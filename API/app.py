from flask import Flask, jsonify, request
from flask_cors import CORS
from db import get_connection  # sua função para conectar ao MySQL
from datetime import datetime
from mysql.connector import Error
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

#=====================================================================================================================================================================================
#                                                                  Acesso ao APP - Usuário/Administrador
#=====================================================================================================================================================================================
# ------------------------
# Cadastro de Usuário (próprio usuário)
# ------------------------
@app.route('/cadastro_usuario', methods=['POST'])
def criar_usuario():
    data = request.get_json()
    # Pegando os campos enviados pelo Flutter
    #nome_social = data.get('nome_social')
    nome_completo = data.get('nome')
    telefone = data.get('telefone')
    email = data.get('email')
    senha = data.get('senha')
    data_nascimento = data.get('data_nascimento')
    
    cpf = data.get('cpf')
    # Validando campos obrigatórios
    if not all([nome_completo, telefone, email, senha, data_nascimento, cpf]):
        return jsonify({'error': 'Todos os campos são obrigatórios'}), 400

    # Conectando ao banco
    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Não foi possível conectar ao banco de dados'}), 500

    cursor = conn.cursor()
    try:
        # Inserindo todos os campos obrigatórios
        cursor.execute(
            """INSERT INTO usuario
            (nome_social, nome_completo, email, senha, cpf, telefone, data_nascimento, data_cadastro, data_ultimo_acesso, ativo, Administrador_idAdministrador)
            VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW(), %s, %s)""",
            (None, nome_completo, email, senha, cpf, telefone, data_nascimento, 1, None)
        )


        conn.commit()
        return jsonify({'message': 'Usuário criado com sucesso!'}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ------------------------
# Login de Usuário
# ------------------------
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    senha = data.get('senha')

    if not email or not senha:
        return jsonify({'error': 'Email e senha são obrigatórios'}), 400

    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Erro ao conectar ao banco de dados'}), 500

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM usuario WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and user['senha'] == senha:
            # Atualiza o último login
            #cursor.execute("UPDATE cadastro_usuario SET ultimo_login = NOW() WHERE email = %s", (email,))
            conn.commit()

            return jsonify({
                'message': 'Login bem-sucedido:',
                'user': {
                    'idUsuario': user.get('idUsuario'),
                    'nome': user.get('nome_completo'),
                    'email': user.get('email'),
                    'telefone': user.get('telefone'),
                    'endereco': user.get('endereco'),
                    'dataNascimento': user.get('data_nascimento'),
                }
            }), 200

        return jsonify({'error': 'Email ou senha inválidos'}), 401

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ------------------------
# Login de Administrador
# ------------------------
@app.route('/login_admin', methods=['POST'])
def login_admin():
    data = request.get_json()
    email = data.get('email')
    senha = data.get('senha')

    if not email or not senha:
        return jsonify({'error': 'Email e senha são obrigatórios'}), 400

    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Erro ao conectar ao banco de dados'}), 500

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM administrador WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and user['senha'] == senha:
            conn.commit()
            return jsonify({
                'message': 'Login bem-sucedido',
                'user': {  # pode até renomear para 'admin' se quiser
                    'idAdministrador': user.get('idAdministrador'),
                    'nome': user.get('nome'),
                    'email': user.get('email'),
                }
            }), 200

        return jsonify({'error': 'Email ou senha inválidos'}), 401

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        cursor.close()
        conn.close()

#====================================================================================================================================================================================
#                                                                       Gerenciamento de Conta -- Usuário
#====================================================================================================================================================================================
#======================
#   Buscar Endereço
#======================
@app.route("/get_endereco/<int:idUsuario>", methods=["GET"])
def get_enderecos(idUsuario):
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    query = "SELECT * FROM endereco WHERE Usuario_idUsuario = %s"
    
    cur.execute(query, (idUsuario,))
    enderecos = cur.fetchall()

    cur.close()
    conn.close()

    return jsonify(enderecos), 200

#==============================
#      Adicionar Endereço
#==============================
@app.route("/add_endereco", methods=["POST"])
def add_endereco():
    data = request.json

    conn = get_connection()
    cur = conn.cursor()

    query = """
        INSERT INTO endereco
        (Usuario_idUsuario, logradouro, numero, bairro, cidade, estado, cep, complemento, referencia)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """

    values = (
        data["Usuario_idUsuario"],
        data.get("logradouro"),
        data.get("numero"),
        data.get("bairro"),
        data.get("cidade"),
        data.get("estado"),
        data.get("cep"),
        data.get("complemento"),
        data.get("referencia"),
    )

    cur.execute(query, values)
    conn.commit()

    cur.close()
    conn.close()

    return jsonify({"message": "Endereço adicionado com sucesso!"}), 200

#===========================
#    Atualizar Endereço
#===========================
@app.route("/update_endereco/<int:idEndereco>", methods=["POST"])
def update_endereco(idEndereco):
    data = request.json

    conn = get_connection()
    cursor = conn.cursor()

    query = """
        UPDATE endereco
        SET logradouro=%s, numero=%s, bairro=%s, cidade=%s, estado=%s,
            cep=%s, complemento=%s, referencia=%s
        WHERE idEndereco_usuario=%s
    """

    values = (
        data.get("logradouro"),
        data.get("numero"),
        data.get("bairro"),
        data.get("cidade"),
        data.get("estado"),
        data.get("cep"),
        data.get("complemento"),
        data.get("referencia"),
        idEndereco
    )

    cursor.execute(query, values)
    conn.commit()

    cursor.close()
    conn.close()

    return jsonify({"message": "Endereço atualizado com sucesso!"}), 200


#==========================
#   Deletar Endereço
#==========================
@app.route("/delete_endereco/<int:idEndereco>", methods=["DELETE"])
def delete_endereco(idEndereco):
    conn = get_connection()
    cur = conn.cursor()

    query = "DELETE FROM endereco WHERE idEndereco_usuario = %s"

    cur.execute(query, (idEndereco,))
    conn.commit()

    cur.close()
    conn.close()

    return jsonify({"message": "Endereço removido com sucesso!"}), 200



#======================
#   Buscar usuário
#======================
@app.route('/get_usuario/<int:id>', methods=['GET'])
def get_usuario(id):
    conn = get_connection()
    cur = conn.cursor()
    print(id)

    cur.execute("SELECT * FROM usuario WHERE idUsuario = %s", (id,))
    user = cur.fetchone()
    
    cur.close()
    conn.close()
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    keys = [
        'idUsuario', 'nome_social', 'nome_completo', 'email', 'senha',
        'cpf', 'telefone', 'data_nascimento', 'data_cadastro',
        'data_ultimo_acesso', 'ativo', 'Administrador_idAdministrador'
    ]
    return jsonify(dict(zip(keys, user)))

#=======================
#   Atualizar usuário
#=======================
@app.route('/update_usuario/<int:id>', methods=['PUT'])
def update_usuario(id):
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE usuario 
        SET nome_social=%s, nome_completo=%s, telefone=%s, data_nascimento=%s
        WHERE idUsuario=%s
    """, (data['nome_social'], data['nome_completo'],
          data['telefone'], data['data_nascimento'], id))
    
    # commit na conexão correta
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({'message': 'Usuário atualizado com sucesso!'})

#============================
# Atualizar Senha
#============================

@app.route('/update_senha/<int:user_id>', methods=['PUT'])
def update_password(user_id):
    data = request.get_json()
    
    # Pegar dados do request
    current_password = data.get('currentPassword')
    new_password = data.get('newPassword')

    # Validações básicas
    if not current_password or not new_password:
        return jsonify({
            'success': False,
            'message': 'Senha atual e nova senha são obrigatórias'
        }), 400

    if len(new_password) < 6:
        return jsonify({
            'success': False,
            'message': 'A nova senha deve ter pelo menos 6 caracteres'
        }), 400

    # Conectar ao banco de dados
    conn = get_connection()
    if conn is None:
        return jsonify({
            'success': False,
            'message': '⚠️ Não foi possível conectar ao banco de dados'
        }), 500

    cursor = conn.cursor(dictionary=True)
    try:
        # 1. Buscar o usuário no banco
        cursor.execute(
            "SELECT idUsuario, senha FROM usuario WHERE idUsuario = %s AND ativo = 1",
            (user_id,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({
                'success': False,
                'message': '❌ Usuário não encontrado'
            }), 404

        # 2. Verificar se a senha atual está correta
        if user['senha'] != current_password:
            return jsonify({
                'success': False,
                'message': '❌ Senha atual incorreta'
            }), 401

        # 3. Atualizar a senha no banco
        cursor.execute(
            """UPDATE usuario 
               SET senha = %s, data_ultimo_acesso = NOW() 
               WHERE idUsuario = %s""",
            (new_password, user_id)
        )
        conn.commit()

        # 4. Retornar sucesso
        return jsonify({
            'success': True,
            'message': '✅ Senha atualizada com sucesso'
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({
            'success': False,
            'message': f'❌ Erro ao atualizar senha: {str(e)}'
        }), 500
    finally:
        cursor.close()
        conn.close()


# ...existing code...

# Dicionário para controlar tentativas (em produção use Redis ou banco)
tentativas_reset = {}

# ...existing code...

@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.get_json()
    
    email = data.get('email')
    cpf = data.get('cpf')
    data_nascimento = data.get('data_nascimento')
    nova_senha = data.get('nova_senha')

    # Validações básicas
    if not all([email, cpf, data_nascimento, nova_senha]):
        return jsonify({'error': 'Email, CPF, data de nascimento e nova senha são obrigatórios'}), 400

    if len(nova_senha) < 6:
        return jsonify({'error': 'A senha deve ter pelo menos 6 caracteres'}), 400

    # Remove pontos e traços do CPF (garante apenas números)
    cpf_limpo = cpf.replace('.', '').replace('-', '')

    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Erro ao conectar ao banco de dados'}), 500

    cursor = conn.cursor(dictionary=True)
    
    try:
        # 1. Verifica se o usuário existe pelo email
        cursor.execute("""
            SELECT idUsuario, nome_completo, email, ativo, cpf, data_nascimento
            FROM usuario 
            WHERE email = %s
        """, (email,))
        
        usuario = cursor.fetchone()

        if not usuario:
            return jsonify({'error': 'Usuário não encontrado'}), 404

        # 2. Verifica se a conta já está bloqueada
        if usuario['ativo'] == 0:
            return jsonify({'error': 'Conta bloqueada por excesso de tentativas. Entre em contato com o suporte.'}), 403

        # 3. Inicializa contador de tentativas para este email
        if email not in tentativas_reset:
            tentativas_reset[email] = 0

        # 4. Remove máscara do CPF do banco também (para comparação)
        cpf_banco = usuario['cpf'].replace('.', '').replace('-', '')
        
        # Converte data do banco para string no formato YYYY-MM-DD
        data_banco = str(usuario['data_nascimento'])
        
        print(f"[DEBUG] CPF enviado: {cpf_limpo} | CPF banco: {cpf_banco}")
        print(f"[DEBUG] Data enviada: {data_nascimento} | Data banco: {data_banco}")
        print(f"[DEBUG] Tentativas atuais: {tentativas_reset.get(email, 0)}")

        # 5. Verifica se CPF e data de nascimento conferem
        if cpf_banco == cpf_limpo and data_banco == data_nascimento:
            # ✅ DADOS CORRETOS - Atualiza senha e reseta tentativas
            cursor.execute("""
                UPDATE usuario 
                SET senha = %s, data_ultimo_acesso = NOW()
                WHERE idUsuario = %s
            """, (nova_senha, usuario['idUsuario']))
            
            conn.commit()

            # Remove do controle de tentativas
            if email in tentativas_reset:
                del tentativas_reset[email]

            print(f"[SUCESSO] Senha alterada para {email}")

            return jsonify({
                'message': 'Senha alterada com sucesso!',
                'usuario': {
                    'nome': usuario['nome_completo'],
                    'email': usuario['email']
                }
            }), 200
        
        else:
            # ❌ DADOS INCORRETOS - Incrementa tentativas
            tentativas_reset[email] = tentativas_reset.get(email, 0) + 1
            tentativas_restantes = 5 - tentativas_reset[email]

            print(f"[TENTATIVA FALHA] Email: {email} | Tentativas: {tentativas_reset[email]} | Restantes: {tentativas_restantes}")

            # Se atingiu 5 tentativas, BLOQUEIA A CONTA
            if tentativas_reset[email] >= 5:
                cursor.execute("""
                    UPDATE usuario 
                    SET ativo = 0
                    WHERE email = %s
                """, (email,))
                conn.commit()
                
                print(f"[BLOQUEIO] ❌ Conta {email} BLOQUEADA! ativo=0")
                
                # Verifica se realmente bloqueou
                cursor.execute("SELECT ativo FROM usuario WHERE email = %s", (email,))
                check = cursor.fetchone()
                print(f"[VERIFICAÇÃO] Status ativo após bloqueio: {check['ativo']}")
                
                return jsonify({
                    'error': 'Conta bloqueada por excesso de tentativas inválidas. Entre em contato com o suporte.'
                }), 403

            # Ainda tem tentativas
            return jsonify({
                'error': f'Dados incorretos. Você tem {tentativas_restantes} tentativa(s) restante(s).'
            }), 401

    except Exception as e:
        conn.rollback()
        print(f"[ERRO CRÍTICO] {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Erro ao redefinir senha: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

# ...existing code...

# ------------------------
# Endpoint para verificar tentativas (DEBUG)
# ------------------------
@app.route('/debug_tentativas', methods=['GET'])
def debug_tentativas():
    return jsonify(tentativas_reset), 200

# ------------------------
# Endpoint para limpar tentativas de um email (DEBUG)
# ------------------------
@app.route('/limpar_tentativas/<email>', methods=['POST'])
def limpar_tentativas(email):
    if email in tentativas_reset:
        del tentativas_reset[email]
        return jsonify({'message': f'Tentativas de {email} limpas'}), 200
    return jsonify({'message': 'Email não tinha tentativas registradas'}), 200

# ...existing code...

# ===================================================================================================================================================================================
#                                                                   Gerenciamento de usuários -- Administrador
# ===================================================================================================================================================================================
# ------------------------
# Listar todos os usuários
# ------------------------
@app.route('/usuario', methods=['GET'])
def listar_usuarios():
    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Não foi possível conectar ao banco de dados'}), 500

    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT idUsuario, nome_completo, email, telefone, data_nascimento, cpf FROM usuario")
        users = cursor.fetchall()
        return jsonify(users), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ------------------------
# Editar um usuário existente
# ------------------------
@app.route('/usuario/<int:id>', methods=['PUT'])
def editar_usuario(id):
    print(id)
    data = request.get_json()
    nome_completo = data.get('nome')
    telefone = data.get('telefone')
    email = data.get('email')
    senha = data.get('senha')
    data_nascimento = data.get('data_nascimento')
    cpf = data.get('cpf')

    if not all([nome_completo, telefone, email, senha, data_nascimento, cpf]):
        return jsonify({'error': 'Todos os campos são obrigatórios'}), 400

    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Não foi possível conectar ao banco de dados'}), 500

    cursor = conn.cursor()
    try:
        cursor.execute("""
            UPDATE usuario SET
                nome_completo=%s,
                telefone=%s,
                email=%s,
                senha=%s,
                data_nascimento=%s,
                cpf=%s
            WHERE idUsuario=%s
        """, (nome_completo, telefone, email, senha, data_nascimento, cpf, id))
        conn.commit()
        return jsonify({'message': 'Usuário atualizado com sucesso!'}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ------------------------
# Excluir um usuário
# ------------------------
@app.route('/usuario/<int:id>', methods=['DELETE'])
def excluir_usuario(id):
    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Não foi possível conectar ao banco de dados'}), 500

    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM usuario WHERE idUsuario=%s", (id,))
        conn.commit()
        return jsonify({'message': 'Usuário excluído com sucesso!'}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ------------------------
# Adicionar um novo usuário
# ------------------------
@app.route('/adicionar_usuario/<int:admin_id>', methods=['POST'])
def adicionar_usuario(admin_id):
    data = request.get_json()

    nome_completo = data.get('nome')
    telefone = data.get('telefone')
    email = data.get('email')
    senha = data.get('senha')
    data_nascimento = data.get('data_nascimento')
    cpf = data.get('cpf')

    # Validando campos obrigatórios
    if not all([nome_completo, telefone, email, senha, data_nascimento, cpf]):
        return jsonify({'error': 'Todos os campos são obrigatórios'}), 400

    conn = get_connection()
    if conn is None:
        return jsonify({'error': 'Não foi possível conectar ao banco de dados'}), 500

    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO usuario
               (nome_social, nome_completo, email, senha, cpf, telefone, data_nascimento, data_cadastro, data_ultimo_acesso, ativo, Administrador_idAdministrador)
               VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW(), %s, %s)""",
            (None, nome_completo, email, senha, cpf, telefone, data_nascimento, 1, admin_id)
        )
        conn.commit()
        return jsonify({'message': 'Usuário adicionado com sucesso!'}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()


#--------------------------
# Buscar cliente pelo CPF
#--------------------------
@app.route('/cliente/<cpf>', methods=['GET'])
def buscar_cliente(cpf):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        query = "SELECT nome_completo, email, senha, cpf, telefone, data_nascimento, ativo FROM usuario WHERE cpf=%s"
        cursor.execute(query, (cpf,))
        cliente = cursor.fetchone()
        if cliente:
            return jsonify({'cliente': cliente}), 200
        else:
            return jsonify({'error': 'Cliente não encontrado'}), 404
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


#--------------------------
# Excluir cliente pelo CPF
#--------------------------
@app.route('/cliente/<cpf>', methods=['DELETE'])
def excluir_cliente(cpf):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Primeiro verifica se existe
        cursor.execute("SELECT cpf FROM usuario WHERE cpf=%s", (cpf,))
        if cursor.fetchone() is None:
            return jsonify({'error': 'Cliente não encontrado'}), 404

        # Deleta
        cursor.execute("DELETE FROM usuario WHERE cpf=%s", (cpf,))
        conn.commit()
        return jsonify({'message': 'Cliente excluído com sucesso'}), 200
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# -------------------------
# Contar total de usuários 
# -------------------------
@app.route('/usuarios/count', methods=['GET'])
def contar_usuarios():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM usuario")
    (quantidade,) = cursor.fetchone()
    cursor.close()
    conn.close()
    return jsonify({'quantidade': quantidade}), 200

# ====================================================================================================================================================================================
#                                                                       Gerenciamento de produtos -- Administrador
# ====================================================================================================================================================================================
# ---------------------------
# Adicionar um novo produto
# ---------------------------
@app.route('/add_products', methods=['POST'])
def add_product():
    data = request.get_json()
    print(data)

    nome = data.get('nome')
    descricao = data.get('descricao')
    valor = data.get('valor')
    imagem = data.get('imagem')
    quantidade_estoque = data.get('quantidade_estoque')
    categoria = data.get('categoria', 'geral')
    vitrine_id = data.get('vitrine_id', 1)
    #avaliacao = data.get('avaliacao', None)  # opcional
    #usuario_id = data.get('usuario_id', 1)
    administrador_id = data.get('administrador_id')
    data_cadastro = datetime.now()

    # Validação de campos obrigatórios
    if not all([nome, descricao, valor is not None, imagem, quantidade_estoque is not None]):
        return jsonify({'error': 'Campos obrigatórios faltando'}), 400

    conn = get_connection()
    cursor = conn.cursor()
    try:
        sql = """
            INSERT INTO produtos 
            (nome, descricao, valor, imagem, quantidade_estoque,
             data_cadastro, vitrine_idVitrine, administrador_idAdministrador, categoria)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (
            nome, descricao, valor, imagem, quantidade_estoque,
            data_cadastro, vitrine_id, administrador_id, categoria
        ))
        conn.commit()
        return jsonify({'message': 'Produto cadastrado com sucesso!'}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ------------------------
# Deletar um produto
# ------------------------
@app.route('/produtos/<int:id>', methods=['DELETE'])
def delete_produto(id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM produtos WHERE idProdutos = %s", (id,))
    conn.commit()
    return jsonify({"message": "Produto excluído"})

# ------------------------
# Visualizar um produto
# ------------------------
@app.route('/get_products', methods=['GET'])
def get_products():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT idProdutos, nome, descricao, valor, avaliacao, imagem, 
                   quantidade_estoque, categoria, data_cadastro
            FROM produtos
        """)
        produtos = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({'produtos': produtos}), 200

    except Exception as e:
        print("Erro ao buscar produtos:", e)
        return jsonify({'error': str(e)}), 500


# ------------------------
# Atualizar um produto
# ------------------------
@app.route('/produtos/<int:id>', methods=['PUT'])
def update_produto(id):
    data = request.get_json()

    # Pegando os campos do JSON, se não vierem, mantém None
    nome = data.get('nome')
    descricao = data.get('descricao')
    valor = data.get('valor')
    imagem = data.get('imagem')
    quantidade_estoque = data.get('quantidade_estoque')
    categoria = data.get('categoria')

    # Monta o UPDATE apenas com os campos que não são None
    campos = []
    valores = []

    if nome is not None:
        campos.append("nome=%s")
        valores.append(nome)
    if descricao is not None:
        campos.append("descricao=%s")
        valores.append(descricao)
    if valor is not None:
        campos.append("valor=%s")
        valores.append(valor)
    if imagem is not None:
        campos.append("imagem=%s")
        valores.append(imagem)
    if quantidade_estoque is not None:
        campos.append("quantidade_estoque=%s")
        valores.append(quantidade_estoque)
    if categoria is not None:
        campos.append("categoria=%s")
        valores.append(categoria)

    if not campos:
        return jsonify({"message": "Nenhum campo para atualizar"}), 400

    valores.append(id)  # para o WHERE

    try:
        conn = get_connection()
        cursor = conn.cursor()
        query = f"UPDATE produtos SET {', '.join(campos)} WHERE idProdutos=%s"
        cursor.execute(query, tuple(valores))
        conn.commit()

        linhas_afetadas = cursor.rowcount
        cursor.close()
        conn.close()

        if linhas_afetadas > 0:
            return jsonify({'message': 'Produto atualizado com sucesso!'}), 200
        else:
            return jsonify({'message': 'Produto não encontrado'}), 404
    except Error as e:
        return jsonify({'error': str(e)}), 500
# ===================================================================================================================================================================================
#                                                                    Gerenciamento de promoções - Administrador
# ===================================================================================================================================================================================
# ------------------------
# Listar produtos em promoção
# ------------------------
@app.route('/promocao', methods=['GET'])
def get_promocoes():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT 
            idProdutos,
            nome,
            descricao,
            categoria,
            valor,
            imagem,
            is_promotion
        FROM produtos
        WHERE is_promotion = 1
    """)
    promocoes = cursor.fetchall()
    conn.close()
    return jsonify(promocoes)

# ------------------------
# Adicionar produto à promoção
# ------------------------
@app.route('/promocao', methods=['POST'])
def add_promocao():
    data = request.get_json()
    id_produto = data.get('Produto_idProduto')
    preco_promocional = data.get('preco_promocional')

    if not id_produto or preco_promocional is None:
        return jsonify({'error': 'Produto_idProduto e preco_promocional são obrigatórios'}), 400

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE produtos
        SET is_promotion = 1, valor = %s
        WHERE idProdutos = %s
    """, (preco_promocional, id_produto))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Produto adicionado à promoção com sucesso'}), 201

# ------------------------
# Atualizar produto em promoção
# ------------------------
@app.route('/promocao/<int:id>', methods=['PUT'])
def update_promocao(id):
    data = request.get_json()
    preco_promocional = data.get('preco_promocional')
    if preco_promocional is None:
        return jsonify({'error': 'preco_promocional é obrigatório'}), 400

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE produtos
        SET valor = %s
        WHERE idProdutos = %s AND is_promotion = 1
    """, (preco_promocional, id))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Produto em promoção atualizado'})

# ------------------------
# Remover produto da promoção
# ------------------------
@app.route('/promocao/<int:id>', methods=['DELETE'])
def remove_promocao(id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE produtos
        SET is_promotion = 0
        WHERE idProdutos = %s
    """, (id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Produto removido da promoção'})

# ===================================================================================================================================================================================
#                                                                     Gerenciamento de cupons -- Administrador
# ===================================================================================================================================================================================
# ------------------------
# Listar cupons
# ------------------------
@app.route('/cupons', methods=['GET'])
def get_cupons():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT 
            idCupom,
            codigo,
            descricao,
            desconto,
            tipo_desconto,
            data_validade,
            ativo,
            Administrador_idAdministrador,
            data_criacao
        FROM cupom
    """)
    cupons = cursor.fetchall()
    conn.close()
    return jsonify({'cupons': cupons})

# ------------------------
# Adicionar cupom
# ------------------------
@app.route('/cupons', methods=['POST'])
def add_cupom():
    data = request.get_json()
    codigo = data.get('codigo')
    descricao = data.get('descricao', '')
    desconto = data.get('desconto')
    tipo_desconto = data.get('tipo_desconto', 'percentual')
    data_validade = data.get('data_validade')
    ativo = data.get('ativo', 1)
    admin_id = data.get('Administrador_idAdministrador')

    if not codigo or desconto is None or not data_validade or not admin_id:
        return jsonify({'error': 'codigo, desconto, data_validade e Administrador_idAdministrador são obrigatórios'}), 400

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO cupom (codigo, descricao, desconto, tipo_desconto, data_validade, ativo, Administrador_idAdministrador)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (codigo, descricao, desconto, tipo_desconto, data_validade, ativo, admin_id))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Cupom adicionado com sucesso'}), 201

# ------------------------
# Atualizar cupom
# ------------------------
@app.route('/cupons/<int:id>', methods=['PUT'])
def update_cupom(id):
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Nenhum dado recebido'}), 400

    fields = []
    values = []

    # Aceita qualquer campo que exista no JSON
    for key in ['codigo', 'descricao', 'desconto', 'tipo_desconto', 'data_validade', 'ativo']:
        if key in data:
            fields.append(f"{key}=%s")
            values.append(data[key])

    if not fields:
        return jsonify({'error': 'Nenhum campo válido para atualizar'}), 400

    values.append(id)
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(f"UPDATE cupom SET {', '.join(fields)} WHERE idCupom=%s", values)
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'Cupom atualizado com sucesso'})
    except Exception as e:
        print("Erro ao atualizar cupom:", e)
        return jsonify({'error': str(e)}), 500


# ------------------------
# Remover/Desativar cupom
# ------------------------
@app.route('/cupons/<int:id>', methods=['DELETE'])
def remove_cupom(id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM cupom WHERE idCupom=%s", (id,))
    
    if cursor.rowcount == 0:
        conn.close()
        return jsonify({'error': 'Cupom não encontrado'}), 404
    
    conn.commit()
    conn.close()
    return jsonify({'message': 'Cupom removido com sucesso'})

#===================================================================================================================================================================================
#                                                                               Vitrine de Produtos
#===================================================================================================================================================================================
# ===========================
# Buscar categorias únicas
# ===========================
@app.route('/categorias', methods=['GET'])
def get_categorias():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT DISTINCT categoria FROM produtos WHERE categoria IS NOT NULL AND categoria <> ''")
    categorias = cursor.fetchall()
    return jsonify(categorias)

# ------------------------
# Listar todos os produtos
# ------------------------
@app.route('/produtos', methods=['GET'])
def get_produtos():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM produtos")
        produtos = cursor.fetchall()
        return jsonify(produtos)
    except Error as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# ------------------------
# Listar produtos em promoção
# ------------------------

# ------------------------
# Listar produtos por categoria
# ------------------------
@app.route('/produtos/categoria/<string:categoria>', methods=['GET'])
def get_produtos_categoria(categoria):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM produtos WHERE categoria = %s", (categoria,))
        produtos = cursor.fetchall()
        return jsonify(produtos)
    except Error as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


#====================================================================================================================================================================================
#                                                                      Gerenciamento de Favoritos -- Usuário
#====================================================================================================================================================================================
# ===============================
# Listar favoritos de um usuário
# ===============================
@app.route('/favoritos/<int:user_id>', methods=['GET'])
def get_favoritos(user_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT f.idFavoritos, p.idProdutos, p.nome, p.descricao, p.valor,
                   p.imagem, p.avaliacao, p.categoria, p.is_promotion
            FROM favoritos f
            JOIN produtos p ON f.Produtos_idProdutos = p.idProdutos
            WHERE f.Usuario_idUsuario = %s
        """, (user_id,))
        favoritos = cursor.fetchall()
        return jsonify(favoritos), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


# ===============================
# Adicionar produto aos favoritos
# ===============================
@app.route('/favoritos', methods=['POST'])
def add_favorito():
    data = request.json
    user_id = data.get("Usuario_idUsuario")
    produto_id = data.get("Produtos_idProdutos")
    
    if not user_id or not produto_id:
        return jsonify({"error": "Usuario_idUsuario e Produtos_idProdutos são obrigatórios"}), 400

    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO favoritos (Usuario_idUsuario, data_criacao, Produtos_idProdutos) VALUES (%s, NOW(), %s)",
            (user_id, produto_id)
        )
        conn.commit()
        favorito_id = cursor.lastrowid
        return jsonify({"idFavoritos": favorito_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


# ===============================
# Remover produto dos favoritos
# ===============================
@app.route('/favoritos/<int:fav_id>', methods=['DELETE'])
def remove_favorito(fav_id):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM favoritos WHERE idFavoritos = %s", (fav_id,))
        conn.commit()
        return jsonify({"message": "Favorito removido"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


#======================================================================================================================================================================================
#                                                                      Carrinho de Compras -- Usuário
#======================================================================================================================================================================================
#--------------------------------
# Listar carrinho de um usuário
#--------------------------------
@app.route('/get_carrinho/<int:user_id>', methods=['GET'])
def get_carrinho(user_id):
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    
    # Seleciona produtos do carrinho junto com o ID do carrinho
    cur.execute("""
        SELECT cp.idCarrinho_Produtos AS id,
               cp.Carrinho_idCarrinho AS carrinho_id,
               p.idProdutos AS produto_id,
               p.nome,
               p.descricao,
               p.valor,
               p.imagem,
               cp.quantidade
        FROM carrinho_produto cp
        JOIN carrinho c ON cp.Carrinho_idCarrinho = c.idCarrinho
        JOIN produtos p ON cp.Produtos_idProdutos = p.idProdutos
        WHERE c.Usuario_idUsuario = %s
    """, (user_id,))
    
    items = cur.fetchall()
    cur.close()
    conn.close()
    
    return jsonify(items)


#--------------------------------
# Adicionar produto ao carrinho
@app.route("/add_carrinho", methods=["POST"])
def add_carrinho():
    data = request.json
    usuario_id = data["usuario_id"]
    produto_id = data["produto_id"]
    quantidade = data.get("quantidade", 1)

    conn = get_connection()
    cur = conn.cursor(buffered=True)  # ⚡ importante

    # 1️⃣ Verifica se existe carrinho aberto para o usuário
    cur.execute(
        "SELECT idCarrinho FROM carrinho WHERE Usuario_idUsuario=%s AND status='aberto'",
        (usuario_id,)
    )
    carrinho = cur.fetchone()

    if carrinho:
        carrinho_id = carrinho[0]
    else:
        # Cria novo carrinho sem coluna inexistente
        cur.execute(
            "INSERT INTO carrinho (data_criacao, Usuario_idUsuario, status) VALUES (NOW(), %s, 'aberto')",
            (usuario_id,)
        )
        conn.commit()
        carrinho_id = cur.lastrowid

    # 2️⃣ Verifica se o produto já está no carrinho
    cur.execute(
        "SELECT idCarrinho_Produtos, quantidade FROM carrinho_produto WHERE Carrinho_idCarrinho=%s AND Produtos_idProdutos=%s",
        (carrinho_id, produto_id)
    )
    produto_no_carrinho = cur.fetchone()

    if produto_no_carrinho:
        # Atualiza quantidade
        nova_quantidade = produto_no_carrinho[1] + quantidade
        cur.execute(
            "UPDATE carrinho_produto SET quantidade=%s, data_criacao=NOW() WHERE idCarrinho_Produtos=%s",
            (nova_quantidade, produto_no_carrinho[0])
        )
    else:
        # Insere produto novo no carrinho correto
        cur.execute(
            "INSERT INTO carrinho_produto (Carrinho_idCarrinho, Produtos_idProdutos, quantidade, data_criacao) VALUES (%s, %s, %s, NOW())",
            (carrinho_id, produto_id, quantidade)
        )

    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"status": "sucesso", "msg": "Produto adicionado ao carrinho"})

#----------------------------------------------
# Alterar quantidade do produto no carrinho
#----------------------------------------------
@app.route('/update_carrinho', methods=['POST'])
def update_carrinho():
    data = request.get_json()
    conn = get_connection()       # Conexão única
    cur = conn.cursor()           # Cursor dessa conexão

    cur.execute("""
        UPDATE carrinho_produto
        SET quantidade = %s, data_criacao=NOW()
        WHERE idCarrinho_Produtos = %s
    """, (data['quantidade'], data['idCarrinho_Produtos']))

    conn.commit()                 # Commit na mesma conexão
    cur.close()
    conn.close()                  # Fecha conexão
    return jsonify({"status": "ok"})

#--------------------------------
# Remover produto do carrinho
#--------------------------------
@app.route('/remove_unidade_carrinho/<int:cart_prod_id>', methods=['DELETE'])
def remove_carrinho(cart_prod_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM carrinho_produto WHERE idCarrinho_Produtos = %s", (cart_prod_id,))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"status": "sucesso"})

#-------------------------------------
# Remover todos os itens do carrinho
#-------------------------------------
@app.route('/remove_produto_carrinho', methods=['POST'])
def remove_produto_carrinho():
    data = request.get_json()
    carrinho_id = data.get('carrinho_id')   # o id do carrinho
    produto_id = data.get('produto_id')  # o id do produto

    conn = get_connection()
    cur = conn.cursor()

    # 1️⃣ Deleta o produto do carrinho
    cur.execute(
        "DELETE FROM carrinho_produto WHERE Carrinho_idCarrinho = %s AND Produtos_idProdutos = %s",
        (carrinho_id, produto_id)
    )

    # 2️⃣ Verifica se ainda existem produtos naquele carrinho
    cur.execute(
        "SELECT COUNT(*) FROM carrinho_produto WHERE Carrinho_idCarrinho = %s",
        (carrinho_id,)
    )
    count = cur.fetchone()[0]

    # 3️⃣ Se não houver produtos, deleta o carrinho
    if count == 0:
        cur.execute(
            "DELETE FROM carrinho WHERE idCarrinho = %s",
            (carrinho_id,)
        )

    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"status": "ok"})

#====================================================================================================================================================================================
#                                                                          Pagamento -- PaymentScreen
#===================================================================================================================================================================================
# ==========================
#  Carrinho
# ==========================
@app.route("/get_carrinho22/<int:usuario_id>", methods=["GET"])
def get_cart(usuario_id):
    conn = get_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
    cur.execute("""
        SELECT c.idCarrinho, p.idProduto, p.nome, p.descricao, p.valor, ci.quantidade
        FROM carrinho c
        JOIN carrinho_item ci ON c.idCarrinho = ci.Carrinho_idCarrinho
        JOIN produto p ON ci.Produto_idProduto = p.idProduto
        WHERE c.Usuario_idUsuario = %s
    """, (usuario_id,))
    items = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(items)

#--------------------------
#    Limpar Carrinho
#--------------------------
@app.route("/limpar_carrinho/<int:usuario_id>", methods=["POST"])
def limpar_carrinho(usuario_id):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM carrinho WHERE Usuario_idUsuario = %s", (usuario_id,))
    conn.commit()

    cur.close()
    conn.close()

    return {"status": "Carrinho limpo com sucesso"}

# ==========================
# Endereço de entrega 
# ==========================
@app.route("/endereco_usuario/<int:usuario_id>", methods=["GET"])
def endereco_usuario(usuario_id):
    conn = get_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
    cur.execute("SELECT * FROM endereco WHERE Usuario_idUsuario=%s", (usuario_id,))
    enderecos = cur.fetchall()  # <- pega todos
    cur.close()
    conn.close()

    if not enderecos:
        return jsonify([])  # lista vazia se não houver
    return jsonify(enderecos)  # retorna lista JSON


# ==========================
# 3. Cupom
# ==========================
@app.route("/validar_cupom", methods=["POST"])
def validar_cupom():
    data = request.json
    codigo = data.get("codigo")
    conn = get_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
    cur.execute("SELECT * FROM cupom WHERE codigo=%s AND ativo=1 AND data_validade>=CURDATE()", (codigo,))
    cupom = cur.fetchone()
    cur.close()
    conn.close()
    if not cupom:
        return jsonify({"erro": "Cupom inválido ou expirado"}), 400
    return jsonify(cupom)

# ==========================
# 4. Cartão de crédito
# ==========================
@app.route("/cartao", methods=["POST"])
def adicionar_cartao():
    data = request.json
    nome = data["nome"]
    numero = data["numero"]
    validade = data["validade"]
    cvv = data["cvv"]
    forma_pagamento_id = data.get("forma_pagamento_id")
    usuario_id = data.get("usuario_id")

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO cartao_credito (nome, numero, validade, cvv, Forma_pagamento_idForma_pagamento)
        VALUES (%s,%s,%s,%s,%s)
    """, (nome, numero, validade, cvv, forma_pagamento_id))
    conn.commit()
    card_id = cur.lastrowid
    cur.close()
    conn.close()
    return jsonify({"mensagem": "Cartão adicionado", "id": card_id})




# ==========================
# 5. Confirmar Pagamento
# ==========================
@app.route("/criar_pedido", methods=["POST"])
def criar_pedido():
    data = request.json
    print(data)
    usuario_id = data["usuario_id"]
    endereco = data.get("endereco") 
    valor_total = data["valor_total"]
    valor_frete = data.get("valor_frete", 0)
    valor_desconto = data.get("valor_desconto", 0)
    cupom_codigo = data.get("cupom_codigo")
    pagamento = data["pagamento"]

    observacao = data.get("observacao")
    status = "Realizado"

    conn = get_connection()
    cur = conn.cursor()
    print(endereco)
    # cria o pedido
    cur.execute("""
        INSERT INTO relatorio_pedido
        (Usuario_idUsuario, endereco, valor_total, valor_frete, valor_desconto, cupom_codigo, status, observacao, tipo_pagamento)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (usuario_id, endereco, valor_total, valor_frete, valor_desconto, cupom_codigo, status, observacao, pagamento))

    pedido_id = cur.lastrowid
    # agora salvamos cada item do pedido
    for item in data["items"]:
        cur.execute("""
            INSERT INTO relatorio_pedido_produto
            (Relatorio_Pedido_id, Produto_id, quantidade, preco_unitario)
            VALUES (%s,%s,%s,%s)
        """, (pedido_id, item["id"], item["quantity"], item["price"]))

    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"mensagem": "Pedido criado!", "pedido_id": pedido_id})

#===================================================================================================================================================================================
#                                                                              Histórico Pedido (OrderScreen)
#===================================================================================================================================================================================

@app.route("/listar_pedidos/<int:usuario_id>", methods=["GET"])
def listar_pedidos_usuario(usuario_id):
    conn = get_connection()
    cur = conn.cursor(dictionary=True)

    # pega pedidos
    cur.execute("""
        SELECT * FROM relatorio_pedido
        WHERE Usuario_idUsuario = %s
       
    """, (usuario_id,))
    pedidos = cur.fetchall()

    # pega itens de cada pedido
    for pedido in pedidos:
        cur.execute("""
            SELECT p.nome, rp.quantidade, rp.preco_unitario
            FROM relatorio_pedido_produto rp
            JOIN produtos p ON p.idProdutos = rp.Produto_id
            WHERE rp.Relatorio_Pedido_id = %s
        """, (pedido["idRelatorio_Pedido"],))
        pedido["items"] = cur.fetchall()

    cur.close()
    conn.close()
    return jsonify(pedidos)

#=================================================================================================================================================================================
# GET - Listar todos os relatórios de pedidos
@app.route('/relatorios_pedidos', methods=['GET'])
def listar_relatorios():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT 
            idRelatorio_Pedido,
            Usuario_idUsuario,
            endereco,
            valor_total,
            valor_frete,
            valor_desconto,
            status,
            data_status,
            observacao,
            tipo_pagamento
        FROM relatorio_pedido
        ORDER BY idRelatorio_Pedido DESC
    """)

    relatorios = cursor.fetchall()
    cursor.close()
    conn.close()

    return jsonify(relatorios), 200


# PUT - Atualizar status de um pedido
@app.route('/update_relatorios_pedidos/<int:id_relatorio>', methods=['PUT'])
def atualizar_status(id_relatorio):
    data = request.json
    novo_status = data.get("status")
    if not novo_status:
        return jsonify({"erro": "Campo 'status' é obrigatório"}), 400

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE relatorio_pedido
        SET status = %s
        WHERE idRelatorio_Pedido = %s""", 
        (novo_status, id_relatorio))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"mensagem": "Status atualizado com sucesso"}), 200


#=====================================================================================================================================================================================
#                                                                                    Rota IP 
#=====================================================================================================================================================================================
# ------------------------
# Rota Home
# ------------------------
if __name__ == '__main__':
    #app.run(host='0.0.0.0', port=8080, debug=True) # Online
    app.run(host='0.0.0.0', port=5000, debug=True) # Local
#-----------------------------
# Teste
#-----------------------------
@app.route("/teste_db")
def teste_db():
    return {"status": "ok"}

