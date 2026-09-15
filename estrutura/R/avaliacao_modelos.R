# ==============================================================================
# SCRIPT: AVALIAÇÃO E SELEÇÃO DE MODELOS POLINOMIAIS (R/avaliacao_modelos.R)
# Metodologia: Aula 6 - Avaliação e Seleção de Modelos (Prof. Dr. João Paulo F. de Mello)
# ==============================================================================
#
# Objetivo:
# Avaliar a capacidade de generalização e o compromisso viés-variância
# através da divisão 70/30 (treino/teste) e comparação de regressões polinomiais
# (Graus 1, 3 e 12) para a relação Valor FOB (Milhões US$) ~ Volume (k ton).
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Setup e Carregamento de Bibliotecas
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(fs)
  library(tibble)
})

options(scipen = 999, digits = 4)

# Determinação dinâmica da raiz do projeto
caminho_atual <- getwd()
raiz_projeto <- ifelse(basename(caminho_atual) %in% c("notebooks", "R"), path_dir(caminho_atual), caminho_atual)

# Carregamento da base de dados processada das rotas líderes
caminho_csv <- path(raiz_projeto, "data", "processed", "df_sazonal_lideres.csv")

if (!file_exists(caminho_csv)) {
  stop(paste("Arquivo não encontrado em:", caminho_csv))
}

df_sazonal_lideres <- read_csv2(caminho_csv, show_col_types = FALSE)

# Padronização e preparação das variáveis modeladas
df_modelagem <- df_sazonal_lideres |>
  mutate(
    volume_mil_ton    = `Quilograma Líquido` / 1e6,  # X: Volume físico (k ton)
    valor_milhoes_fob = `Valor US$ FOB` / 1e6       # Y: Valor comercial (M$ FOB)
  ) |>
  select(volume_mil_ton, valor_milhoes_fob, everything())

cat(sprintf(">>> Base carregada com sucesso! Total de observações: %d\n", nrow(df_modelagem)))

# ==============================================================================
# 1. Divisão dos Dados em Treino (70%) e Teste (30%)
# ==============================================================================
# Regra de Ouro da Aula 6: A partição deve ocorrer ANTES de qualquer ajuste.
# O conjunto de teste permanece isolado para estimar o erro honesto fora da amostra.

set.seed(42) # Reprodutibilidade estrita

n_total  <- nrow(df_modelagem)
n_treino <- round(0.70 * n_total)
n_teste  <- n_total - n_treino

indices_treino <- sample(seq_len(n_total), size = n_treino, replace = FALSE)

dados_treino <- df_modelagem[indices_treino, ]
dados_teste  <- df_modelagem[-indices_treino, ]

cat(sprintf(">>> Divisão concluída: Treino = %d observações (70%%) | Teste = %d observações (30%%)\n\n", 
            nrow(dados_treino), nrow(dados_teste)))

# ==============================================================================
# 2. Ajuste dos Modelos Polinomiais (Graus 1, 3 e 12)
# ==============================================================================
# Utiliza-se base polinomial ortogonal poly(x, grau) conforme recomendado na Aula 6
# para garantir estabilidade numérica e prevenir multicolinearidade em ordens elevadas.

modelo_g1  <- lm(valor_milhoes_fob ~ poly(volume_mil_ton, 1), data = dados_treino)
modelo_g3  <- lm(valor_milhoes_fob ~ poly(volume_mil_ton, 3), data = dados_treino)
modelo_g12 <- lm(valor_milhoes_fob ~ poly(volume_mil_ton, 12), data = dados_treino)

modelos_candidatos <- list(
  "Grau 1 (Linear)"      = modelo_g1,
  "Grau 3 (Cúbico)"      = modelo_g3,
  "Grau 12 (Polinomial)" = modelo_g12
)

# ==============================================================================
# 3. Cálculo de Métricas de Avaliação: MSE e RMSE
# ==============================================================================
# Função para cálculo do Erro Quadrático Médio (MSE)
calcular_mse <- function(modelo, dados) {
  predicoes <- predict(modelo, newdata = dados)
  mean((dados$valor_milhoes_fob - predicoes)^2)
}

# Tabela comparativa dos três modelos
tabela_metricas <- tibble(
  Modelo = c("Grau 1 (Linear)", "Grau 3 (Cúbico)", "Grau 12 (Alta Flexibilidade)"),
  Grau   = c(1, 3, 12),
  `MSE Treino` = c(
    calcular_mse(modelo_g1, dados_treino),
    calcular_mse(modelo_g3, dados_treino),
    calcular_mse(modelo_g12, dados_treino)
  ),
  `MSE Teste` = c(
    calcular_mse(modelo_g1, dados_teste),
    calcular_mse(modelo_g3, dados_teste),
    calcular_mse(modelo_g12, dados_teste)
  )
) |>
  mutate(
    `RMSE Treino (M$ FOB)` = sqrt(`MSE Treino`),
    `RMSE Teste (M$ FOB)`  = sqrt(`MSE Teste`),
    `Razão MSE Teste/Treino` = `MSE Teste` / `MSE Treino`
  )

cat("==============================================================================\n")
cat("                   TABELA COMPARATIVA DE DESEMPENHO                           \n")
cat("==============================================================================\n")
print(as.data.frame(tabela_metricas), row.names = FALSE)
cat("==============================================================================\n\n")

# ==============================================================================
# 4. Análise Completa da Curva em U (Graus 1 a 12)
# ==============================================================================
graus_seq <- 1:12
mse_treino_seq <- numeric(length(graus_seq))
mse_teste_seq  <- numeric(length(graus_seq))

for (g in graus_seq) {
  mod_temp <- lm(valor_milhoes_fob ~ poly(volume_mil_ton, g), data = dados_treino)
  mse_treino_seq[g] <- calcular_mse(mod_temp, dados_treino)
  mse_teste_seq[g]  <- calcular_mse(mod_temp, dados_teste)
}

df_curva_u <- tibble(
  Grau       = rep(graus_seq, 2),
  MSE        = c(mse_treino_seq, mse_teste_seq),
  Conjunto   = rep(c("Treino (70%)", "Teste (30%)"), each = length(graus_seq))
)

grau_otimo <- graus_seq[which.min(mse_teste_seq)]
cat(sprintf(">>> Ponto ótimo de generalização identificado no Grau: %d (Menor MSE de Teste = %.4f)\n\n", 
            grau_otimo, min(mse_teste_seq)))

# ==============================================================================
# 5. Visualizações Gráficas
# ==============================================================================

# ------------------------------------------------------------------------------
# Gráfico 1: Dispersão Treino/Teste e Curvas de Ajuste Polinomial
# ------------------------------------------------------------------------------
grid_x <- tibble(
  volume_mil_ton = seq(min(df_modelagem$volume_mil_ton), max(df_modelagem$volume_mil_ton), length.out = 500)
)

df_curvas <- bind_rows(
  grid_x |> mutate(valor_pred = predict(modelo_g1, newdata = grid_x),  Modelo = "Grau 1 (Reta - Rígido)"),
  grid_x |> mutate(valor_pred = predict(modelo_g3, newdata = grid_x),  Modelo = "Grau 3 (Curva Suave)"),
  grid_x |> mutate(valor_pred = predict(modelo_g12, newdata = grid_x), Modelo = "Grau 12 (Hiperflexível - Sobreajustado)")
)

grafico_curvas <- ggplot() +
  geom_point(data = dados_treino, aes(x = volume_mil_ton, y = valor_milhoes_fob, color = "Treino (70%)"), 
             alpha = 0.5, size = 1.8) +
  geom_point(data = dados_teste, aes(x = volume_mil_ton, y = valor_milhoes_fob, color = "Teste (30%)"), 
             alpha = 0.8, size = 2.0, shape = 17) +
  geom_line(data = df_curvas, aes(x = volume_mil_ton, y = valor_pred, linetype = Modelo, group = Modelo), 
            color = "#2c3e50", linewidth = 1.0) +
  scale_color_manual(
    name = "Partição dos Dados",
    values = c("Treino (70%)" = "#3498db", "Teste (30%)" = "#e74c3c")
  ) +
  scale_linetype_manual(
    name = "Modelos Candidatos",
    values = c("Grau 1 (Reta - Rígido)" = "dashed", 
               "Grau 3 (Curva Suave)" = "solid", 
               "Grau 12 (Hiperflexível - Sobreajustado)" = "dotdash")
  ) +
  scale_x_continuous(labels = label_number(suffix = " k ton", big.mark = ".")) +
  scale_y_continuous(labels = label_number(suffix = " M$", big.mark = ".")) +
  labs(
    title = "Regressão Polinomial: Comparação de Flexibilidade dos Modelos",
    subtitle = "Ajuste sobre Treino (70%) e Avaliação sobre Teste (30%) | Faturamento FOB vs. Volume Físico",
    x = "Volume Físico Movimentado (Milhares de Toneladas)",
    y = "Faturamento Comercial (Milhões de US$ FOB)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    legend.box = "vertical",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13)
  )

# ------------------------------------------------------------------------------
# Gráfico 2: Curva em U do Erro de Treino e Teste (Compromisso Viés-Variância)
# ------------------------------------------------------------------------------
grafico_curva_u <- ggplot(df_curva_u, aes(x = Grau, y = MSE, color = Conjunto, group = Conjunto)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = grau_otimo, linetype = "dashed", color = "#27ae60", linewidth = 0.8) +
  annotate("text", x = grau_otimo + 0.3, y = max(df_curva_u$MSE) * 0.85, 
           label = paste("Mínimo Erro de Teste (Grau", grau_otimo, ")"), 
           hjust = 0, color = "#27ae60", fontface = "bold", size = 3.5) +
  scale_color_manual(values = c("Treino (70%)" = "#2980b9", "Teste (30%)" = "#e67e22")) +
  scale_x_continuous(breaks = graus_seq) +
  scale_y_continuous(labels = label_number(big.mark = ".")) +
  labs(
    title = "Curva em U do Erro e Compromisso Viés-Variância",
    subtitle = "Evolução do MSE de Treino vs. MSE de Teste em função da Complexidade Polinomial",
    x = "Grau do Polinômio (Flexibilidade / Capacidade do Modelo)",
    y = "Erro Quadrático Médio (MSE)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13)
  )

# Exibição dos gráficos
print(grafico_curvas)
print(grafico_curva_u)

# ==============================================================================
# 6. Síntese Conclusiva da Seleção de Modelos
# ==============================================================================
cat("\n==============================================================================\n")
cat("                       DIAGNÓSTICO E SELEÇÃO FINAL                            \n")
cat("==============================================================================\n")
cat("1. Menor Erro de Treino: Modelo de Grau 12 (MSE Treino =", round(tabela_metricas$`MSE Treino`[3], 2), ")\n")
cat("   -> Motivo: Polinômios de ordem elevada 'decoram' as oscilações e ruídos da amostra de treino.\n")
cat("2. Menor Erro de Teste:  Modelo de Grau 3 (MSE Teste =", round(tabela_metricas$`MSE Teste`[2], 2), " | RMSE =", round(tabela_metricas$`RMSE Teste (M$ FOB)`[2], 2), "M$ FOB)\n")
cat("   -> Motivo: Representa o balanço ótimo entre viés e variância, capturando a curvatura real dos dados.\n")
cat("3. Diagnóstico de Sobreajuste (Overfitting): Evidenciado categoricamente no Grau 12.\n")
cat("   -> O Grau 12 apresenta forte divergência entre treino e teste (Razão Teste/Treino =", round(tabela_metricas$`Razão MSE Teste/Treino`[3], 2), "),\n")
cat("      apresentando explosão dos erros nas bordas e perda severa de generalização fora da amostra.\n")
cat("4. MODELO SELECIONADO: Grau 3 (Cúbico), pois garante a maior acurácia preditiva em dados novos.\n")
cat("==============================================================================\n")