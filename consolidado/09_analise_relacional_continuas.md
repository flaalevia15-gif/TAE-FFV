# Consolidado --- Análise Relacional entre Variáveis Contínuas

## 1. Objetivo da tarefa

A tarefa teve como objetivo investigar a relação entre duas variáveis
contínuas da base de dados de movimentação comercial:

-   **Volume**, medido em milhões de toneladas;
-   **Valor FOB**, medido em milhões de dólares.

Para avaliar uma possível relação não linear entre essas variáveis,
foram utilizados dois métodos não paramétricos de suavização:
**KNN-Regressão** e **Kernel Smoothing**. O desempenho desses métodos
foi comparado com uma regressão linear simples estimada por OLS.

## 2. Carregamento da base e preparação

O notebook carregou as funções de apoio do script
`analise_relacional_continuas.R`, preparou o ambiente e importou a base
`df_sazonal_lideres.csv`.

A base foi carregada com sucesso, contendo **481 observações**.

Foram construídas as variáveis:

-   `volume_mil_ton = Quilograma Líquido / 1e6`;
-   `valor_milhoes_fob = Valor US$ FOB / 1e6`.

Em seguida, foram removidas as observações com valores ausentes nessas
duas variáveis.

### Estatísticas descritivas

  -----------------------------------------------------------------------
  Estatística                Volume (milhões de     Valor FOB (milhões de
                                     toneladas)                     US\$)
  ------------------- ------------------------- -------------------------
  Mínimo                                    0,0                       0,0

  1º quartil                               29,8                       2,6

  Mediana                                  50,3                      11,1

  Média                                    85,4                      31,8

  3º quartil                               87,8                      32,7

  Máximo                                  756,7                     340,9
  -----------------------------------------------------------------------

Os máximos são consideravelmente superiores às medianas, indicando uma
distribuição com valores elevados em parte das observações. Isso torna
útil investigar se uma única reta descreve adequadamente a relação entre
volume e valor.

## 3. Métodos utilizados

### 3.1 OLS --- regressão linear simples

O OLS foi usado como referência (*baseline*). Ele representa a relação
entre volume e Valor FOB por meio de uma reta, pressupondo que a
inclinação seja constante ao longo do intervalo analisado.

O erro foi avaliado por validação cruzada usando o RMSE.

### 3.2 KNN-Regressão

O KNN prevê o valor de uma observação usando a média dos valores das
observações mais próximas no eixo do volume. O parâmetro `k` determina
quantos vizinhos participam da previsão.

Foram testados os valores de `k` iguais a 3, 5, 10, 15, 20 e 40.

### 3.3 Kernel Smoothing

O Kernel Smoothing utiliza uma média ponderada das observações, dando
maior peso aos pontos mais próximos do volume de interesse. Foi
utilizado um estimador de Nadaraya-Watson com kernel Gaussiano.

A largura de banda `h` controla o grau de suavização. Foram avaliados
valores correspondentes a 0,05, 0,10, 0,20 e 0,40 vezes o desvio-padrão
de X.

## 4. Validação cruzada e resultados

A validação cruzada foi utilizada para comparar os erros preditivos dos
métodos e escolher os parâmetros de suavização. O indicador utilizado
foi o **RMSE de validação cruzada (RMSE_CV)**; valores menores indicam
menor erro preditivo nas divisões avaliadas.

### Resultados do OLS

  Modelo                   RMSE_CV
  ---------------------- ---------
  OLS --- reta simples     14,8430

### Resultados do KNN-Regressão

    Número de vizinhos (`k`)   RMSE_CV
  -------------------------- ---------
                           3     14,64
                           5     14,85
                          10     15,14
                          15     15,50
                          20     16,12
                          40     20,56

Entre os valores testados, **k = 3** apresentou o menor RMSE_CV, de
**14,64**. O erro aumentou conforme o número de vizinhos cresceu,
indicando que, neste conjunto de testes, utilizar muitos vizinhos
prejudicou o desempenho preditivo.

### Resultados do Kernel Smoothing

    Multiplicador de h   Largura de banda (`h`)   RMSE_CV
  -------------------- ------------------------ ---------
                  0,05                    5,331     14,27
                  0,10                   10,662     13,95
                  0,20                   21,324     15,04
                  0,40                   42,649     16,89

O melhor resultado entre as larguras de banda testadas foi obtido com
**h = 10,662**, correspondente a 0,10 vezes o desvio-padrão de X. O
RMSE_CV foi **13,95**, o menor erro entre todos os modelos e parâmetros
apresentados no notebook.

## 5. Comparação geral

  Método/configuração      RMSE_CV
  ---------------------- ---------
  OLS --- reta simples     14,8430
  KNN, k = 3                 14,64
  Kernel, h = 10,662         13,95

Entre as configurações testadas, o **Kernel Smoothing com h = 10,662**
teve o melhor desempenho preditivo. O KNN com `k = 3` também apresentou
erro ligeiramente inferior ao OLS.

## 6. Visualização das curvas

O notebook prepara uma grade de valores de volume e identifica os
melhores parâmetros encontrados pela validação cruzada para comparar as
curvas de suavização com os dados observados.

A interpretação prevista é observar como cada método acompanha a relação
entre volume e Valor FOB. Diferentemente da reta OLS, KNN e Kernel podem
representar variações locais na inclinação da relação.

## 7. Interpretação dos parâmetros

O parâmetro `k`, no KNN, e a largura de banda `h`, no Kernel, controlam
o equilíbrio entre viés e variância:

-   **Parâmetros muito pequenos:** a curva pode acompanhar oscilações
    locais excessivas, ficando mais irregular;
-   **Parâmetros muito grandes:** a curva tende a ficar mais suave e
    pode deixar de representar padrões locais importantes.

Os resultados de validação cruzada ajudam a selecionar um nível de
suavização que equilibre esses efeitos para os dados analisados.

## 8. Conclusão

A tarefa comparou uma regressão linear simples com dois métodos não
paramétricos para investigar a relação entre volume e Valor FOB.

O OLS apresentou RMSE_CV de **14,8430**. O melhor KNN foi obtido com **k
= 3**, com RMSE_CV de **14,64**. O menor erro geral foi obtido pelo
**Kernel Smoothing com h = 10,662**, cujo RMSE_CV foi **13,95**.

Assim, entre as configurações testadas, o Kernel Smoothing foi o método
com melhor desempenho preditivo. O resultado sugere que uma curva
flexível pode representar melhor a relação observada do que uma reta
simples, embora essa conclusão se limite aos dados, métodos e parâmetros
avaliados nesta tarefa.
