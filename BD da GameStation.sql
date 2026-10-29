-- =========================================================================
-- PROVA DO DIA 22/10/26 : TRANSFORMAÇÃO DO MODELO CONCEITUAL (DER) 
-- Contexto: Módulo de Controle de Clientes e Sessões de LAN House
-- =========================================================================

-- Remove o banco de dados se ele já existir para evitar erros
DROP DATABASE IF EXISTS LanHouseDB;

-- Criação do banco de dados 
CREATE DATABASE LanHouseDB;
USE LanHouseDB;

-- =========================================================================
-- 1. TABELA CLIENTE (Entidade Forte)
-- CONCEITO: 
-- * No DER em papel, o Cliente tinha o CPF como identificador (Chave Natural).
-- * DECISÃO DE PROJETO: Adotamos um 'idCliente' artificial (Surrogate Key) do tipo INT UNSIGNED. 
-- * POR QUE 'UNSIGNED'? Removemos os números negativos, dobrando o limite 
--   de clientes que o sistema pode cadastrar (de 2 bilhões para 4 bilhões).
-- =========================================================================
-- SOBRE 1ª FORMA NORMAL (1FN - ATOMICIDADE):
-- 
-- CONCEITO INICIAL REPRESENTADO NO MODELO DE ENTIDADE E RELACIONAMENTO:
-- O Cliente possui Atributo Composto (Endereço) e Atributo Multivalorado (E-mail).
--
-- APLICAÇÃO DA 1ª FORMA NORMAL (1FN - ATOMICIDADE):
-- 1. Atributo Composto (Endereço): Foi DESMEMBRADO em suas partes simples e
--    atômicas: logradouro, numero, bairro, cidade, uf e cep.
-- 2. Atributo Multivalorado (E-mail): Um cliente pode ter N e-mails. Para não
--    violar a 1FN (evitando criar colunas email1, email2 ou colocar múltiplos 
--    e-mails na mesma célula separados por vírgula), o e-mail FOI REMOVIDO 
--    desta tabela e virou uma nova tabela relacionada ('ClienteEmail').

CREATE TABLE Cliente (
  -- idCliente: Chave Primária (PK). Identifica unicamente cada cliente de forma segura.
  idCliente INT UNSIGNED NOT NULL PRIMARY KEY,

  -- nome: Atributo simples/atômico obrigatório (NOT NULL).
  nome VARCHAR(125) NOT NULL, 
  CPF VARCHAR(11) NOT NULL UNIQUE,

  -- ATRIBUTO COMPOSTO (ENDEREÇO) DESMEMBRADO (1FN):
  -- Todos os campos são atômicos e indivisíveis.
  numero VARCHAR(10) NOT NULL,
  bairro VARCHAR(60) NOT NULL,
  cidade VARCHAR(60) NOT NULL,
  uf CHAR(2) NOT NULL,
  cep CHAR(8) NOT NULL
);
-- =========================================================================
-- 1.1 TABELA CLIENTE_EMAIL (Solução da 1FN para Atributo Multivalorado)
-- CONCEITO:
-- Como um Cliente pode ter zero, um ou múltiplos e-mails, criamos esta
-- tabela associada. A chave primária é COMPOSTA (idCliente + email) para 
-- evitar que o mesmo e-mail seja cadastrado duas vezes para o mesmo cliente.
-- =========================================================================
CREATE TABLE ClienteEmail (
  idCliente INT UNSIGNED NOT NULL,
  email VARCHAR(100) NOT NULL,
  -- Chave Primária Composta
  PRIMARY KEY (idCliente, email),
  -- Chave Estrangeira com Integridade Referencial
  CONSTRAINT fk_cliente_email
    FOREIGN KEY (idCliente)
    REFERENCES Cliente(idCliente)
);
-- =========================================================================
-- 2. TABELA SESSAO (O Lado "N" do Relacionamento 1:N com Cliente)
-- CONCEITO DE MAPEAMENTO (REGRA DE OURO):
-- - No relacionamento 1:N ("Um cliente realiza muitas sessões de uso"), a chave 
--   primária da entidade "1" (Cliente) "viaja" para a entidade "N" (Sessao) 
--   transformando-se em uma Chave Estrangeira (Foreign Key).
-- =========================================================================
CREATE TABLE Sessao (

  -- idSessao: Identificador único de cada sessão/tempo de uso contratado
  idSessao INT UNSIGNED NOT NULL PRIMARY KEY,

  -- dataSessao: Armazena o momento em que a sessão foi aberta.
  dataSessao DATE NOT NULL,

  -- tempoMinutos: Quantidade de minutos que o cliente adquiriu para jogar/navegar.
  tempoMinutos INT UNSIGNED NOT NULL,

  -- idCliente (FK): A "ponte" que liga a sessão ao seu respectivo cliente.
  -- Precisa ter EXATAMENTE o mesmo tipo de dado da origem (INT UNSIGNED).
  idCliente INT UNSIGNED NOT NULL,

  -- CONSTRAINT (Restrição de Integridade Referencial):
  -- Garante que nenhuma sessão seja cadastrada no sistema para um "fantasma" 
  -- (ou seja, o idCliente informado precisa existir obrigatoriamente na tabela Cliente).
  CONSTRAINT fk_cliente_sessao
    FOREIGN KEY (idCliente)
    REFERENCES Cliente(idCliente)
);

-- =========================================================================
-- 3. POVOANDO O BANCO DE DADOS (INSERÇÃO DE DADOS - DML)
-- =========================================================================

-- CONCEITO DE ORDEM DE INSERÇÃO:
-- Como a tabela 'Sessao' depende da tabela 'Cliente' (devido à Chave Estrangeira),
-- DEVEMOS primeiro cadastrar os Clientes. Tentar cadastrar uma Sessão para um 
-- Cliente que ainda não existe resultará em erro de integridade referencial!

-- Cadastrando os Clientes na tabela Cliente (com todos os campos obrigatórios):
INSERT INTO Cliente (idCliente, nome, CPF, logradouro, numero, bairro, cidade, uf, cep) VALUES 
(1, 'Carlos Eduardo Silva', '11122233344', 'Rua das Flores', '123', 'Centro', 'São Paulo', 'SP', '01001000'),
(2, 'Maria Fernanda Oliveira', '22233344455', 'Av. Paulista', '1500', 'Bela Vista', 'São Paulo', 'SP', '01310100'),
(3, 'João Pedro Santos', '33344455566', 'Rua da Paz', '45', 'Liberdade', 'São Paulo', 'SP', '01503000');

-- Cadastrando os E-mails (Aplicando a 1FN):
INSERT INTO ClienteEmail (idCliente, email) VALUES 
(1, 'carlos@email.com'),
(1, 'carlos.gamer@email.com'),
(2, 'maria.f@email.com');

-- Cadastrando as Sessões na tabela Sessao (Substituindo o antigo "Pedido"):
INSERT INTO Sessao (idSessao, dataSessao, tempoMinutos, idCliente) VALUES 
(101, '2026-03-01', 120, 1), -- Sessão 101 feita pelo Carlos (idCliente = 1) - 120 minutos
(102, '2026-03-02', 60, 1),  -- Sessão 102 também feita pelo Carlos - 60 minutos (demonstrando a relação 1:N)
(103, '2026-03-05', 180, 2); -- Sessão 103 feita pela Maria Fernanda (idCliente = 2) - 180 minutos

-- NOTA SOBRE O CLIENTE 3 (João Pedro):
-- O cliente João Pedro foi cadastrado, mas ainda não realizou nenhuma sessão.
-- Isso nos ajudará a entender a diferença nos tipos de consulta (JOINs).

-- =========================================================================
-- TESTE DE SEGURANÇA / INTEGRIDADE REFERENCIAL (DESAFIO PARA OS ALUNOS)
-- =========================================================================
-- O comando abaixo está COMENTADO porque, se for executado, GERARÁ UM ERRO!
-- Motivo: O idCliente 99 não existe na tabela Cliente. A CONSTRAINT 'fk_cliente_sessao'
-- impede que o sistema aceite sessões abertas por "clientes fantasmas".
-- INSERT INTO Sessao (idSessao, dataSessao, tempoMinutos, idCliente) 
-- VALUES (104, '2026-03-10', 90, 99); 
-- Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails...


-- =========================================================================
-- 4. CONSULTANDO OS DADOS (SELECT & JOINs)
-- =========================================================================

-- -------------------------------------------------------------------------
-- CONSULTA 1: Listar todos os clientes cadastrados
-- -------------------------------------------------------------------------
SELECT * FROM Cliente;

SELECT idCliente, nome FROM Cliente;

SELECT idCliente AS 'Codigo do Cliente', nome AS 'Nome' FROM Cliente;


-- -------------------------------------------------------------------------
-- CONSULTA 2: Listar todas as sessões cadastradas
-- -------------------------------------------------------------------------
SELECT * FROM Sessao;


-- -------------------------------------------------------------------------
-- CONSULTA 3: Cruzamento de Dados (INNER JOIN)
-- Exibe apenas as sessões que possuem um cliente associado 
-- e apenas os clientes que abriram sessões na LAN house.
-- -------------------------------------------------------------------------
SELECT 
    s.idSessao AS 'Código da Sessão',
    s.dataSessao AS 'Data do Uso',
    s.tempoMinutos AS 'Minutos Contratados',
    c.nome AS 'Nome do Cliente'
FROM Sessao s
INNER JOIN Cliente c ON s.idCliente = c.idCliente;

-- EXPLICAÇÃO DO INNER JOIN:
-- 1. 'Sessao s' e 'Cliente c': Usamos "apelidos" (aliases) para facilitar a leitura.
-- 2. 'ON s.idCliente = c.idCliente': É a "ponte". Diz ao banco para ligar a FK da 
--    tabela Sessao com a PK da tabela Cliente.


-- -------------------------------------------------------------------------
-- CONSULTA 4: Cruzamento Completo (LEFT JOIN)
-- Exibe TODOS os clientes, inclusive aqueles que NUNCA usaram as máquinas.
-- -------------------------------------------------------------------------
SELECT 
    c.idCliente AS 'ID Cliente',
    c.nome AS 'Nome do Cliente',
    s.idSessao AS 'Código da Sessão',
    s.tempoMinutos AS 'Minutos'
FROM Cliente c
LEFT JOIN Sessao s ON c.idCliente = s.idCliente;

-- EXPLICAÇÃO DO LEFT JOIN:
-- A tabela da esquerda (Cliente) é a principal. Todos os seus registros aparecem.
-- Como o cliente 'João Pedro Santos' não utilizou os PCs, as colunas da sessão
-- para ele serão preenchidas como 'NULL' (Vazio/Ausente).
