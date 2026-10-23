# ==============================================================================
# Script: analise_relacional_continuas.R
# Aula 09: Análise Relacional Entre Variáveis Contínuas (KNN & Kernel)
# ==============================================================================

# 1. Carregamento e Preparação de Pacotes
preparar_ambiente <- function() {
  pacotes <- c("readr", "dplyr", "stringr", "ggplot2", "scales", "tibble")
  instalar <- pacotes[!(pacotes %in% rownames(installed.packages()))]
  if (length(instalar) > 0) {
    install.packages(instalar, repos = "https://cloud.r-project.org")
  }
  invisible(lapply(pacotes, library, character.only = TRUE))
  options(scipen = 999, digits = 4)
}

# 2. Localização Automática da Raiz da Pasta estrutura/
obter_raiz_estrutura <- function() {
  caminho_atual <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  if (basename(caminho_atual) == "R" && basename(dirname(caminho_atual)) == "estrutura") {
    return(dirname(caminho_atual))
  } else if (basename(caminho_atual) == "notebooks" && basename(dirname(caminho_atual)) == "estrutura") {
    return(dirname(caminho_atual))
  } else if (basename(caminho_atual) == "estrutura") {
    return(caminho_atual)
  } else {
    candidato <- file.path(caminho_atual, "estrutura")
    if (dir.exists(candidato)) return(candidato) else return(caminho_atual)
  }
}

# 3. Carregamento dos Dados
carregar_dados <- function() {
  raiz <- obter_raiz_estrutura()
  caminho_csv <- file.path(raiz, "data", "processed", "df_sazonal_lideres.csv")
  if (!file.exists(caminho_csv)) {
    stop("Base de dados não encontrada em: ", caminho_csv)
  }
  read_csv2(caminho_csv, show_col_types = FALSE)
}

# 4. Implementação dos Métodos Não Paramétricos (Suavização)
knn_reg <- function(x0, x, y, k) {
  distancias <- abs(x - x0)
  indices <- order(distancias)[1:k]
  mean(y[indices])
}

kernel_nw <- function(x0, x, y, h) {
  pesos <- dnorm((x - x0) / h)
  soma_pesos <- sum(pesos)
  if (soma_pesos == 0) return(NA)
  sum(pesos * y) / soma_pesos
}

# 5. Validação Cruzada (K-Fold CV = 5)
avaliar_modelos_cv <- function(df, k_folds = 5, ks_knn = c(3, 5, 10, 15, 20, 40), hs_kernel_mult = c(0.05, 0.1, 0.2, 0.4)) {
  set.seed(1)
  n <- nrow(df)
  dobra <- sample(rep(1:k_folds, length.out = n))
  
  x <- df$volume_mil_ton
  y <- df$valor_milhoes_fob
  
  # Baseline: Regressão Linear Simples (OLS)
  cv_ols <- mean(sapply(1:k_folds, function(j) {
    tr <- dobra != j
    va <- dobra == j
    modelo <- lm(valor_milhoes_fob ~ volume_mil_ton, data = df[tr, ])
    pred <- predict(modelo, newdata = df[va, ])
    mean((y[va] - pred)^2)
  }))
  
  # CV para KNN
  result_knn <- sapply(ks_knn, function(k) {
    mse <- mean(sapply(1:k_folds, function(j) {
      tr <- dobra != j
      va <- dobra == j
      pred <- sapply(x[va], knn_reg, x = x[tr], y = y[tr], k = k)
      mean((y[va] - pred)^2)
    }))
    c(k = k, RMSE_CV = sqrt(mse))
  })
  
  # CV para Kernel (Nadaraya-Watson)
  dp_x <- sd(x)
  hs_kernel <- dp_x * hs_kernel_mult
  
  result_kernel <- sapply(seq_along(hs_kernel), function(i) {
    h <- hs_kernel[i]
    mse <- mean(sapply(1:k_folds, function(j) {
      tr <- dobra != j
      va <- dobra == j
      pred <- sapply(x[va], kernel_nw, x = x[tr], y = y[tr], h = h)
      mean((y[va] - pred)^2, na.rm = TRUE)
    }))
    c(h = h, h_mult = hs_kernel_mult[i], RMSE_CV = sqrt(mse))
  })
  
  list(
    rmse_ols = sqrt(cv_ols),
    knn_cv = as.data.frame(t(result_knn)),
    kernel_cv = as.data.frame(t(result_kernel))
  )
}