-- 1. CRIAÇÃO DAS TABELAS

-- Clientes
CREATE TABLE clientes (
    cliente_id VARCHAR(50) PRIMARY KEY,
    cliente_unico_id VARCHAR(50) NOT NULL,
    cep INT,
    cidade VARCHAR(100),
    estado VARCHAR(2)
);

-- Vendedores
CREATE TABLE vendedores (
    vendedor_id VARCHAR(50) PRIMARY KEY,
    cep INT,
    cidade VARCHAR(100),
    estado VARCHAR(2)
);

-- Produtos 
CREATE TABLE produtos (
    produto_id VARCHAR(50) PRIMARY KEY,
    categoria_nome VARCHAR(100),
    comprimento_nome INT,
    comprimento_descricao INT,
    fotos_qtd INT,
    peso_g INT,
    comprimento_cm INT,
    altura_cm INT,
    largura_cm INT
);

-- Pedidos
CREATE TABLE pedidos (
    pedido_id VARCHAR(50) PRIMARY KEY,
    cliente_id VARCHAR(50),
    status_pedido VARCHAR(30),
    data_compra TIMESTAMP,
    data_aprovacao TIMESTAMP,
    data_envio_transportadora TIMESTAMP,
    data_entrega_cliente TIMESTAMP,
    data_estimada_entrega TIMESTAMP,
    CONSTRAINT fk_pedidos_clientes FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

-- Itens do Pedido 
CREATE TABLE itens_pedido (
    item_pedido_id BIGSERIAL PRIMARY KEY,
    pedido_id VARCHAR(50),
    item_sequencial INT,
    produto_id VARCHAR(50),
    vendedor_id VARCHAR(50),
    data_limite_envio TIMESTAMP,
    preco NUMERIC(10, 2),
    valor_frete NUMERIC(10, 2),
    CONSTRAINT fk_itens_pedido_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id),
    CONSTRAINT fk_itens_pedido_produtos FOREIGN KEY (produto_id) REFERENCES produtos(produto_id),
    CONSTRAINT fk_itens_pedido_vendedores FOREIGN KEY (vendedor_id) REFERENCES vendedores(vendedor_id)
);

-- Pagamentos 
CREATE TABLE pagamentos_pedido (
    pagamento_id BIGSERIAL PRIMARY KEY,
    pedido_id VARCHAR(50),
    pagamento_sequencial INT,
    tipo_pagamento VARCHAR(30),
    parcelas INT,
    valor_pagamento NUMERIC(10, 2),
    CONSTRAINT fk_pagamentos_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id)
);

-- Avaliações
CREATE TABLE avaliacoes_pedido (
    avaliacao_registro_id BIGSERIAL PRIMARY KEY,
    avaliacao_id VARCHAR(50),
    pedido_id VARCHAR(50),
    nota INT,
    comentario_titulo TEXT,
    comentario_mensagem TEXT,
    data_criacao TIMESTAMP,
    data_resposta TIMESTAMP,
    CONSTRAINT fk_avaliacoes_pedidos FOREIGN KEY (pedido_id) REFERENCES pedidos(pedido_id)
);

-- 2. IMPORTAÇÃO 


-- 3.1 Tabelas Primárias
COPY clientes(cliente_id, cliente_unico_id, cep, cidade, estado)
FROM 'C:\olist_churn_analytics\olist_customers_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY vendedores(vendedor_id, cep, cidade, estado)
FROM 'C:\olist_churn_analytics\olist_sellers_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY produtos(produto_id, categoria_nome, comprimento_nome, comprimento_descricao, fotos_qtd, peso_g, comprimento_cm, altura_cm, largura_cm)
FROM 'C:\olist_churn_analytics\olist_products_dataset.csv'
DELIMITER ',' CSV HEADER;

-- 3.2 Tabelas Dependentes
COPY pedidos(pedido_id, cliente_id, status_pedido, data_compra, data_aprovacao, data_envio_transportadora, data_entrega_cliente, data_estimada_entrega)
FROM 'C:\olist_churn_analytics\olist_orders_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY itens_pedido(pedido_id, item_sequencial, produto_id, vendedor_id, data_limite_envio, preco, valor_frete)
FROM 'C:\olist_churn_analytics\olist_order_items_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY pagamentos_pedido(pedido_id, pagamento_sequencial, tipo_pagamento, parcelas, valor_pagamento)
FROM 'C:\olist_churn_analytics\olist_order_payments_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY avaliacoes_pedido(avaliacao_id, pedido_id, nota, comentario_titulo, comentario_mensagem, data_criacao, data_resposta)
FROM 'C:\olist_churn_analytics\olist_order_reviews_dataset.csv'
DELIMITER ',' CSV HEADER;


-- 3. LIMPEZA E TRADUÇÃO PRA PT


ALTER TABLE produtos 
    DROP COLUMN comprimento_nome,
    DROP COLUMN comprimento_descricao,
    DROP COLUMN fotos_qtd,
    DROP COLUMN comprimento_cm,
    DROP COLUMN altura_cm,
    DROP COLUMN largura_cm;

ALTER TABLE avaliacoes_pedido
    DROP COLUMN comentario_titulo,
    DROP COLUMN comentario_mensagem,
    DROP COLUMN data_criacao,
    DROP COLUMN data_resposta;

UPDATE pedidos
SET status_pedido = CASE status_pedido
    WHEN 'delivered' THEN 'entregue'
    WHEN 'shipped' THEN 'enviado'
    WHEN 'canceled' THEN 'cancelado'
    WHEN 'unavailable' THEN 'indisponivel'
    WHEN 'invoiced' THEN 'faturado'
    WHEN 'processing' THEN 'em_processamento'
    WHEN 'created' THEN 'criado'
    WHEN 'approved' THEN 'aprovado'
    ELSE status_pedido
END;

UPDATE pagamentos_pedido
SET tipo_pagamento = CASE tipo_pagamento
    WHEN 'credit_card' THEN 'cartao_de_credito'
    WHEN 'boleto' THEN 'boleto'
    WHEN 'voucher' THEN 'vale_compras'
    WHEN 'debit_card' THEN 'cartao_de_debito'
    WHEN 'not_defined' THEN 'nao_definido'
    ELSE tipo_pagamento
END;


-- 4. VALIDAÇÃO DOS REGISTROS CARREGADOS

SELECT 'clientes' AS tabela, COUNT(*) AS total FROM clientes
UNION ALL
SELECT 'vendedores', COUNT(*) FROM vendedores
UNION ALL
SELECT 'produtos', COUNT(*) FROM produtos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'itens_pedido', COUNT(*) FROM itens_pedido
UNION ALL
SELECT 'pagamentos_pedido', COUNT(*) FROM pagamentos_pedido
UNION ALL
SELECT 'avaliacoes_pedido', COUNT(*) FROM avaliacoes_pedido;


-- 1. Confirmar se a tradução do status dos pedidos funcionou
SELECT status_pedido, COUNT(*) AS total
FROM pedidos
GROUP BY status_pedido
ORDER BY total DESC;

-- 2. Confirmar se a tradução das formas de pagamento funcionou
SELECT tipo_pagamento, COUNT(*) AS total
FROM pagamentos_pedido
GROUP BY tipo_pagamento
ORDER BY total DESC;

-- 3. Confirmar que a tabela produtos ficou enxuta (apenas 3 colunas)
SELECT * FROM produtos LIMIT 5;

-- ANÁLISE DE CHURN E RETENÇÃO BÁSICA

-- Taxa de recompra 
WITH metricas_cliente AS (
    SELECT 
        c.cliente_unico_id,
        COUNT(p.pedido_id) AS total_pedidos
    FROM clientes as c
    JOIN pedidos as p ON c.cliente_id = p.cliente_id
    WHERE p.status_pedido = 'entregue'
    GROUP BY c.cliente_unico_id
)
SELECT 
    CASE 
        WHEN total_pedidos = 1 THEN 'compra_unica'
        ELSE 'recompra'
    END AS perfil_cliente,
    COUNT(*) AS qtd_clientes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentual
FROM metricas_cliente
GROUP BY 1
ORDER BY perfil_cliente;

--Impacto Financeiro
 
WITH perdas_operacionais AS (
    SELECT 
        p.status_pedido,
        p.pedido_id,
        (ip.preco + ip.valor_frete) AS valor_item
    FROM pedidos as p
    JOIN itens_pedido as ip ON p.pedido_id = ip.pedido_id
    WHERE p.status_pedido IN ('cancelado', 'indisponivel')
)
SELECT 
    status_pedido,
    COUNT(DISTINCT pedido_id) AS total_pedidos,
    ROUND(SUM(valor_item), 2) AS valor_total_perdido
FROM perdas_operacionais
GROUP BY status_pedido
ORDER BY valor_total_perdido DESC;
