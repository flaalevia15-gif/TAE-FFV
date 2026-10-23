# ==============================================================================
# SCRIPT MODULAR: REGRESSION SPLINES & SMOOTHING SPLINES (R/analise_splines.R)
# ==============================================================================
#
# ÍNDICE DE SEÇÕES:
# 1. [TAG: PREPARO_ENV]     - Preparação de ambiente e busca dinâmica da raiz
# 2. [TAG: PREPARO_SPLINES] - Base das rotas líderes com variáveis temporais e logs
# 3. [TAG: CV_REG_SPLINE]   - CV(5) repetida para Regression Splines (ns)
# 4. [TAG: SMOOTH_SPLINES]  - Ajuste de Smoothing Splines (smooth.spline) via GCV
# 5. [TAG: TESTE_FUTURO]    - Treino no passado e teste no futuro (comportamento nas pontas)
# 6. [TAG: GRAFICO_PRECO]   - Visualização: Reta x Spline Natural x Smoothing Spline
# ==============================================================================

# 1. [TAG: PREPARO_ENV] PREPARAR AMBIENTE E CAMINHOS DA ESTRUTURA
preparar_ambiente <- function() {
  pacotes <- c("readr", "dplyr", "ggplot2", "splines", "scales", "tibble", "purrr")
  instalar <- pacotes[!(pacotes %in% rownames(installed.packages()))]
  if (length(instalar) > 0) {
    install.packages(instalar, repos = "https://cloud.r-project.org")
  }
  invisible(lapply(pacotes, library, character.only = TRUE))
  options(scipen = 999, digits = 4)
}

obter_raiz_estrutura <- function() {
  caminho_atual <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  if (basename(caminho_atual) %in% c("R", "notebooks") && basename(dirname(caminho_atual)) == "estrutura") {
    return(dirname(caminho_atual))
  } else if (basename(caminho_atual) == "estrutura") {
    return(caminho_atual)
  } else {
    candidato <- file.path(caminho_atual, "estrutura")
    if (dir.exists(candidato)) return(candidato) else return(caminho_atual)
  }
}

carregar_dados <- function() {
  raiz <- obter_raiz_estrutura()
  caminho_csv <- file.path(raiz, "data", "processed", "df_sazonal_lideres.csv")
  if (!file.exists(caminho_csv)) {
    stop("Base de dados não encontrada em: ", caminho_csv)
  }
  read_csv2(caminho_csv, show_col_types = FALSE)
}


# 2. [TAG: PREPARO_SPLINES] PREPARO DA BASE DE DADOS
preparar_base_splines <- function(df_sazonal_lideres) {
  df_sazonal_lideres |>
    filter(`Valor US$ FOB` > 0, `Quilograma Líquido` > 0) |>
    mutate(
      rota = factor(paste(sub(" - SP", "", Município), substr(Fluxo, 1, 3), sep = " | ")),
      t = (Ano - 2019) * 12 + mes_numero,
      log_valor = log(`Valor US$ FOB`),
      log_peso = log(`Quilograma Líquido`),
      preco_ton = `Valor US$ FOB` / (`Quilograma Líquido` / 1000)
    ) |>
    as.data.frame()
}


# 3. [TAG: CV_REG_SPLINE] VALIDAÇÃO CRUZADA PARA REGRESSION SPLINES (ns)
cv_formula <- function(formula, dados, K = 5, repeticoes = 10, semente = 123) {
  y_nome <- all.vars(formula)[1]
  mse_rep <- numeric(repeticoes)

  for (r in seq_len(repeticoes)) {
    set.seed(semente + r)
    dobra <- sample(rep(1:K, length.out = nrow(dados)))
    erros <- numeric(0)

    for (k in 1:K) {
      treino <- dados[dobra != k, ]
      valid <- dados[dobra == k, ]
      ajuste <- lm(formula, data = treino)
      pred <- predict(ajuste, newdata = valid)
      erros <- c(erros, (valid[[y_nome]] - pred)^2)
    }
    mse_rep[r] <- mean(erros)
  }
  sqrt(mean(mse_rep))
}

comparar_regression_splines <- function(base, dfs = c(3, 4, 5, 6, 8, 10)) {
  linhas <- list(
    data.frame(modelo = "Baseline (Sem tempo): rota * log_peso", df = NA,
               rmse_cv = cv_formula(log_valor ~ rota * log_peso, base)),
    data.frame(modelo = "Linear no tempo: rota * log_peso + rota:t", df = 1,
               rmse_cv = cv_formula(log_valor ~ rota * log_peso + rota:t, base))
  )

  for (d in dfs) {
    f <- as.formula(sprintf("log_valor ~ rota * log_peso + rota:ns(t, df = %d)", d))
    linhas[[length(linhas) + 1]] <- data.frame(
      modelo = sprintf("Spline Natural no tempo (df = %d)", d), df = d, 
      rmse_cv = cv_formula(f, base)
    )
  }

  bind_rows(linhas)
}


# 4. [TAG: SMOOTH_SPLINES] SMOOTHING SPLINES VIA GCV
ajustar_smoothing_splines_por_rota <- function(base) {
  rotas <- unique(base$rota)
  
  map_dfr(rotas, function(r) {
    sub_df <- base |> filter(rota == r)
    
    # smooth.spline escolhe df/lambda ótimo via GCV automaticamente
    fit <- smooth.spline(x = sub_df$t, y = sub_df$preco_ton)
    
    data.frame(
      rota = r,
      df_efetivo = round(fit$df, 2),
      lambda = round(fit$lambda, 6)
    )
  })
}


# 5. [TAG: TESTE_FUTURO] AVALIAÇÃO DE EXTRAPOLAÇÃO NAS PONTAS
teste_futuro <- function(base, t_corte = 79) {
  treino <- base[base$t <= t_corte, ]
  teste <- base[base$t > t_corte, ]

  formulas <- list(
    "Sem tempo"               = log_valor ~ rota * log_peso,
    "Reta no tempo"           = log_valor ~ rota * log_peso + rota:t,
    "Spline Natural (df = 4)" = log_valor ~ rota * log_peso + rota:ns(t, df = 4),
    "Spline Natural (df = 8)" = log_valor ~ rota * log_peso + rota:ns(t, df = 8)
  )

  bind_rows(lapply(names(formulas), function(nome) {
    ajuste <- lm(formulas[[nome]], data = treino)
    pred <- predict(ajuste, newdata = teste)
    data.frame(modelo = nome, n_teste = nrow(teste),
               rmse_futuro = round(sqrt(mean((teste$log_valor - pred)^2)), 4))
  }))
}


# 6. [TAG: GRAFICO_PRECO] VISUALIZAÇÃO: RETA x SPLINE NATURAL x SMOOTHING SPLINE
plotar_comparacao_splines <- function(base, df_ns = 5) {
  # Prepara predições do smooth.spline por rota para o gráfico
  pred_smooth <- map_dfr(unique(base$rota), function(r) {
    sub_df <- base |> filter(rota == r) |> arrange(t)
    fit <- smooth.spline(x = sub_df$t, y = sub_df$preco_ton)
    data.frame(
      rota = r,
      t = sub_df$t,
      y_smooth = predict(fit, sub_df$t)$y
    )
  })
  
  base_plot <- base |> left_join(pred_smooth, by = c("rota", "t"))

  ggplot(base_plot, aes(x = t, y = preco_ton)) +
    geom_point(color = "#9aa5b1", size = 1.6, alpha = 0.6) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                aes(color = "Reta (MQO)"), linetype = "dashed", linewidth = 0.8) +
    geom_smooth(method = "lm", formula = y ~ splines::ns(x, df = df_ns), se = FALSE,
                aes(color = "Spline Natural (ns)"), linewidth = 1.1) +
    geom_line(aes(y = y_smooth, color = "Smoothing Spline"), linewidth = 1.0, linetype = "dotdash") +
    facet_wrap(~ rota, scales = "free_y", ncol = 3) +
    scale_x_continuous(breaks = seq(1, 85, 24), labels = seq(2019, 2026, 2)) +
    scale_color_manual(values = c("Reta (MQO)" = "#2e5eaa", 
                                  "Spline Natural (ns)" = "#d1495b", 
                                  "Smoothing Spline" = "#2ba84a")) +
    labs(
      title = "Preço por Tonelada: Reta vs Spline Natural vs Smoothing Spline",
      subtitle = "Comparação dos métodos de suavização por partes ao longo do tempo",
      x = "Ano (Linha do Tempo)", y = "US$ por Tonelada", color = "Modelo"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
}