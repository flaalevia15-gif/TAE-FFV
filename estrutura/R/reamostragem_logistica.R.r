# ==============================================================================
# ANÁLISE DE REAMOSTRAGEM: REGRESSÃO LOGÍSTICA MÚLTIPLA
# Validação Cruzada 5-Fold e Bootstrap (B = 2000)
# ==============================================================================

# 1. PREPARAÇÃO DO AMBIENTE E DADOS
library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(fs)

options(scipen = 999, digits = 4)
set.seed(123)

# Carregamento dos dados
caminho_csv <- path(getwd(), "data", "processed", "df_sazonal_lideres.csv")
if (!file_exists(caminho_csv)) {
  caminho_csv <- path(path_dir(getwd()), "data", "processed", "df_sazonal_lideres.csv")
}

dados <- read_csv2(caminho_csv, show_col_types = FALSE)

# Preparação da variável dependente binária (Fluxo)
dados_logistica <- dados %>%
  mutate(
    Fluxo_bin = ifelse(grepl("Exp", as.character(Fluxo), ignore.case = TRUE), 1L, 0L),
    Quilograma_Liquido_Escalado = Quilograma_Liquido / 1000000 # em milhares de toneladas para estabilidade
  )

n <- nrow(dados_logistica)
cat(sprintf("Base de Regressão Logística preparada. Total de observações: %d\n\n", n))

# Fórmula do modelo logístico original
fórmula_logistica <- Fluxo_bin ~ Quilograma_Liquido_Escalado

# Função auxiliar para calcular métricas de classificação
calcular_metricas <- function(y_real, p_pred, limiar = 0.5) {
  y_pred <- ifelse(p_pred >= limiar, 1L, 0L)
  acuracia <- mean(y_real == y_pred)
  
  tp <- sum(y_real == 1 & y_pred == 1)
  fp <- sum(y_real == 0 & y_pred == 1)
  fn <- sum(y_real == 1 & y_pred == 0)
  tn <- sum(y_real == 0 & y_pred == 0)
  
  precisao <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
  recall <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
  especificidade <- ifelse((tn + fp) > 0, tn / (tn + fp), 0)
  
  return(c(Acuracia = acuracia, Precisao = precisao, Recall = recall, Especificidade = especificidade))
}

# ==============================================================================
# 2. VALIDAÇÃO CRUZADA 5-FOLD (K = 5) - LOGÍSTICA
# ==============================================================================
K <- 5
folds <- sample(rep(1:K, length.out = n))

metricas_folds <- matrix(0, nrow = K, ncol = 4)
colnames(metricas_folds) <- c("Acuracia", "Precisao", "Recall", "Especificidade")

for (k in 1:K) {
  treino <- dados_logistica[folds != k, ]
  validacao <- dados_logistica[folds == k, ]
  
  # Reajuste do modelo logístico no treino
  fit_log <- glm(fórmula_logistica, family = binomial(link = "logit"), data = treino)
  
  # Predição das probabilidades na dobra de validação
  prob_pred <- predict(fit_log, newdata = validacao, type = "response")
  
  # Métricas
  metricas_folds[k, ] <- calcular_metricas(validacao$Fluxo_bin, prob_pred, limiar = 0.5)
}

tabela_cv_logistica <- as.data.frame(metricas_folds)
tabela_cv_logistica$Fold <- 1:K
tabela_cv_logistica <- tabela_cv_logistica[, c("Fold", "Acuracia", "Precisao", "Recall", "Especificidade")]

cat("--- RESULTADOS DA CV 5-FOLD (REGRESSÃO LOGÍSTICA) ---\n")
print(tabela_cv_logistica)

resumo_cv_logistica <- data.frame(
  Métrica = c("Acurácia", "Precisão", "Recall (Sensibilidade)", "Especificidade"),
  Média_CV = colMeans(metricas_folds),
  Desvio_Padrão = apply(metricas_folds, 2, sd)
)

cat("\n--- TABELA RESUMO DA VALIDAÇÃO CRUZADA LOGÍSTICA ---\n")
print(resumo_cv_logistica)

# ==============================================================================
# 3. BOOTSTRAP (B = 2000) - REGRESSÃO LOGÍSTICA
# Coeficiente escolhido: Quilograma_Liquido_Escalado
# ==============================================================================
B <- 2000
fit_log_orig <- glm(fórmula_logistica, family = binomial(link = "logit"), data = dados_logistica)
beta_log_orig <- coef(fit_log_orig)["Quilograma_Liquido_Escalado"]
or_orig <- exp(beta_log_orig)

boot_beta_log <- numeric(B)
boot_or_log <- numeric(B)

for (b in 1:B) {
  idx <- sample(1:n, size = n, replace = TRUE)
  dados_boot <- dados_logistica[idx, ]
  fit_boot <- glm(fórmula_logistica, family = binomial(link = "logit"), data = dados_boot)
  
  beta_val <- coef(fit_boot)["Quilograma_Liquido_Escalado"]
  boot_beta_log[b] <- beta_val
  boot_or_log[b] <- exp(beta_val)
}

# Estatísticas Bootstrap
se_boot_log <- sd(boot_beta_log)
ci_percentil_beta <- quantile(boot_beta_log, probs = c(0.025, 0.975))
ci_percentil_or <- quantile(boot_or_log, probs = c(0.025, 0.975))

cat("\n--- RESULTADOS DO BOOTSTRAP LOGÍSTICO (B = 2000) ---\n")
cat(sprintf("Estimativa Original Logit (beta): %.6f\n", beta_log_orig))
cat(sprintf("Odds Ratio Original (e^beta): %.6f\n", or_orig))
cat(sprintf("Erro Padrão Bootstrap do Logit: %.6f\n", se_boot_log))
cat(sprintf("IC Percentil 95%% (Logit): [%.6f, %.6f]\n", ci_percentil_beta[1], ci_percentil_beta[2]))
cat(sprintf("IC Percentil 95%% (Odds Ratio): [%.6f, %.6f]\n", ci_percentil_or[1], ci_percentil_or[2]))

# ==============================================================================
# 4. GRÁFICO DA DISTRIBUIÇÃO BOOTSTRAP LOGÍSTICA
# ==============================================================================
df_boot_log_plot <- data.frame(beta_val = boot_beta_log)

p_boot_log <- ggplot(df_boot_log_plot, aes(x = beta_val)) +
  geom_histogram(aes(y = ..density..), bins = 40, fill = "#1b9e77", color = "white", alpha = 0.7) +
  geom_density(color = "#00441b", size = 1) +
  geom_vline(aes(xintercept = beta_log_orig, color = "Estimativa Original"), size = 1.2, linetype = "solid") +
  geom_vline(aes(xintercept = ci_percentil_beta[1], color = "IC Percentil 95%"), size = 1, linetype = "dashed") +
  geom_vline(aes(xintercept = ci_percentil_beta[2], color = "IC Percentil 95%"), size = 1, linetype = "dashed") +
  scale_color_manual(name = "Legenda", values = c("Estimativa Original" = "#d9534f", "IC Percentil 95%" = "#2b5c8f")) +
  labs(
    title = "Distribuição Bootstrap do Coeficiente Logístico",
    subtitle = "Impacto do Volume Físico no Logit do Fluxo Comercial (B = 2000)",
    x = "Estimativa do Coeficiente Logit (Beta)",
    y = "Densidade"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

print(p_boot_log)