--1.

CREATE OR REPLACE PROCEDURE aplicar_desconto(p_id INT, p_percentual NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
v_preco_atual NUMERIC(10,2);
v_preco_novo NUMERIC(10,2);
BEGIN
SELECT preco INTO v_preco_atual FROM produtos WHERE id = p_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Produto ID=% não encontrado no sistema!', p_id;
END IF;

IF p_percentual < 1 OR p_percentual > 100 THEN
    RAISE EXCEPTION 'Operação cancelada. O percentual de desconto deve estar entre 1 e 100.';
END IF;

v_preco_novo := v_preco_atual - (v_preco_atual * (p_percentual / 100.0));

IF v_preco_novo < 1.00 THEN
    RAISE EXCEPTION 'Desconto excessivo! O preço final ficaria em R$ %, o que é menor que o limite de R$ 1,00.', v_preco_novo;
END IF;

UPDATE produtos
SET preco = v_preco_novo
WHERE id = p_id;

RAISE NOTICE 'Desconto aplicado com sucesso! Novo preço do produto ID=% é R$ %', p_id, v_preco_novo;

END;
$$;

--2.

CREATE OR REPLACE PROCEDURE cadastrar_agendamento(p_pet_id INT, p_servico_id INT, p_data_agendamento TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM pets WHERE id = p_pet_id) THEN
RAISE EXCEPTION 'Cadastro bloqueado: Pet ID=% não encontrado!', p_pet_id;
END IF;

IF NOT EXISTS (SELECT 1 FROM servicos WHERE id = p_servico_id) THEN
    RAISE EXCEPTION 'Cadastro bloqueado: Serviço ID=% não encontrado!', p_servico_id;
END IF;

IF p_data_agendamento < CURRENT_TIMESTAMP THEN
    RAISE EXCEPTION 'Operação cancelada: Não é possível realizar agendamentos com datas no passado.';
END IF;

INSERT INTO agendamentos (pet_id, servico_id, data_agendamento, status)
VALUES (p_pet_id, p_servico_id, p_data_agendamento, 'agendado');

RAISE NOTICE 'Novo agendamento criado com sucesso para o Pet ID=%.', p_pet_id;

END;
$$;

--3.

CREATE OR REPLACE PROCEDURE transferir_pet(p_pet_id INT, p_cliente_novo_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
v_cliente_atual INT;
BEGIN
SELECT cliente_id INTO v_cliente_atual
FROM pets
WHERE id = p_pet_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Transferência cancelada: Pet ID=% não encontrado no sistema!', p_pet_id;
END IF;

IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_cliente_novo_id) THEN
    RAISE EXCEPTION 'Transferência cancelada: Novo cliente ID=% não encontrado!', p_cliente_novo_id;
END IF;

IF v_cliente_atual = p_cliente_novo_id THEN
    RAISE EXCEPTION 'Erro lógico: O Pet ID=% já está registrado no nome do Cliente ID=%. Ação redundante.', p_pet_id, p_cliente_novo_id;
END IF;

UPDATE pets
SET cliente_id = p_cliente_novo_id
WHERE id = p_pet_id;

RAISE NOTICE 'Propriedade alterada! Pet ID=% transferido com sucesso para o Cliente ID=%.', p_pet_id, p_cliente_novo_id;

END;
$$;
