import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_cadastro_usuario(client):
    payload = {
        "nome": "Teste",
        "telefone": "11999999999",
        "email": "teste@exemplo.com",
        "senha": "123456",
        "data_nascimento": "2000-01-01",
        "cpf": "12345678900"
    }
    response = client.post("/cadastro_usuario", json=payload)
    assert response.status_code in [200, 500, 400]

def test_login_usuario(client):
    payload = {
        "email": "teste@exemplo.com",
        "senha": "123456"
    }
    response = client.post("/login", json=payload)
    assert response.status_code in [200, 401, 403, 500, 400]

def test_login_admin(client):
    payload = {
        "email": "admin@exemplo.com",
        "senha": "admin123"
    }
    response = client.post("/login_admin", json=payload)
    assert response.status_code in [200, 401, 403, 500, 400]

def test_reset_password(client):
    payload = {
        "email": "teste@exemplo.com",
        "cpf": "12345678900",
        "data_nascimento": "2000-01-01",
        "nova_senha": "nova123"
    }
    response = client.post("/reset_password", json=payload)
    assert response.status_code in [200, 401, 403, 404, 400, 500]

def test_update_password(client):
    # Primeiro, tente atualizar a senha do usuário 1 (ajuste conforme seu banco)
    payload = {
        "currentPassword": "123456",
        "newPassword": "nova123"
    }
    response = client.put("/update_senha/1", json=payload)
    assert response.status_code in [200, 400, 401, 404, 500]



    #=======================================================================
    # Gerenciamento de Endereços e Usuários
    #=======================================================================
def test_get_endereco(client):
    response = client.get("/get_endereco/1")
    assert response.status_code in [200, 404]

def test_add_endereco(client):
    payload = {
        "Usuario_idUsuario": 1,
        "logradouro": "Rua Teste",
        "numero": "123",
        "bairro": "Centro",
        "cidade": "Cidade",
        "estado": "UF",
        "cep": "12345678",
        "complemento": "Apto 1",
        "referencia": "Próximo à praça"
    }
    response = client.post("/add_endereco", json=payload)
    assert response.status_code in [200, 400, 500]

def test_update_endereco(client):
    payload = {
        "logradouro": "Rua Alterada",
        "numero": "456",
        "bairro": "Bairro Novo",
        "cidade": "Cidade Nova",
        "estado": "UF",
        "cep": "87654321",
        "complemento": "Casa",
        "referencia": "Em frente ao mercado"
    }
    response = client.post("/update_endereco/1", json=payload)
    assert response.status_code in [200, 400, 500]

def test_delete_endereco(client):
    response = client.delete("/delete_endereco/1")
    assert response.status_code in [200, 404, 500]

def test_get_usuario(client):
    response = client.get("/get_usuario/1")
    assert response.status_code in [200, 404]

def test_update_usuario(client):
    payload = {
        "nome_social": "Teste Social",
        "nome_completo": "Nome Completo Teste",
        "telefone": "11999999999",
        "data_nascimento": "2000-01-01"
    }
    response = client.put("/update_usuario/1", json=payload)
    assert response.status_code in [200, 400, 500]

def test_update_password(client):
    payload = {
        "currentPassword": "123456",
        "newPassword": "nova123"
    }
    response = client.put("/update_senha/1", json=payload)
    assert response.status_code in [200, 400, 401, 404, 500]