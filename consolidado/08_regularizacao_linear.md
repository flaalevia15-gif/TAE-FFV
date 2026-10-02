# Consolidado --- Regularização Linear

## 1. Objetivo

A tarefa aplicou **Ridge (L2), Lasso (L1) e Elastic Net** à mesma
regressão linear múltipla consolidada anteriormente:

**Valor FOB \~ Volume \* Rota Líder**

O objetivo foi analisar como a regularização modifica os coeficientes, a
quantidade de preditores mantidos e o desempenho preditivo em validação
cruzada.

## 2. Preparação dos dados

Foi utilizada a base `df_sazonal_lideres.csv`.

Foram construídas: - `volume_mil_ton`: volume convertido para milhões de
toneladas; - `valor_milhoes_fob`: Valor US\$ FOB convertido para milhões
de dólares; - `rota_lider`: combinação de Município + Fluxo + País +
Descrição SH4.

A estrutura da regressão anterior foi mantida, sem novos preditores. A
matriz de projeto foi construída com `model.matrix()`, incluindo as
variáveis de rota e as interações entre volume e rota.

## 3. Modelo OLS

O OLS foi utilizado como modelo de referência.

-   MSE: **156,6**
-   RMSE: **12,51**
-   Preditores não nulos: **11**

## 4. Ridge

A Ridge utiliza penalização L2 e reduz a magnitude dos coeficientes, sem
necessariamente zerá-los.

-   Alpha: **0**
-   Lambda: **4,8818**
-   Seleção: `lambda.min`
-   MSE: **175,1**
-   RMSE: **13,23**
-   Preditores não nulos: **11**

## 5. Lasso

A Lasso utiliza penalização L1 e pode zerar coeficientes, realizando
seleção de variáveis.

### Lasso --- `lambda.min`

-   Alpha: **1**
-   Lambda: **0,2667**
-   MSE: **154,0**
-   RMSE: **12,41**
-   Preditores não nulos: **7**

### Lasso --- `lambda.1se`

-   Alpha: **1**
-   Lambda: **2,4868**
-   MSE: **179,0**
-   RMSE: **13,38**
-   Preditores não nulos: **5**

O `lambda.1se` produz uma solução mais simples, reduzindo o modelo para
5 preditores não nulos.

## 6. Elastic Net

O Elastic Net combina as penalizações L1 e L2.

-   Alpha: **0,5**
-   Lambda: **0,2103**
-   Seleção: `lambda.min`
-   MSE: **155,5**
-   RMSE: **12,47**
-   Preditores não nulos: **9**

## 7. Comparação

  -------------------------------------------------------------------------------
  Modelo         Alpha     Lambda Seleção          CV MSE    CV RMSE   Preditores
                                                                        não nulos
  --------- ---------- ---------- ------------ ---------- ---------- ------------
  OLS              ---        --- OLS               156,6      12,51           11

  Ridge              0     4,8818 lambda.min        175,1      13,23           11

  Lasso              1     0,2667 lambda.min        154,0      12,41            7

  Lasso              1     2,4868 lambda.1se        179,0      13,38            5

  Elastic          0,5     0,2103 lambda.min        155,5      12,47            9
  Net                                                                
  -------------------------------------------------------------------------------

## 8. Comparação dos coeficientes

A comparação dos coeficientes mostrou o efeito direto da regularização.

Para `volume_mil_ton`:

-   OLS: **0,47291**
-   Ridge: **0,25570**
-   Lasso (`lambda.1se`): **0,429853**
-   Elastic Net: **0,437940**

A Lasso também zerou alguns coeficientes associados às categorias de
`rota_lider`, demonstrando sua capacidade de seleção de variáveis.

## 9. Validação cruzada

Os modelos foram avaliados por validação cruzada utilizando **MSE** e
**RMSE**. O RMSE representa o erro na mesma escala da variável resposta
e permite comparar o desempenho preditivo dos modelos.

## 10. Resultados principais

Os RMSEs obtidos foram:

-   OLS: **12,51**
-   Ridge: **13,23**
-   Lasso (`lambda.min`): **12,41**
-   Lasso (`lambda.1se`): **13,38**
-   Elastic Net: **12,47**

Na tabela de comparação, a Lasso com `lambda.min` apresentou o menor
RMSE. Já a Lasso com `lambda.1se` produziu o modelo mais simples, com
somente 5 preditores não nulos.

## 11. Conclusão

A tarefa demonstrou como Ridge, Lasso e Elastic Net podem controlar a
complexidade de uma regressão linear.

A **Ridge** reduziu a magnitude dos coeficientes, mantendo os 11
preditores. A **Lasso** realizou seleção de variáveis, mantendo 7
preditores com `lambda.min` e 5 com `lambda.1se`. O **Elastic Net**
manteve 9 preditores.

Os resultados mostram um equilíbrio entre desempenho preditivo e
simplicidade do modelo. A Lasso com `lambda.min` apresentou RMSE de
**12,41**, enquanto `lambda.1se` produziu uma solução mais enxuta, com 5
preditores não nulos.
