# Consolidado --- 10. Análise com Splines

## 1. Objetivo da tarefa

A atividade teve como objetivo avaliar a evolução temporal dos preços
por tonelada das rotas comerciais brasileiras, utilizando modelos
capazes de representar relações não lineares.

Foram estudadas duas abordagens:

-   **Regression Splines (Spline Natural):** divide a relação em
    trechos, utilizando nós (*knots*) posicionados nos quantis dos
    dados. A spline natural impõe comportamento linear nas extremidades,
    ajudando a evitar oscilações excessivas fora dos limites observados.
-   **Smoothing Splines (Splines de Suavização):** utiliza os pontos
    observados como referência para construir uma curva suave. A
    flexibilidade é controlada por uma penalização da curvatura, cujo
    parâmetro é selecionado automaticamente pelo método GCV
    (*Generalized Cross-Validation*).

A atividade também comparou os modelos por validação cruzada e avaliou
seu desempenho ao prever períodos futuros.

## 2. Carregamento e preparação dos dados

Primeiro, o notebook carregou o script modular `analise_splines.R`. Em
seguida, executou as funções de preparação do ambiente, carregamento dos
dados e preparação da base específica para as splines.

A base preparada apresentou **481 registros**.

O notebook utiliza as funções `preparar_ambiente()`, `carregar_dados()`
e `preparar_base_splines()`. Como a implementação dessas funções está no
script externo, não incluído no notebook, os detalhes internos de cada
transformação não podem ser confirmados apenas pelo arquivo analisado.

## 3. Validação cruzada dos Regression Splines

Nesta etapa, foi realizada uma validação cruzada com **5 partes (CV-5)**
para comparar diferentes especificações temporais. O objetivo foi
selecionar os graus de liberdade (`df`) mais adequados para a Spline
Natural.

Foram avaliados: - Um modelo de referência sem variável temporal, com
`rota * log_peso`; - Um modelo linear no tempo, com
`rota * log_peso + rota:t`; - Splines naturais com graus de liberdade
iguais a 3, 4, 5, 6, 8 e 10.

### Resultados

  Modelo                   Graus de liberdade (df)    RMSE da CV
  ---------------------- ------------------------- -------------
  Baseline (sem tempo)                         ---       0,22571
  Linear no tempo                                1       0,21682
  Spline Natural                                 3       0,18713
  Spline Natural                                 4       0,11083
  Spline Natural                                 5       0,11268
  Spline Natural                                 6       0,08713
  Spline Natural                                 8       0,08439
  Spline Natural                                10   **0,07917**

### Interpretação

O menor RMSE foi obtido pela Spline Natural com **10 graus de liberdade
(0,07917)**. Entre os modelos avaliados, essa especificação apresentou o
melhor desempenho médio na validação cruzada.

Também é possível observar que a inclusão de uma estrutura temporal
melhorou os resultados em relação ao modelo sem tempo. O modelo linear
apresentou RMSE de 0,21682, enquanto as splines reduziram
progressivamente o erro conforme aumentaram os graus de liberdade,
embora a melhora entre `df = 4` e `df = 5` não tenha sido monotônica.

O RMSE mede a magnitude típica dos erros de previsão na escala da
variável resposta. **Quanto menor o RMSE, melhor o desempenho
preditivo**, considerando a mesma base e o mesmo procedimento de
avaliação.

## 4. Ajuste das Smoothing Splines por rota

Na segunda etapa, foram ajustadas Splines de Suavização separadamente
para cada rota. O notebook utilizou a função `smooth.spline()`, com
seleção automática do parâmetro de suavização por GCV.

O parâmetro `lambda` controla a penalização da curvatura: - Uma
penalização menor permite uma curva mais flexível, que acompanha mais de
perto os dados; - Uma penalização maior produz uma curva mais suave,
reduzindo oscilações.

O resultado apresentou os seguintes valores:

  Rota               Graus de liberdade efetivos     Lambda
  ---------------- ----------------------------- ----------
  Cubatão \| Exp                           43,80   0,000000
  Guarujá \| Exp                           21,13   0,000006
  Santos \| Exp                            25,12   0,000004
  Cubatão \| Imp                           34,29   0,000001
  Guarujá \| Imp                           32,66   0,000001
  Santos \| Imp                            37,88   0,000001

### Interpretação

Os graus de liberdade efetivos variaram entre as rotas, de **21,13 a
43,80**. Isso indica que o ajuste automático selecionou níveis
diferentes de flexibilidade para representar cada série temporal.

Cubatão na exportação apresentou o maior número de graus de liberdade
efetivos (43,80), enquanto Guarujá na exportação apresentou o menor
(21,13).

Os valores de `lambda` exibidos são muito pequenos. Isso é compatível
com ajustes relativamente flexíveis, mas a interpretação precisa depende
da escala e da implementação do procedimento. O notebook não apresenta
uma comparação numérica de RMSE entre as seis Smoothing Splines nesta
etapa; portanto, esses resultados devem ser entendidos como parâmetros
dos ajustes, e não como uma classificação de desempenho entre rotas.

## 5. Teste de extrapolação: passado versus futuro

A terceira etapa avaliou a capacidade dos modelos de prever observações
futuras. Para isso, o notebook executou `teste_futuro()` com
`t_corte = 79`, separando o período anterior para treinamento e
avaliando **70 observações de teste**.

Foram comparados quatro modelos: - Modelo sem variável temporal; - Reta
no tempo; - Spline Natural com `df = 4`; - Spline Natural com `df = 8`.

### Resultados

  Modelo                      Observações de teste   RMSE futuro
  ------------------------- ---------------------- -------------
  Sem tempo                                     70        0,1537
  Reta no tempo                                 70        0,2302
  Spline Natural (df = 4)                       70    **0,1338**
  Spline Natural (df = 8)                       70        0,2656

### Interpretação

A Spline Natural com **4 graus de liberdade** apresentou o menor RMSE
futuro (0,1338), sendo a melhor entre as quatro especificações avaliadas
nesse teste.

O modelo sem tempo obteve RMSE de 0,1537. Já a reta no tempo apresentou
erro maior (0,2302), e a Spline Natural com 8 graus de liberdade teve o
maior erro (0,2656).

Esse resultado é importante porque mostra que o modelo com melhor
resultado na validação cruzada não necessariamente é o melhor para
prever períodos futuros. Na CV-5, a Spline Natural com `df = 10` foi a
melhor; no teste futuro, a especificação com `df = 4` foi superior entre
os modelos testados.

Uma possível interpretação é que uma curva muito flexível pode se
ajustar bem aos padrões presentes nos dados usados na validação, mas ter
dificuldade para generalizar para períodos posteriores. O próprio
objetivo desta etapa é demonstrar o risco de extrapolação das splines.
Os números mostram que aumentar os graus de liberdade não garantiu
melhor previsão futura.

## 6. Visualização comparativa

Na última etapa, o notebook executou
`plotar_comparacao_splines(base_splines, df_ns = 5)`, gerando uma
visualização comparativa dos ajustes.

A chamada utiliza uma Spline Natural com `df = 5` para a comparação
visual. O arquivo registra a geração do gráfico, mas não contém uma
descrição textual dos detalhes visuais nem valores adicionais extraídos
dele. Por isso, não é possível afirmar, apenas com os resultados
registrados, quais trechos específicos da curva apresentam aumentos,
quedas ou pontos de mudança.

## 7. Conclusão geral

A atividade mostrou como as splines podem representar relações temporais
não lineares, oferecendo mais flexibilidade do que uma reta. Foram
aplicadas duas abordagens: Regression Splines, com graus de liberdade
definidos para a Spline Natural, e Smoothing Splines, cuja suavização
foi selecionada automaticamente por GCV.

Na validação cruzada CV-5, a Spline Natural com `df = 10` apresentou o
menor RMSE (**0,07917**). Entretanto, no teste de previsão do futuro, a
Spline Natural com `df = 4` obteve o melhor resultado (**RMSE =
0,1338**), enquanto a especificação com `df = 8` apresentou o maior erro
(**0,2656**).

Portanto, o principal aprendizado é que **o melhor ajuste dentro dos
dados disponíveis não é necessariamente o melhor modelo para prever
períodos futuros**. A escolha da complexidade deve considerar não apenas
o erro de validação, mas também a capacidade de generalização e o risco
de extrapolação. Um modelo excessivamente flexível pode acompanhar
oscilações da amostra e, ainda assim, produzir previsões futuras menos
precisas.

## 8. Resumo dos principais resultados

-   Base preparada: **481 registros**.
-   Melhor Regression Spline na CV-5: **df = 10**, RMSE = **0,07917**.
-   Graus de liberdade efetivos das Smoothing Splines: de **21,13 a
    43,80**, variando conforme a rota.
-   Melhor modelo no teste futuro: **Spline Natural com df = 4**, RMSE =
    **0,1338**.
-   Pior resultado no teste futuro entre os modelos comparados: **Spline
    Natural com df = 8**, RMSE = **0,2656**.
-   Conclusão central: maior flexibilidade pode melhorar o ajuste na
    validação cruzada, mas não garante melhor desempenho na previsão de
    períodos futuros.
