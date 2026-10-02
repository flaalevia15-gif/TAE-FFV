# Consolidado — Reamostragem na Regressão Logística

## 1. Objetivo da tarefa

Esta etapa teve como objetivo avaliar o modelo de regressão logística utilizando duas técnicas de reamostragem:

1. **Validação Cruzada K-Fold (K = 5):** estimar o desempenho preditivo do modelo por meio de Acurácia, Precisão, Recall e Especificidade.
2. **Bootstrap (B = 2000):** avaliar a distribuição e a incerteza do coeficiente logístico e do Odds Ratio.

---

## 2. Preparação dos dados

Foi utilizada a base `df_sazonal_lideres.csv`, localizada em `data/processed`.

O código identificou automaticamente a coluna relacionada ao peso que contém a palavra `Quilograma`.

A variável `Fluxo` foi transformada em uma variável binária:

- valor associado à Exportação → `1`
- demais valores → `0`

O peso em quilogramas também foi escalado para milhões:

```text
Quilograma_Liquido_Escalado = Quilograma_Liquido / 1.000.000
```

Foram removidas observações com valores ausentes nas variáveis utilizadas.

Após o tratamento, a base ficou com **481 observações**.

---

## 3. Modelo de regressão logística

Foi utilizado o modelo:

```text
Fluxo_bin ~ Quilograma_Liquido_Escalado
```

O modelo foi ajustado com distribuição binomial e função de ligação logit.

As probabilidades previstas foram transformadas em classes utilizando o ponto de corte de **0,5**:

- probabilidade ≥ 0,5 → classe 1;
- probabilidade < 0,5 → classe 0.

---

## 4. Validação Cruzada 5-Fold

A base foi dividida aleatoriamente em **5 folds**.

Em cada rodada:

1. quatro folds foram utilizados para treinamento;
2. um fold foi utilizado para validação;
3. o modelo logístico foi ajustado no conjunto de treinamento;
4. foram calculadas as probabilidades para o conjunto de validação;
5. as probabilidades foram convertidas em classes;
6. foram calculadas as métricas de desempenho.

As métricas utilizadas foram:

- **Acurácia:** proporção total de classificações corretas;
- **Precisão:** proporção das previsões positivas que realmente eram positivas;
- **Recall:** proporção dos casos positivos corretamente identificados;
- **Especificidade:** proporção dos casos negativos corretamente identificados.

### Resultados

| Fold | Acurácia | Precisão | Recall | Especificidade |
|---:|---:|---:|---:|---:|
| 1 | 0,7010 | 0,8333 | 0,5102 | 0,8958 |
| 2 | 0,7708 | 0,8788 | 0,6170 | 0,9184 |
| 3 | 0,7292 | 0,9200 | 0,4894 | 0,9592 |
| 4 | 0,7188 | 0,8065 | 0,5435 | 0,8800 |
| 5 | 0,6667 | 0,7879 | 0,5098 | 0,8444 |

Os resultados mostram que as métricas variaram entre os cinco folds, o que é esperado porque cada rodada utiliza uma divisão diferente entre treinamento e validação.

---

## 5. Bootstrap

Na segunda parte foi utilizado o método **Bootstrap**, com **B = 2000 reamostragens**.

Primeiro, foi ajustado o modelo na base original. Depois, em cada uma das 2000 iterações:

1. foram selecionadas 481 observações com reposição;
2. o modelo logístico foi ajustado novamente;
3. o coeficiente de `Quilograma_Liquido_Escalado` foi armazenado;
4. o Odds Ratio foi calculado a partir desse coeficiente.

O Odds Ratio foi calculado por:

```text
OR = exp(β)
```

---

## 6. Resultados do Bootstrap

Os resultados obtidos foram:

- **Beta original:** `0,016866`
- **Odds Ratio original:** `1,017009`
- **Erro padrão Bootstrap:** `0,001973`
- **IC 95% do Beta:** `[0,013423 ; 0,021196]`

O intervalo de confiança foi calculado pelo método percentil, utilizando os percentis 2,5% e 97,5% da distribuição das estimativas Bootstrap.

O código também calculou o intervalo de confiança do Odds Ratio, embora esse resultado não tenha sido impresso no output apresentado.

---

## 7. Gráfico da distribuição Bootstrap

Foi produzido um gráfico da distribuição das estimativas Bootstrap do coeficiente logístico.

O gráfico contém:

- histograma das estimativas;
- curva de densidade;
- indicação da estimativa original;
- limites do intervalo de confiança de 95%.

A finalidade é visualizar como o coeficiente varia entre as diferentes reamostragens.

---

## 8. Resultado geral da tarefa

A análise apresentou:

- **481 observações** utilizadas no modelo;
- validação cruzada com **5 folds**;
- avaliação por Acurácia, Precisão, Recall e Especificidade;
- **2000 reamostragens Bootstrap**;
- coeficiente original de `0,016866`;
- Odds Ratio original de `1,017009`;
- erro padrão Bootstrap de `0,001973`;
- intervalo de confiança de 95% do coeficiente entre `0,013423` e `0,021196`.

---

## 9. Conclusão

A etapa de reamostragem permitiu avaliar o modelo logístico tanto em relação ao seu desempenho de classificação quanto à incerteza da estimativa de seu coeficiente.

A validação cruzada mostrou variação das métricas entre os cinco folds, enquanto o Bootstrap permitiu construir uma distribuição empírica das estimativas do coeficiente logístico.

O coeficiente original foi `0,016866`, com erro padrão Bootstrap de `0,001973` e IC 95% de `[0,013423; 0,021196]`. O Odds Ratio correspondente na amostra original foi `1,017009`.

Esses resultados complementam a análise do modelo ao mostrar não apenas suas previsões, mas também a variação esperada das estimativas quando diferentes amostras da base são utilizadas.
