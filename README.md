# Análise de Churn, Retenção e Segmentação RFM — Olist 

Este projeto analisa o comportamento de compra e a retenção de clientes no e-commerce da Olist. Utilizei PostgreSQL para toda a parte de extração, limpeza e modelagem dos dados, e VS Code para organizar os scripts e a documentação antes de subir tudo para o GitHub e conectar ao Power BI.

---

# Objetivos do Projeto

- Identificar o tamanho real do problema de retenção na base da Olist, calculando a taxa de recompra e a proporção de clientes de compra única.
- Mensurar o impacto financeiro direto causado por cancelamentos e pedidos indisponíveis no sistema.
- Criar um modelo completo de segmentação RFM (Recência, Frequência e Valor Monetário) tratando as datas e aplicando regras claras de pontuação.
- Classificar a base em 6 personas de negócio para facilitar ações direcionadas de marketing e retenção.
- Estruturar e disponibilizar views otimizadas no PostgreSQL para servir de base direta para o dashboard no Power BI.

# Fonte dos Dados

Os dados brutos vêm do dataset público da Olist no Kaggle: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

# Detalhamento das Etapas e Scripts SQL

## 1. Extração, Limpeza e Diagnóstico Inicial (`SQL/extracao_limpeza.sql`)

Nesta primeira etapa, fiz o levantamento dos dados operacionais e entendi o comportamento inicial do cliente na plataforma.

**Diagnóstico de Recompra:**
Ao cruzar a contagem de pedidos entregues por cliente único, identificamos que a plataforma sofre com uma dependência extrema de novos clientes:
- **Clientes de compra única:** 97,00% da base.
- **Taxa de recompra:** Apenas 3,00% dos clientes voltaram a fazer um segundo pedido.

**Impacto Financeiro por Falha Operacional:**
Calculando a soma do valor dos itens somado ao frete para pedidos com status cancelado ou indisponível, identificamos um valor considerável retido ou perdido em falhas de processo:
- **Prejuízo em pedidos cancelados e indisponíveis:** R$ 108.026,21.

---

## 2. Cálculo da Lógica RFM e Agrupamento em Personas (`SQL/rfm.sql`)

Para contornar o problema de retenção, montei a inteligência da segmentação RFM. Como a base de dados histórica possui um ponto final específico, utilizei o recurso de buscar a data máxima da base através de um `CROSS JOIN` para calcular a recência real em dias com exatidão (`::date`).

O modelo distribui notas de 1 a 5 para três critérios:
- **Recência (R):** Quantidade de dias desde a última compra até a data máxima da base (quanto menor a quantidade de dias, maior a nota).
- **Frequência (F):** Quantidade total de pedidos realizados pelo cliente.
- **Monetário (M):** Soma total gasta pelo cliente em suas compras.

Com base na combinação dessas notas, apliquei regras condicionais (`CASE WHEN`) para agrupar os 93.098 clientes em 6 personas estratégicas:

1. **Atenção / Em Desenvolvimento:** Representa 46.443 clientes (49,75% da base) com ticket médio de R$ 159,99. São clientes que compraram há um tempo intermediário, fizeram poucas compras e possuem gasto mediano.
2. **Inativos / Perdidos:** Representa 30.768 clientes (32,98% da base) com ticket médio de R$ 60,20. São clientes que não compram há muito tempo e tiveram um gasto total baixo.
3. **Em Risco (Alto Valor):** Representa 9.594 clientes (10,28% da base) com ticket médio de R$ 514,63. São clientes que realizaram compras de alto valor no passado, mas estão há bastante tempo sem comprar novamente.
4. **Novos / Promissores:** Representa 4.426 clientes (4,74% da base) com ticket médio de R$ 60,59. São clientes com recência muito recente, mas que ainda realizaram apenas a primeira compra de valor inicial.
5. **VIP / Campeões:** Representa 1.344 clientes (1,44% da base) com ticket médio de R$ 525,18. São os melhores clientes da base, que compraram recentemente, possuem boa frequência e o maior ticket médio da plataforma.
6. **Clientes Leais:** Representa 763 clientes (0,82% da base) com ticket médio de R$ 294,53. São clientes com padrão de compra recorrente e bom histórico de engajamento.

*Análise de Destaque:* A persona **Em Risco (Alto Valor)** representa mais de 10% da base total de clientes e tem um ticket médio muito alto (R$ 514,63). Focar campanhas de reativação de CRM nesse grupo específico traz o maior retorno financeiro possível com o menor custo de atração.

---

## 3. Construção das Views para o Power BI (`SQL/views.sql`)

Para garantir uma conexão limpa e performática com o Power BI sem carregar o relatório com cálculos pesados, criei duas visões diretamente no PostgreSQL:

1. **`vw_churn_rfm_clientes`**: Tabela detalhada em nível de cliente contendo o ID único, dias de recência, total de pedidos, valor monetário, notas individuais de R, F e M e o nome final da persona atribuída.
2. **`vw_resumo_rfm_personas`**: Tabela agregada com a contagem total de clientes, percentual sobre a base e ticket médio consolidado para cada uma das 6 personas.

## 4. Construção e Formatação do Dashboard 

Na etapa final de visualização, desenvolvi um painel dinâmico e interativo no Power BI conectado às views do PostgreSQL.

**Design Visual e UX/UI:**
- **Cartões de KPIs Superior:** Indicadores de volume total de clientes, média de inatividade em dias, ticket médio e faturamento total.
- **Paleta Cromática Semântica:** Definição de cores padronizadas com códigos HEX equivalentes em todos os visuais para identificação imediata das personas:
  - **Em Risco (Alto Valor):** Tom coral/vermelho em destaque para sinalizar urgência em retenção.
  - **Atenção / Em Desenvolvimento:** Tom lilás/roxo suave para acompanhamento de grande volume da base.
  - **Inativos / Perdidos:** Tom cinza-aço em segundo plano neutro.
- **Análise Temporal e Regional:** Gráfico de linhas dinâmico com ajuste automático de granularidade por período e tabela descritiva com o *Top 5 Cidades em Risco de Churn* acompanhada da média de inatividade.