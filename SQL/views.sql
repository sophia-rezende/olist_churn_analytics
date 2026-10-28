-- CRIAÇÃO DAS VIEWS 

CREATE OR REPLACE VIEW vw_churn_rfm_clientes AS
WITH data_maxima AS (
    SELECT MAX(p.data_compra::date) AS ultima_data_base 
    FROM pedidos AS p
),
rfm_bruto AS (
    SELECT 
        c.cliente_unico_id AS cliente_unico_id,
        (m.ultima_data_base - MAX(p.data_compra::date)) AS recencia_dias,
        COUNT(DISTINCT p.pedido_id) AS frequencia,
        ROUND(SUM(ip.preco + ip.valor_frete), 2) AS monetario
    FROM clientes AS c
    JOIN pedidos AS p ON c.cliente_id = p.cliente_id
    JOIN itens_pedido AS ip ON p.pedido_id = ip.pedido_id
    CROSS JOIN data_maxima AS m
    WHERE p.status_pedido = 'entregue'
    GROUP BY c.cliente_unico_id, m.ultima_data_base
),
rfm_pontuado AS (
    SELECT 
        r.cliente_unico_id AS cliente_unico_id,
        r.recencia_dias AS recencia_dias,
        r.frequencia AS frequencia,
        r.monetario AS monetario,
        
        CASE 
            WHEN r.recencia_dias <= 30 THEN 5
            WHEN r.recencia_dias <= 90 THEN 4
            WHEN r.recencia_dias <= 180 THEN 3
            WHEN r.recencia_dias <= 360 THEN 2
            ELSE 1
        END AS r_score,

        CASE 
            WHEN r.frequencia >= 3 THEN 5
            WHEN r.frequencia = 2 THEN 3
            ELSE 1
        END AS f_score,

        CASE 
            WHEN r.monetario >= 500 THEN 5
            WHEN r.monetario >= 250 THEN 4
            WHEN r.monetario >= 100 THEN 3
            WHEN r.monetario >= 50 THEN 2
            ELSE 1
        END AS m_score
    FROM rfm_bruto AS r
)
SELECT 
    p.cliente_unico_id AS cliente_unico_id,
    p.recencia_dias AS recencia_dias,
    p.frequencia AS frequencia,
    p.monetario AS monetario,
    p.r_score AS r_score,
    p.f_score AS f_score,
    p.m_score AS m_score,
    CONCAT(p.r_score, p.f_score, p.m_score) AS rfm_score_concatenado,
    
    CASE 
        WHEN p.r_score >= 4 AND p.m_score >= 4 THEN 'VIP / Campeões'
        WHEN p.r_score >= 3 AND p.f_score >= 3 THEN 'Clientes Leais'
        WHEN p.r_score >= 4 AND p.m_score <= 2 THEN 'Novos / Promissores'
        WHEN p.r_score <= 2 AND p.m_score >= 4 THEN 'Em Risco (Alto Valor)'
        WHEN p.r_score <= 2 AND p.m_score <= 2 THEN 'Inativos / Perdidos'
        ELSE 'Atencao / Em Desenvolvimento'
    END AS segmento_persona

FROM rfm_pontuado AS p;

SELECT * 
FROM vw_churn_rfm_clientes 
LIMIT 10;

CREATE OR REPLACE VIEW vw_resumo_rfm_personas AS
SELECT 
    v.segmento_persona AS segmento_persona,
    COUNT(*) AS total_clientes,
    ROUND(AVG(v.monetario), 2) AS ticket_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentual
FROM vw_churn_rfm_clientes AS v
GROUP BY v.segmento_persona
ORDER BY total_clientes DESC;

SELECT 
    r.segmento_persona AS segmento_persona,
    r.total_clientes AS total_clientes,
    r.ticket_medio AS ticket_medio,
    r.percentual AS percentual
FROM vw_resumo_rfm_personas AS r;