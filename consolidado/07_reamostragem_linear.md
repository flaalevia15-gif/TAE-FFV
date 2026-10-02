# Consolidado — Reamostragem na Regressão Linear Múltipla

## 1. Objetivo da tarefa

Esta etapa teve como objetivo avaliar o comportamento dos modelos de regressão linear por meio de técnicas de reamostragem:

1. **Validação Cruzada K-Fold (K = 5):** avaliar o erro de predição fora da amostra e comparar um modelo simples com um modelo que também considera Município e Fluxo.
2. **Bootstrap (B = 2000):** quantificar a incerteza da estimativa do coeficiente associado ao peso da carga, obtendo o erro padrão e um intervalo de confiança de 95%.

---

## 2. Preparação dos dados

Foi utilizada a base `df_sazonal_lideres.csv`, carregada a partir da pasta `data/processed`.

Foram mantidas apenas as observações com:

- `Valor US$ FOB > 0`
- `Quilograma Líquido > 0`

Em seguida, foram criadas duas variáveis em escala logarítmica:

- `log_valor_fob = log(Valor US$ FOB)`
- `log_peso_kg = log(Quilograma Líquido)`

As variáveis `Município` e `Fluxo` foram transformadas em fatores, considerando os níveis definidos no código.

Após o tratamento, a base ficou com **481 observações**.

---

## 3. Validação Cruzada 5-Fold

Foram definidos dois modelos:

### Modelo 1 — Simples

```text
log_valor_fob ~ log_peso_kg
```

Esse modelo utiliza somente o peso da carga como variável explicativa.

### Modelo 2 — Com variáveis categóricas

```text
log_valor_fob ~ log_peso_kg + Municipio + Fluxo
```

Além do peso, esse modelo considera o município e o tipo de fluxo.

A base foi dividida aleatoriamente em **5 folds**. Em cada rodada, quatro partes foram utilizadas para treinamento e uma para validação.

Foram calculados:

- **MSE (Mean Squared Error):** erro quadrático médio;
- **RMSE (Root Mean Squared Error):** raiz do erro quadrático médio.

### Resultados

| Fold | MSE Modelo 1 | RMSE Modelo 1 | MSE Modelo 2 | RMSE Modelo 2 |
|---:|---:|---:|---:|---:|
| 1 | 0,9240 | 0,9612 | 0,9240 | 0,9612 |
| 2 | 1,1333 | 1,0646 | 1,1333 | 1,0646 |
| 3 | 1,1453 | 1,0702 | 1,1453 | 1,0702 |
| 4 | 0,8658 | 0,9305 | 0,8658 | 0,9305 |
| 5 | 1,2708 | 1,1273 | 1,2708 | 1,1273 |

Os valores obtidos para os dois modelos foram iguais em todos os folds apresentados.

Isso indica que, **nesta execução da validação cruzada**, o modelo com Município e Fluxo não apresentou diferença no erro de predição em relação ao modelo simples.

### Ajuste metodológico realizado

Durante a validação, o código verificou se `Município` e `Fluxo` possuíam mais de um nível no conjunto de treinamento de cada fold.

Essa verificação foi necessária porque um fold poderia apresentar apenas um nível de uma variável categórica, impedindo o ajuste normal do modelo `lm()`.

Quando essa situação ocorreria, o código utiliza o modelo simples como alternativa para aquela rodada, evitando a interrupção da execução.

---

## 4. Bootstrap

Na segunda parte foi utilizado o método **Bootstrap**, com **B = 2000 reamostragens**.

Em cada reamostragem:

1. Foram selecionadas 481 observações com reposição;
2. O modelo linear foi ajustado novamente;
3. O coeficiente associado a `log_peso_kg` foi armazenado.

Antes do Bootstrap, o código também verificou quais níveis das variáveis categóricas estavam disponíveis e ajustou a fórmula do modelo de maneira segura.

O objetivo foi observar como a estimativa do coeficiente varia quando diferentes amostras são retiradas da mesma base.

### Resultados

- **Estimativa original do coeficiente:** `0,9310`
- **Erro padrão Bootstrap:** `0,0174`
- **IC percentil de 95%:** `[0,8920 ; 0,9608]`

O intervalo de confiança foi obtido a partir dos percentis 2,5% e 97,5% da distribuição das 2000 estimativas Bootstrap.

---

## 5. Gráfico da distribuição Bootstrap

Foi produzido um gráfico contendo:

- histograma das estimativas obtidas nas 2000 reamostragens;
- curva de densidade;
- linha correspondente à estimativa original;
- linhas delimitando o intervalo de confiança de 95%.

O gráfico permite visualizar a distribuição das estimativas do coeficiente `log_peso_kg` e verificar a concentração dos resultados ao redor da estimativa original.

---

## 6. Resultado geral da tarefa

A etapa de reamostragem mostrou que:

- a base analisada possui **481 observações** após o tratamento;
- a validação cruzada foi realizada com **5 folds**;
- os dois modelos apresentaram os mesmos valores de MSE e RMSE nos cinco folds registrados;
- o coeficiente associado ao peso apresentou estimativa original de **0,9310**;
- o Bootstrap com **2000 reamostragens** produziu erro padrão de **0,0174**;
- o intervalo de confiança de 95% para o coeficiente foi **[0,8920; 0,9608]**.

Assim, esta etapa serviu para avaliar tanto o comportamento preditivo dos modelos fora da amostra quanto a incerteza associada à estimativa do efeito do peso sobre o valor FOB.

---

## 7. Conclusão

A reamostragem permitiu complementar a análise da regressão linear com duas perspectivas: **desempenho preditivo**, por meio da validação cruzada, e **incerteza estatística**, por meio do Bootstrap.

Na validação cruzada realizada, os resultados de erro dos modelos simples e ampliado foram iguais nos cinco folds. No Bootstrap, as 2000 reamostragens produziram uma distribuição das estimativas concentrada em torno do valor original de `0,9310`, com erro padrão de `0,0174` e intervalo de confiança de 95% entre `0,8920` e `0,9608`.
