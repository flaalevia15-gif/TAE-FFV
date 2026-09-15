# 02. Entendimento dos Dados e Recorte Geográfico

### Documentação da Etapa
* **Objetivo da etapa:** Analisar a representatividade comercial dos municípios da Baixada Santista e justificar estatisticamente o afunilamento do estudo aos 3 polos principais.
* **Dados de entrada:** Base bruta consolidada da Região Metropolitana (`data/raw/toda_baixada_2019-01_2026-07.csv`).
* **Procedimentos realizados:**
  1. Limpeza e padronização monetária da base regional completa.
  2. Cálculo de rankings anuais de participação financeira (Valor US$ FOB) para Exportações e Importações.
  3. Análise de assiduidade e consistência histórica das posições de topo.
  4. Consolidação do ranking geral acumulado (2019–2026).
* **Resultados obtidos:** Constatação de que Santos, Cubatão e Guarujá concentram conjuntamente mais de 99% de todo o fluxo monetário da região.
* **Interpretação:** A expressiva dominância desses 3 municípios justifica descartar os demais, eliminando ruídos amostrais de municípios com fluxos esparsos sem comprometer a representatividade do complexo portuário.
* **Decisões metodológicas:** Utilizar o corte Top 3 baseado no volume financeiro agregado no período completo.
* **Próximo passo:** Análise Exploratória de Dados detalhada e mensuração de concentração de mercado via HHI (`03_eda_concentracao.ipynb`).

### Resultados: Assiduidade e Participação Acumulada
================================================================================ 
                      RESUMO INTERPRETÁVEL DOS RESULTADOS                       
================================================================================ 

>>> TOP 3 DE EXPORTAÇÕES POR ANO:
 • 2019: 1º Santos - SP (65.82%), 2º Guarujá - SP (17.55%), 3º Cubatão - SP (16.41%)
 • 2020: 1º Santos - SP (65.34%), 2º Guarujá - SP (21.11%), 3º Cubatão - SP (13.29%)
 • 2021: 1º Santos - SP (62.44%), 2º Guarujá - SP (21.12%), 3º Cubatão - SP (16.11%)
 • 2022: 1º Santos - SP (64.93%), 2º Cubatão - SP (20.61%), 3º Guarujá - SP (14.15%)
 • 2023: 1º Santos - SP (70.14%), 2º Cubatão - SP (17.67%), 3º Guarujá - SP (11.87%)
 • 2024: 1º Santos - SP (74.91%), 2º Cubatão - SP (13.74%), 3º Guarujá - SP (10.98%)
 • 2025: 1º Santos - SP (76.28%), 2º Cubatão - SP (14.63%), 3º Guarujá - SP (8.84%)
 • 2026: 1º Santos - SP (75.84%), 2º Cubatão - SP (14.56%), 3º Guarujá - SP (9.42%)

>>> TOP 3 DE IMPORTAÇÕES POR ANO:
 • 2019: 1º Santos - SP (49.42%), 2º Cubatão - SP (30.92%), 3º Guarujá - SP (18.7%)
 • 2020: 1º Santos - SP (60.26%), 2º Cubatão - SP (19.96%), 3º Guarujá - SP (18.42%)
 • 2021: 1º Santos - SP (43.35%), 2º Cubatão - SP (41.08%), 3º Guarujá - SP (14.91%)
 • 2022: 1º Cubatão - SP (43.69%), 2º Santos - SP (43.48%), 3º Guarujá - SP (12.3%)
 • 2023: 1º Santos - SP (50.65%), 2º Cubatão - SP (25.49%), 3º Guarujá - SP (22.82%)
 • 2024: 1º Santos - SP (52.17%), 2º Cubatão - SP (29.3%), 3º Guarujá - SP (17.66%)
 • 2025: 1º Santos - SP (78.81%), 2º Cubatão - SP (12.57%), 3º Guarujá - SP (8.28%)
 • 2026: 1º Santos - SP (49.49%), 2º Cubatão - SP (34.25%), 3º Guarujá - SP (15.65%)

## Ranking geral acumulado — Exportações (2019–2026)

| Ranking | Município | Valor US$ FOB | Participação acumulada |
|---:|---|---:|---:|
| 1 | Santos - SP | 37.482.104.393 | 70,49% |
| 2 | Cubatão - SP | 8.492.580.333 | 15,97% |
| 3 | Guarujá - SP | 7.046.272.804 | 13,25% |
| 4 | São Vicente - SP | 145.898.008 | 0,27% |
| 5 | Mongaguá - SP | 1.607.133 | 0,00% |
| 6 | Praia Grande - SP | 1.532.685 | 0,00% |
| 7 | Itanhaém - SP | 567.872 | 0,00% |
| 8 | Peruíbe - SP | 537.888 | 0,00% |
| 9 | Bertioga - SP | 71.168 | 0,00% |

## Ranking geral acumulado — Importações (2019–2026)

| Ranking | Município | Valor US$ FOB | Participação acumulada |
|---:|---|---:|---:|
| 1 | Santos - SP | 10.650.841.644 | 56,27% |
| 2 | Cubatão - SP | 5.359.802.652 | 28,32% |
| 3 | Guarujá - SP | 2.784.357.581 | 14,71% |
| 4 | São Vicente - SP | 108.219.439 | 0,57% |
| 5 | Praia Grande - SP | 13.492.452 | 0,07% |
| 6 | Itanhaém - SP | 3.996.552 | 0,02% |
| 7 | Bertioga - SP | 3.433.476 | 0,02% |
| 8 | Peruíbe - SP | 1.710.112 | 0,01% |
| 9 | Mongaguá - SP | 651.517 | 0,00% |
