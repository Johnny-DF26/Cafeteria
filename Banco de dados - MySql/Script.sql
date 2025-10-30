use cafeteria_app;
show tables;
select * from cadastro_usuario;
ALTER TABLE cadastro_usuario ADD COLUMN senha VARCHAR(255);

INSERT INTO Usuario (email, senha_hash, data_criacao) VALUES ('teste@teste.com', '123456', NOW());
INSERT INTO Administrador (idAdministrador) VALUES (1);
ALTER TABLE Cadastro_usuario MODIFY Administrador_idAdministrador INT NULL;

-- Visualizar colunas da Tabela
DESCRIBE usuario;

-- Visualizar coluna
select * from administrador;
select * from usuario;
select * from cadastro_usuario;

-- Adicionar Coluna
ALTER TABLE administrador ADD COLUMN senha VARCHAR(255);

-- Inserir dados na coluna
INSERT INTO administrador (nome, email, cargo, cpf, data_nascimento, data_acesso, ativo, senha) 
	VALUES ('paulo','teste3@gmail.com','adm','22222','1998-12-26','2025-10-20','1','123456');
    
-- Apagar coluna da tabela
ALTER TABLE usuario DROP COLUMN senha;

-- Alterar nomes:
ALTER TABLE administrador RENAME COLUMN data_acesso TO data_criacao;

