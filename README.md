Cafeteria APP

# Cafeteria App

Projeto full-stack com backend em Flask (API) e frontend em Flutter (app multiplataforma).

Estrutura principal
- API/ — backend Flask
  - [API/app.py](API/app.py) (rotas principais: [`login`](API/app.py), [`login_admin`](API/app.py), [`criar_pedido`](API/app.py), [`validar_cupom`](API/app.py), [`add_carrinho`](API/app.py), [`add_product`](API/app.py), [`listar_pedidos_usuario`](API/app.py), etc.)
  - [API/db.py](API/db.py) (função [`get_connection`](API/db.py) para conectar ao MySQL)
  - [API/.env](API/.env) (variáveis de ambiente do banco)
- cafeteria/ — app Flutter
  - [cafeteria/lib/main.dart](cafeteria/lib/main.dart) (entrypoint do app)
  - [cafeteria/pubspec.yaml](cafeteria/pubspec.yaml)
  - Screens e serviços importantes:
    - [cafeteria/lib/services/auth_service.dart](cafeteria/lib/services/auth_service.dart) (configura baseUrl da API)
    - [cafeteria/lib/screens/home/home_screen.dart](cafeteria/lib/screens/home/home_screen.dart)
    - [cafeteria/lib/screens/order/order_screen.dart](cafeteria/lib/screens/order/order_screen.dart)
    - [cafeteria/lib/screens/admin/...](cafeteria/lib/screens/admin) (áreas administrativas)
  - Global state: [cafeteria/lib/screens/global/global.dart](cafeteria/lib/screens/global/global.dart)
- Banco de dados - MySql/ — modelo e scripts
  - [Banco de dados - MySql/Modelo_Fisico.txt](Banco de dados - MySql/Modelo_Fisico.txt)

Pré-requisitos
- Python 3.8+ e pip
- MySQL
- Flutter SDK + ferramentas de plataforma (Android/iOS/web/linux/etc.)

Configuração rápida — backend (API)
1. Ajuste as variáveis em [API/.env](API/.env).
2. Criar virtualenv e instalar dependências:
   pip install flask flask-cors python-dotenv mysql-connector-python
3. Inicializar banco usando os scripts em [Banco de dados - MySql/Modelo_Fisico.txt](Banco de dados - MySql/Modelo_Fisico.txt) (ou seu dump).
4. Rodar API:
   python API/app.py
   - A API roda por padrão em 0.0.0.0:5000 (veja final de [API/app.py](API/app.py)).

Endpoints úteis (exemplos)
- POST /login → função [`login`](API/app.py)
- POST /login_admin → função [`login_admin`](API/app.py)
- POST /criar_pedido → função [`criar_pedido`](API/app.py)
- POST /cupons → função [`add_cupom`](API/app.py)
- POST /validar_cupom → função [`validar_cupom`](API/app.py)
- GET /listar_pedidos/<usuario_id> → função [`listar_pedidos_usuario`](API/app.py)

Configuração rápida — frontend (Flutter)
1. Abra a pasta `cafeteria/`.
2. Ajuste o endereço da API em [cafeteria/lib/services/auth_service.dart](cafeteria/lib/services/auth_service.dart) e, se necessário, nos arquivos que referenciam `baseUrl` (ex.: telas de pagamento, pedidos, home).
3. Instale dependências:
   flutter pub get
4. Rodar app:
   - Mobile/emulador: flutter run
   - Web: flutter run -d chrome
   - Linux/Desktop: flutter run -d linux

Observações importantes
- O frontend usa um IP fixo em vários arquivos — ajuste para o IP da máquina que roda a API ou use um nome DNS local. Verifique [cafeteria/lib/services/auth_service.dart](cafeteria/lib/services/auth_service.dart) e referências a `$baseUrl`.
- A função de conexão com o banco está em [`get_connection`](API/db.py). Garanta que as credenciais em [API/.env](API/.env) estejam corretas.
- Scripts SQL e modelo de tabelas estão em [Banco de dados - MySql/Modelo_Fisico.txt](Banco de dados - MySql/Modelo_Fisico.txt).

Arquivos úteis para desenvolver / debugar
- Backend: [API/app.py](API/app.py), [API/db.py](API/db.py)
- Frontend: [cafeteria/lib/main.dart](cafeteria/lib/main.dart), [cafeteria/lib/services/auth_service.dart](cafeteria/lib/services/auth_service.dart), [cafeteria/lib/screens/home/home_screen.dart](cafeteria/lib/screens/home/home_screen.dart), [cafeteria/lib/screens/order/order_screen.dart](cafeteria/lib/screens/order/order_screen.dart)

Contribuição
- Seguir estilo existente no projeto.
- Testar endpoints via Postman/curl e aplicativo em dispositivos na mesma rede.

Licença
- MIT — ver arquivo [LICENSE](LICENSE).
