# ==============================================================================
# ANÁLISE DE REAMOSTRAGEM: REGRESSÃO LINEAR MÚLTIPLA
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

# Carregamento do banco de dados das rotas líderes
caminho_csv <- path(getwd(), "data", "processed", "df_sazonal_lideres.csv")
if (!file_exists(caminho_csv)) {
  caminho_csv <- path(path_dir(getwd()), "data", "processed", "df_sazonal_lideres.csv")
}

dados <- read_csv2(caminho_csv, show_col_types = FALSE)

# Tratamentos originais preservados
dados_linear <- dados %>%
  filter(`Valor US$ FOB` > 0 & `Quilograma Líquido` > 0) %>%
  mutate(
    log_valor_fob = log(`Valor US$ FOB`),
    log_peso_kg = log(`Quilograma Líquido`),
    Municipio = factor(Município, levels = c("Santos", "Cubatão", "Guarujá")),
    Fluxo = factor(Fluxo, levels = c("Exportação", "Importação"))
  )

n <- nrow(dados_linear)
cat(sprintf("Base preparada com sucesso. Total de observações válidas: %d\n\n", n))

# Fórmulas dos modelos originais
fórmula_mod1 <- log_valor_fob ~ log_peso_kg
fórmula_mod2 <- log_valor_fob ~ log_peso_kg + Municipio + Fluxo

# ==============================================================================
# 2. VALIDAÇÃO CRUZADA 5-FOLD (K = 5)
# ==============================================================================
K <- 5
folds <- sample(rep(1:K, length.out = n))

cv_resultados_mod1 <- numeric(K)
cv_resultados_mod2 <- numeric(K)

for (k in 1:K) {
  treino <- dados_linear[folds != k, ]
  validacao <- dados_linear[folds == k, ]
  
  # Reajuste dos modelos no treino
  fit1 <- lm(fórmula_mod1, data = treino)
  fit2 <- lm(fórmula_mod2, data = treino)
  
  # Predição na dobra de validação
  pred1 <- predict(fit1, newdata = validacao)
  pred2 <- predict(fit2, newdata = validacao)
  
  # Cálculo do MSE por fold
  cv_resultados_mod1[k] <- mean((validacao$log_valor_fob - pred1)^2)
  cv_resultados_mod2[k] <- mean((validacao$log_valor_fob - pred2)^2)
}

# Tabela de resultados por Fold
tabela_folds <- data.frame(
  Fold = 1:K,
  MSE_Modelo_Simples = cv_resultados_mod1,
  RMSE_Modelo_Simples = sqrt(cv_resultados_mod1),
  MSE_Modelo_Multiplo = cv_resultados_mod2,
  RMSE_Modelo_Multiplo = sqrt(cv_resultados_mod2)
)

cat("--- RESULTADOS DA VALIDAÇÃO CRUZADA 5-FOLD ---\n")
print(tabela_folds)

# Tabela Resumo CV(5)
cv_resumo <- data.frame(
  Modelo = c("Modelo 1 (Simples)", "Modelo 2 (Múltiplo)"),
  CV_5_MSE = c(mean(cv_resultados_mod1), mean(cv_resultados_mod2)),
  RMSE_CV_5 = c(sqrt(mean(cv_resultados_mod1)), sqrt(mean(cv_resultados_mod2))),
  Desvio_Padrao_MSE = c(sd(cv_resultados_mod1), sd(cv_resultados_mod2))
)

cat("\n--- TABELA RESUMO CV(5) ---\n")
print(cv_resumo)

# ==============================================================================
# 3. BOOTSTRAP (B = 2000) - MODELO LINEAR MÚLTIPLO
# Coeficiente escolhido: log_peso_kg (Elasticidade-peso)
# ==============================================================================
B <- 2000
fit_original <- lm(fórmula_mod2, data = dados_linear)
beta_orig <- coef(fit_original)["log_peso_kg"]

boot_estimates <- numeric(B)

for (b in 1:B) {
  idx <- sample(1:n, size = n, replace = TRUE)
  dados_boot <- dados_linear[idx, ]
  fit_boot <- lm(fórmula_mod2, data = dados_boot)
  boot_estimates[b] <- coef(fit_boot)["log_peso_kg"]
}

# Estatísticas Bootstrap
se_boot <- sd(boot_estimates)
ci_percentil <- quantile(boot_estimates, probs = c(0.025, 0.975))

cat("\n--- RESULTADOS DO BOOTSTRAP (B = 2000) ---\n")
cat(sprintf("Estimativa Original (beta_log_peso_kg): %.4f\n", beta_orig))
cat(sprintf("Erro Padrão Bootstrap: %.4f\n", se_boot))
cat(sprintf("Intervalo Percentil 95%%: [%.4f, %.4f]\n", ci_percentil[1], ci_percentil[2]))

# ==============================================================================
# 4. GRÁFICO DA DISTRIBUIÇÃO BOOTSTRAP
# ==============================================================================
df_boot_plot <- data.frame(beta_weight = boot_estimates)

p_boot_linear <- ggplot(df_boot_plot, aes(x = beta_weight)) +
  geom_histogram(aes(y = ..density..), bins = 40, fill = "#2b5c8f", color = "white", alpha = 0.7) +
  geom_density(color = "#112e51", size = 1) +
  geom_vline(aes(xintercept = beta_orig, color = "Estimativa Original"), size = 1.2, linetype = "solid") +
  geom_vline(aes(xintercept = ci_percentil[1], color = "IC Percentil 95%"), size = 1, linetype = "dashed") +
  geom_vline(aes(xintercept = ci_percentil[2], color = "IC Percentil 95%"), size = 1, linetype = "dashed") +
  scale_color_manual(name = "Legenda", values = c("Estimativa Original" = "#d9534f", "IC Percentil 95%" = "#5cb85c")) +
  labs(
    title = "Distribuição Bootstrap do Coeficiente (log_peso_kg)",
    subtitle = "2.000 Reamostragens com Reposição (B = 2000)",
    x = "Estimativa do Coeficiente Beta (Elasticidade-Peso)",
    y = "Densidade"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

print(p_boot_linear)