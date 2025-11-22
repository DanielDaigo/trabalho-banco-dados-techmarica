DROP DATABASE IF EXISTS tech_marica;
CREATE DATABASE tech_marica;
USE tech_marica;

-- 1. DDL - CRIAÇÃO DAS TABELAS

CREATE TABLE funcionarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    area_atuacao VARCHAR(50) NOT NULL, -- Ex: Montagem, Qualidade, Almoxarifado
    ativo TINYINT(1) DEFAULT 1, -- 1 = Ativo, 0 = Inativo
    data_admissao DATE NOT NULL
);

CREATE TABLE maquinas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_modelo VARCHAR(100) NOT NULL,
    fabricante VARCHAR(50),
    ano_fabricacao INT
);

CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cod_interno VARCHAR(20) NOT NULL UNIQUE, -- Ex: SENS-001
    nome_comercial VARCHAR(100) NOT NULL,
    responsavel_tecnico VARCHAR(100) NOT NULL, -- Nome do Engenheiro responsável pelo design
    custo_producao DECIMAL(10,2) NOT NULL,
    data_criacao_catalogo DATE NOT NULL -- Para calcular a "idade" do produto
);

CREATE TABLE ordens_producao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    id_maquina INT NOT NULL,
    id_funcionario_autorizou INT NOT NULL, -- Quem deu o start na ordem
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME DEFAULT NULL, -- Pode ser nulo enquanto não acabar
    status ENUM('EM PRODUÇÃO', 'FINALIZADA', 'CANCELADA') DEFAULT 'EM PRODUÇÃO',
    FOREIGN KEY (id_produto) REFERENCES produtos(id),
    FOREIGN KEY (id_maquina) REFERENCES maquinas(id),
    FOREIGN KEY (id_funcionario_autorizou) REFERENCES funcionarios(id)
);

-- 2. DML - INSERÇÃO DE DADOS

INSERT INTO funcionarios (nome, area_atuacao, ativo, data_admissao) VALUES
('Carlos Eduardo', 'Supervisão de Linha', 1, '2020-05-10'),
('Fernanda Lima', 'Operação de Máquinas', 1, '2021-08-20'),
('Roberto Souza', 'Controle de Qualidade', 0, '2019-02-15'), -- Inativo
('Amanda Nunes', 'Logística', 1, '2023-01-10'),
('Jorge Silva', 'Manutenção', 0, '2018-11-30'); -- Inativo

INSERT INTO maquinas (nome_modelo, fabricante, ano_fabricacao) VALUES
('Robô Soldador R-200', 'TechWeld', 2022),
('Impressora de Circuitos PCB-X', 'PrintTron', 2021),
('Esteira Automatizada V5', 'MovTech', 2023);

INSERT INTO produtos (cod_interno, nome_comercial, responsavel_tecnico, custo_producao, data_criacao_catalogo) VALUES
('SENS-01', 'Sensor de Umidade IoT', 'Eng. Mônica', 45.50, '2020-01-15'),
('MOD-WIFI', 'Módulo Wi-Fi 5G', 'Eng. Pedro', 80.00, '2021-06-10'),
('CIRC-A1', 'Placa Mãe Industrial', 'Eng. Mônica', 250.00, '2019-03-22'),
('LED-SMART', 'Painel LED Inteligente', 'Eng. Lucas', 120.00, '2022-11-05'),
('BAT-LIT', 'Bateria Lítio 5000mAh', 'Eng. Pedro', 30.00, '2024-02-01');

INSERT INTO ordens_producao (id_produto, id_maquina, id_funcionario_autorizou, data_inicio, data_conclusao, status) VALUES
(1, 2, 1, '2025-11-01 08:00:00', '2025-11-01 12:00:00', 'FINALIZADA'),
(2, 1, 2, '2025-11-02 09:00:00', NULL, 'EM PRODUÇÃO'),
(3, 2, 1, '2025-11-03 10:00:00', '2025-11-03 16:00:00', 'FINALIZADA'),
(1, 2, 4, '2025-11-05 14:00:00', NULL, 'CANCELADA'), -- Ordem cancelada
(4, 3, 2, '2025-11-10 07:30:00', NULL, 'EM PRODUÇÃO');

-- 3. CONSULTAS SQL

-- Listagem completa das ordens com nomes (Produto, Máquina, Funcionario)
SELECT 
    op.id AS 'Cód. Ordem',
    p.nome_comercial AS 'Produto',
    m.nome_modelo AS 'Máquina Utilizada',
    f.nome AS 'Autorizado Por',
    op.data_inicio,
    op.status
FROM ordens_producao op
INNER JOIN produtos p ON op.id_produto = p.id
INNER JOIN maquinas m ON op.id_maquina = m.id
INNER JOIN funcionarios f ON op.id_funcionario_autorizou = f.id
ORDER BY op.data_inicio DESC;

-- Filtragem de Funcionários INATIVOS
SELECT nome, area_atuacao, data_admissao 
FROM funcionarios 
WHERE ativo = 0;

-- Contagem total de produtos por Responsável Técnico (GROUP BY)
SELECT 
    responsavel_tecnico AS 'Engenheiro Responsável', 
    COUNT(*) AS 'Total de Produtos Criados'
FROM produtos
GROUP BY responsavel_tecnico
ORDER BY COUNT(*) DESC;

-- Seleção de produtos que começam com a letra 'S' (LIKE)
SELECT nome_comercial, cod_interno 
FROM produtos 
WHERE nome_comercial LIKE 'S%';

-- Cálculo da idade do produto em ANOS (Funções de Data)
SELECT 
    nome_comercial, 
    data_criacao_catalogo,
    TIMESTAMPDIFF(YEAR, data_criacao_catalogo, CURDATE()) AS 'Idade (Anos)'
FROM produtos;

-- 4. VIEW
/*
View para o gerente de produção acompanhar os dados 
sem precisar fazer os JOINs manualmente.
*/

CREATE VIEW vw_relatorio_producao AS
SELECT 
    p.nome_comercial AS Produto,
    p.cod_interno AS Codigo,
    m.nome_modelo AS Maquina,
    op.status AS Situacao_Atual,
    op.data_inicio
FROM ordens_producao op
JOIN produtos p ON op.id_produto = p.id
JOIN maquinas m ON op.id_maquina = m.id;

SELECT * FROM vw_relatorio_producao WHERE Situacao_Atual = 'EM PRODUÇÃO';

-- 5. STORED PROCEDURE
/*
Procedure para registrar nova ordem. 
Recebe IDs, pega a data atual e seta status inicial.
*/

DELIMITER $$

CREATE PROCEDURE sp_nova_ordem_producao(
    IN p_id_produto INT,
    IN p_id_funcionario INT,
    IN p_id_maquina INT
)
BEGIN
    -- Insere a nova ordem com status padrão
    INSERT INTO ordens_producao (id_produto, id_funcionario_autorizou, id_maquina, status)
    VALUES (p_id_produto, p_id_funcionario, p_id_maquina, 'EM PRODUÇÃO');

    -- Retorna mensagem de sucesso
    SELECT 'Ordem de produção aberta com sucesso!' AS Mensagem;
END $$

DELIMITER ;

CALL sp_nova_ordem_producao(5, 2, 1);

-- 6. TRIGGER
/*
Trigger para atualizar status automaticamente.
Regra: Se o usuário atualizar a 'data_conclusao' (que antes era NULL)
para uma data válida, o status muda sozinho para 'FINALIZADA'.
*/

DELIMITER $$

CREATE TRIGGER trg_atualiza_status_finalizada
BEFORE UPDATE ON ordens_producao
FOR EACH ROW
BEGIN
    -- Verifica se a data de conclusão está sendo preenchida agora
    IF NEW.data_conclusao IS NOT NULL AND OLD.data_conclusao IS NULL THEN
        SET NEW.status = 'FINALIZADA';
    END IF;
END $$

DELIMITER ;

UPDATE ordens_producao 
SET data_conclusao = NOW() 
WHERE id_produto = 5 AND status = 'EM PRODUÇÃO' LIMIT 1;

SELECT * FROM ordens_producao WHERE id_produto = 5;