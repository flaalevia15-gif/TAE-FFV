# ==============================================================================
# 08. EXPANSÃO E REGULARIZAÇÃO — RIDGE, LASSO E ELASTIC NET
# Aplicação à Regressão Linear Múltipla das Rotas Líderes
# ==============================================================================

# Objetivo:
# Aplicar Ridge (L2), Lasso (L1) e Elastic Net à MESMA especificação da
# regressão linear múltipla consolidada da Aula 04:
#
#   Valor FOB ~ Volume * rota_lider
#
# A regressão OLS original não é alterada. Ela é reproduzida apenas como
# baseline para comparação preditiva.
#
# Base:
#   estrutura/data/processed/df_sazonal_lideres.csv
#
# Saída principal:
#   comparação entre OLS, Ridge, Lasso e Elastic Net, com lambda escolhido
#   por validação cruzada e análise dos coeficientes.

# ==============================================================================
# 0. PACOTES
# ==============================================================================

library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(scales)
library(glmnet)
library(tibble)

options(scipen = 999, digits = 4)

# ==============================================================================
# 1. CAMINHOS E CARREGAMENTO DA BASE
# ==============================================================================

# Os arquivos do projeto foram reorganizados dentro de "estrutura/".
# Este script está em estrutura/R/. A raiz do projeto é, portanto, a pasta
# imediatamente acima de R/. O código também funciona se for executado a partir
# de estrutura/ ou de estrutura/notebooks/.

caminho_atual <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)

if (basename(caminho_atual) == "R" && basename(dirname(caminho_atual)) == "estrutura") {
  raiz_estrutura <- dirname(caminho_atual)
} else if (basename(caminho_atual) == "notebooks" && basename(dirname(caminho_atual)) == "estrutura") {
  raiz_estrutura <- dirname(caminho_atual)
} else if (basename(caminho_atual) == "estrutura") {
  raiz_estrutura <- caminho_atual
} else if (basename(caminho_atual) == "notebooks") {
  raiz_estrutura <- dirname(caminho_atual)
} else {
  # Em execução pelo RStudio/IDE, tenta localizar a pasta "estrutura".
  candidato <- file.path(caminho_atual, "estrutura")
  if (dir.exists(candidato)) {
    raiz_estrutura <- candidato
  } else {
    raiz_estrutura <- caminho_atual
  }
}

caminho_csv <- file.path(
  raiz_estrutura,
  "data", "processed", "df_sazonal_lideres.csv"
)

if (!file.exists(caminho_csv)) {
  stop(
    "Base não encontrada em: ", caminho_csv,
    "\nVerifique se o script está sendo executado dentro da estrutura atual do projeto."
  )
}

df_sazonal_lideres <- read_csv2(caminho_csv, show_col_types = FALSE)

cat(
  sprintf(
    "Base carregada: %d observações mensais.\n",
    nrow(df_sazonal_lideres)
  )
)

# ==============================================================================
# 2. PREPARAÇÃO — MESMA ESPECIFICAÇÃO DA REGRESSÃO MÚLTIPLA ORIGINAL
# ==============================================================================

# A especificação original usa:
#   volume_mil_ton = Quilograma Líquido / 1e6
#   valor_milhoes_fob = Valor US$ FOB / 1e6
#   rota_lider = combinação Município + Fluxo + País + Descrição SH4
#
# Não são acrescentados novos preditores. Isso é importante para que a
# regularização seja aplicada à mesma regressão múltipla da etapa anterior.

df_multipla <- df_sazonal_lideres |>
  mutate(
    volume_mil_ton = `Quilograma Líquido` / 1e6,
    valor_milhoes_fob = `Valor US$ FOB` / 1e6,
    rota_lider = factor(
      paste(
        Município,
        Fluxo,
        País,
        str_trunc(`Descrição SH4`, 15),
        sep = " | "
      )
    )
  )

# Confere as rotas consideradas no modelo.
rotas <- levels(df_multipla$rota_lider)

cat("\nRotas incluídas no modelo:\n")
print(rotas)

# ==============================================================================
# 3. MATRIZ DE PREDITORES
# ==============================================================================

# A Aula 08 orienta construir X com model.matrix() e retirar o intercepto:
#
#   X <- model.matrix(y ~ ., data = dados)[, -1]
#
# Aqui, como queremos reproduzir exatamente a regressão múltipla original,
# construímos a matriz diretamente da mesma fórmula:
#
#   valor_milhoes_fob ~ volume_mil_ton * rota_lider
#
# O intercepto é retirado porque o glmnet possui intercepto próprio.
# A matriz X contém:
#   - volume_mil_ton
#   - dummies de rota
#   - interações volume × rota
#
# Portanto, Ridge/Lasso/Elastic Net trabalham sobre os mesmos termos da OLS.

formula_multipla <- valor_milhoes_fob ~ volume_mil_ton * rota_lider

X <- model.matrix(formula_multipla, data = df_multipla)[, -1, drop = FALSE]
y <- df_multipla$valor_milhoes_fob

cat("\nDimensões da matriz X:", nrow(X), "observações x", ncol(X), "preditores.\n")
cat("\nPreditores utilizados:\n")
print(colnames(X))

# Verificação básica de dados ausentes.
if (anyNA(X) || anyNA(y)) {
  stop("Existem valores ausentes em X ou y. A base precisa ser tratada antes da regularização.")
}

# ==============================================================================
# 4. OLS — BASELINE DA REGRESSÃO MÚLTIPLA ORIGINAL
# ==============================================================================

modelo_ols <- lm(formula_multipla, data = df_multipla)
resumo_ols <- summary(modelo_ols)

rmse_ols_treino <- sqrt(mean(residuals(modelo_ols)^2))
r2_ols <- resumo_ols$r.squared
r2_aj_ols <- resumo_ols$adj.r.squared

cat("\n================ OLS — BASELINE ================\n")
cat("R²:", round(r2_ols, 4), "\n")
cat("R² ajustado:", round(r2_aj_ols, 4), "\n")
cat("RMSE de treino:", round(rmse_ols_treino, 4), "M$ FOB\n")

# ==============================================================================
# 5. VALIDAÇÃO CRUZADA — MESMAS DIVISÕES PARA TODOS OS MODELOS
# ==============================================================================

# A Aula 08 utiliza validação cruzada para escolher lambda.
# Usamos 10 folds e a mesma divisão para OLS, Ridge, Lasso e Elastic Net,
# permitindo uma comparação preditiva mais justa entre os modelos.

set.seed(1)

K <- 10
foldid <- sample(rep(seq_len(K), length.out = nrow(X)))

# Função para RMSE de validação cruzada do OLS.
rmse_ols_cv <- function(X, y, foldid) {
  erros <- numeric(max(foldid))

  for (k in sort(unique(foldid))) {
    treino <- foldid != k
    teste <- foldid == k

    modelo_cv <- lm.fit(
      x = cbind(`(Intercept)` = 1, X[treino, , drop = FALSE]),
      y = y[treino]
    )

    X_teste <- cbind(`(Intercept)` = 1, X[teste, , drop = FALSE])
    pred <- as.vector(X_teste %*% coef(modelo_cv))

    erros[k] <- mean((y[teste] - pred)^2)
  }

  sqrt(mean(erros))
}

rmse_ols_cv_val <- rmse_ols_cv(X, y, foldid)

cat("\nRMSE CV (OLS):", round(rmse_ols_cv_val, 4), "M$ FOB\n")

# ==============================================================================
# 6. RIDGE — REGULARIZAÇÃO L2
# ==============================================================================

# Ridge minimiza RSS + lambda * soma(beta_j^2).
# lambda = 0 se aproxima da OLS; conforme lambda aumenta, os coeficientes
# são encolhidos em direção a zero.
#
# standardize = TRUE segue a recomendação da Aula 08:
# os preditores são padronizados internamente pelo glmnet e os coeficientes
# retornados são apresentados na escala original.

set.seed(1)

cv_ridge <- cv.glmnet(
  x = X,
  y = y,
  alpha = 0,
  nfolds = K,
  foldid = foldid,
  standardize = TRUE,
  type.measure = "mse"
)

lambda_ridge <- cv_ridge$lambda.min
mse_ridge_cv <- min(cv_ridge$cvm)
rmse_ridge_cv <- sqrt(mse_ridge_cv)

coef_ridge <- coef(cv_ridge, s = "lambda.min")
coef_ridge_df <- tibble(
  Termo = rownames(as.matrix(coef_ridge)),
  Coeficiente = as.numeric(coef_ridge)
)

n_ridge <- sum(abs(coef_ridge_df$Coeficiente[-1]) > 1e-10)

cat("\n================ RIDGE (L2) ================\n")
cat("Lambda escolhido (lambda.min):", signif(lambda_ridge, 6), "\n")
cat("CV MSE:", round(mse_ridge_cv, 6), "\n")
cat("CV RMSE:", round(rmse_ridge_cv, 4), "M$ FOB\n")
cat("Preditores com coeficiente não nulo:", n_ridge, "\n")

# ==============================================================================
# 7. LASSO — REGULARIZAÇÃO L1
# ==============================================================================

# Lasso minimiza RSS + lambda * soma(|beta_j|).
# Diferentemente do Ridge, pode zerar coeficientes e, portanto, realizar
# seleção de variáveis.
#
# A Aula 08 destaca lambda.min e lambda.1se.
# lambda.1se privilegia um modelo mais simples dentro da regra de 1 erro-padrão.

set.seed(1)

cv_lasso <- cv.glmnet(
  x = X,
  y = y,
  alpha = 1,
  nfolds = K,
  foldid = foldid,
  standardize = TRUE,
  type.measure = "mse"
)

lambda_lasso_min <- cv_lasso$lambda.min
lambda_lasso_1se <- cv_lasso$lambda.1se

mse_lasso_min <- cv_lasso$cvm[which.min(abs(cv_lasso$lambda - lambda_lasso_min))]
rmse_lasso_min <- sqrt(mse_lasso_min)

idx_1se <- which.min(abs(cv_lasso$lambda - lambda_lasso_1se))
mse_lasso_1se <- cv_lasso$cvm[idx_1se]
rmse_lasso_1se <- sqrt(mse_lasso_1se)

coef_lasso_min <- coef(cv_lasso, s = "lambda.min")
coef_lasso_1se <- coef(cv_lasso, s = "lambda.1se")

coef_lasso_min_df <- tibble(
  Termo = rownames(as.matrix(coef_lasso_min)),
  Coeficiente = as.numeric(coef_lasso_min)
)

coef_lasso_1se_df <- tibble(
  Termo = rownames(as.matrix(coef_lasso_1se)),
  Coeficiente = as.numeric(coef_lasso_1se)
)

n_lasso_min <- sum(abs(coef_lasso_min_df$Coeficiente[-1]) > 1e-10)
n_lasso_1se <- sum(abs(coef_lasso_1se_df$Coeficiente[-1]) > 1e-10)

cat("\n================ LASSO (L1) ================\n")
cat("Lambda.min:", signif(lambda_lasso_min, 6), "\n")
cat("CV RMSE — lambda.min:", round(rmse_lasso_min, 4), "M$ FOB\n")
cat("Preditores não nulos — lambda.min:", n_lasso_min, "\n")
cat("\nLambda.1se:", signif(lambda_lasso_1se, 6), "\n")
cat("CV RMSE — lambda.1se:", round(rmse_lasso_1se, 4), "M$ FOB\n")
cat("Preditores não nulos — lambda.1se:", n_lasso_1se, "\n")

cat("\nPreditores sobreviventes no Lasso — lambda.1se:\n")
print(
  coef_lasso_1se_df |>
    filter(Termo != "(Intercept)", abs(Coeficiente) > 1e-10)
)

cat("\nPreditores zerados pelo Lasso — lambda.1se:\n")
print(
  coef_lasso_1se_df |>
    filter(Termo != "(Intercept)", abs(Coeficiente) <= 1e-10) |>
    select(Termo)
)

# ==============================================================================
# 8. ELASTIC NET — ALPHA = 0.5
# ==============================================================================

# Elastic Net combina penalização L2 e L1:
#
# RSS + lambda * [(1-alpha) * soma(beta_j^2) + alpha * soma(|beta_j|)]
#
# alpha = 0 -> Ridge
# alpha = 1 -> Lasso
# alpha = 0.5 -> combinação intermediária, conforme aplicação prática da Aula 08.

set.seed(1)

alpha_enet <- 0.5

cv_enet <- cv.glmnet(
  x = X,
  y = y,
  alpha = alpha_enet,
  nfolds = K,
  foldid = foldid,
  standardize = TRUE,
  type.measure = "mse"
)

lambda_enet <- cv_enet$lambda.min
mse_enet_cv <- min(cv_enet$cvm)
rmse_enet_cv <- sqrt(mse_enet_cv)

coef_enet <- coef(cv_enet, s = "lambda.min")
coef_enet_df <- tibble(
  Termo = rownames(as.matrix(coef_enet)),
  Coeficiente = as.numeric(coef_enet)
)

n_enet <- sum(abs(coef_enet_df$Coeficiente[-1]) > 1e-10)

cat("\n================ ELASTIC NET ================\n")
cat("Alpha:", alpha_enet, "\n")
cat("Lambda escolhido (lambda.min):", signif(lambda_enet, 6), "\n")
cat("CV MSE:", round(mse_enet_cv, 6), "\n")
cat("CV RMSE:", round(rmse_enet_cv, 4), "M$ FOB\n")
cat("Preditores com coeficiente não nulo:", n_enet, "\n")

# ==============================================================================
# 9. TABELA COMPARATIVA
# ==============================================================================

# A comparação principal é preditiva e baseada em validação cruzada.
# O R² de treino não é usado como critério para escolher lambda.

comparacao_modelos <- tibble(
  Modelo = c("OLS", "Ridge", "Lasso", "Lasso", "Elastic Net"),
  Alpha = c(NA, 0, 1, 1, alpha_enet),
  Lambda = c(NA, lambda_ridge, lambda_lasso_min, lambda_lasso_1se, lambda_enet),
  Selecao_Lambda = c(
    "OLS",
    "lambda.min",
    "lambda.min",
    "lambda.1se",
    "lambda.min"
  ),
  CV_MSE = c(
    rmse_ols_cv_val^2,
    mse_ridge_cv,
    mse_lasso_min,
    mse_lasso_1se,
    mse_enet_cv
  ),
  CV_RMSE = c(
    rmse_ols_cv_val,
    rmse_ridge_cv,
    rmse_lasso_min,
    rmse_lasso_1se,
    rmse_enet_cv
  ),
  Preditores_Nao_Nulos = c(
    ncol(X),
    n_ridge,
    n_lasso_min,
    n_lasso_1se,
    n_enet
  )
)

cat("\n================ COMPARAÇÃO FINAL ================\n")
print(comparacao_modelos)

# ==============================================================================
# 10. COMPARAÇÃO DOS COEFICIENTES
# ==============================================================================

coef_ols <- coef(modelo_ols)

# Garante que todos os termos apareçam na mesma ordem.
coef_ridge_v <- as.numeric(coef_ridge)
names(coef_ridge_v) <- rownames(as.matrix(coef_ridge))

coef_lasso_v <- as.numeric(coef_lasso_1se)
names(coef_lasso_v) <- rownames(as.matrix(coef_lasso_1se))

coef_enet_v <- as.numeric(coef_enet)
names(coef_enet_v) <- rownames(as.matrix(coef_enet))

todos_termos <- unique(c(
  names(coef_ols),
  names(coef_ridge_v),
  names(coef_lasso_v),
  names(coef_enet_v)
))

comparacao_coeficientes <- tibble(
  Termo = todos_termos,
  OLS = unname(coef_ols[Termo]),
  Ridge = unname(coef_ridge_v[Termo]),
  Lasso_lambda_1se = unname(coef_lasso_v[Termo]),
  Elastic_Net = unname(coef_enet_v[Termo])
)

cat("\n================ COEFICIENTES ================\n")
print(comparacao_coeficientes, n = Inf)

# ==============================================================================
# 11. CURVAS DE VALIDAÇÃO CRUZADA
# ==============================================================================

plotar_cv <- function(objeto_cv, titulo) {
  plot(
    objeto_cv,
    main = titulo
  )
}

plotar_cv(cv_ridge, "Ridge — Erro de validação cruzada")
plotar_cv(cv_lasso, "Lasso — Erro de validação cruzada")
plotar_cv(cv_enet, "Elastic Net — Erro de validação cruzada")

# ==============================================================================
# 12. CAMINHOS DOS COEFICIENTES — RIDGE E LASSO
# ==============================================================================

# Os gráficos mostram como os coeficientes mudam conforme lambda varia.
# No Ridge, os coeficientes são encolhidos, mas em geral permanecem não nulos.
# No Lasso, alguns coeficientes podem chegar exatamente a zero.

plot(
  cv_ridge$glmnet.fit,
  xvar = "lambda",
  label = TRUE,
  main = "Caminho dos coeficientes — Ridge"
)

plot(
  cv_lasso$glmnet.fit,
  xvar = "lambda",
  label = TRUE,
  main = "Caminho dos coeficientes — Lasso"
)

# ==============================================================================
# 13. RESUMO DOS TERMOS SELECIONADOS
# ==============================================================================

cat("\n================ RESUMO INTERPRETATIVO ================\n")

cat(
  "\nRidge: a regularização reduz a magnitude dos coeficientes,",
  "sem ter como objetivo zerá-los.\n"
)

cat(
  "Lasso: além de reduzir os coeficientes, pode zerar termos;",
  "por isso, lambda.1se é apresentado como alternativa mais parcimoniosa.\n"
)

cat(
  "Elastic Net: combina os efeitos L1 e L2 com alpha = 0.5.\n"
)

cat(
  "\nImportante: um coeficiente zerado pelo Lasso representa uma seleção",
  "dentro deste modelo regularizado; não deve ser interpretado como prova",
  "de que a variável não possui relação causal com o Valor FOB.\n"
)

# Fim do script.
