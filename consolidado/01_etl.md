# 01. Extração, Transformação e Carga (ETL) e Modelagem Dimensional

### Documentação da Etapa
* **Objetivo da etapa:** Consolidar os microdados particionados e estruturar o modelo dimensional em 3 tabelas em memória (`df_transacional`, `df_dimensao_sh4` e `df_sazonal`).
* **Dados de entrada:** Arquivos CSV particionados por biênios em `data/raw/` (`2019-01_2020-12.csv`, `2021-01_2022-12.csv`, `2023-01_2024-12.csv`, `2025-01_2026-07.csv`).
* **Procedimentos realizados:**
  1. Leitura unificada e validação do volume de registros.
  2. Limpeza textual e conversão de valores monetários/peso (padrão pt-BR para `numeric`).
  3. Separação de atributos de calendário (`mes_numero`, `mes_nome`).
  4. Derivação da Tabela Dimensão Produto (`df_dimensao_sh4`), da Fato Transacional (`df_transacional`) e do Agregado Temporal (`df_sazonal`).
* **Resultados obtidos:** Criação das três estruturas tabulares em memória e exportação de `dados_completos_2019_2026.csv` em `data/processed/`.
* **Interpretação:** A base está estruturada de forma dimensional, otimizando o consumo de memória e preparando as agregações necessárias para as análises descritivas e econométricas.
* **Decisões metodológicas:** Manter as descrições textuais dos produtos isoladas na tabela dimensão para evitar redundância e ganho de eficiência no processamento.
* **Próximo passo:** Entendimento e validação da qualidade dos dados e recorte geográfico regional (`02_entendimento_dados.ipynb`).

### Considerações finais

Nesta etapa, foi realizada a derivação de três estruturas fundamentais para a organização e análise dos dados. A **Tabela Dimensão Produto (`df_dimensao_sh4`)** concentra as informações relacionadas aos produtos classificados pelo código SH4, mantendo suas descrições de forma separada e evitando a repetição dessas informações na base principal. A **Tabela Fato Transacional (`df_transacional`)** reúne os registros das operações de comércio exterior, contendo os dados necessários para representar cada transação. Já o **Agregado Temporal (`df_sazonal`)** organiza e resume as informações por períodos de tempo, permitindo analisar o comportamento dos dados ao longo dos meses e anos. Dessa forma, a derivação dessas três estruturas estabelece uma organização dimensional da base, facilitando a consulta, a redução de redundâncias e a realização das análises posteriores.
