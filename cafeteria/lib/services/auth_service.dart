import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafeteria/core/routes.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  //final String baseUrl = 'http://192.168.0.167:5000'; // IP da sua API
  final String baseUrl = GlobalConfig.GlobalConfig.api();

// ---------------------------------------------------------------------------------------
// -------------------------
// LOGIN USUÁRIO
// -------------------------
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final body = jsonEncode({'email': email, 'senha': password});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode != 200){
      throw AuthException(data['error'] ?? 'Erro desconhecido');
    }

    return {
      'id': data['user']['idUsuario'],
      'nome': data['user']['nome'],
      'email': data['user']['email'],
      'status': data['user']['status'],
      'cpf': data['user']['cpf'],
      'telefone': data['user']['telefone'],
      'endereco': data['user']['endereco'],
      'dataNascimento': data['user']['dataNascimento'],
    };
  }


// --------------------------
// LOGIN ADMINISTRADOR
// -------------------------
  Future<Map<String, dynamic>> signInAdmin(String email, String password) async {
    final url = Uri.parse('$baseUrl/login_admin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': password}),
    );

    final data = jsonDecode(response.body);
    //print('API retornou: $data'); // útil para debug
    

    if (response.statusCode != 200) {
      throw AuthException(data['error'] ?? 'Falha no login do administrador');
    }

    return {
      'id': data['user']['idAdministrador'],
      'nome': data['user']['nome'],
      'email': data['user']['email'],
    };
  }
// ---------------------------------------------------------------------------------------


// -------------------------
// Resetar Senha Usuário
// -------------------------
  Future<void> sendPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/forgot_password');
    final body = jsonEncode({'email': email});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) return;
    final data = jsonDecode(response.body);
    throw AuthException(data['error'] ?? 'Erro ao enviar email de recuperação');
  }


// ------------------------------
// Resetar Senha Administrador
// ------------------------------
  Future<void> sendPasswordResetAdmin(String email) async {
    final url = Uri.parse('$baseUrl/forgot_password_admin');
    final body = jsonEncode({'email': email});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) return;
    final data = jsonDecode(response.body);
    throw AuthException(data['error'] ?? 'Erro ao enviar email de recuperação');
  }

/// Reset de senha com Email + CPF + Data de Nascimento
Future<void> resetPassword({
  required String email,
  required String cpf,
  required String birthDate,
  required String newPassword,
}) async {
  try {
    print('[DEBUG] Enviando: email=$email, cpf=$cpf, data=$birthDate');
    
    final response = await http.post(
      Uri.parse('$baseUrl/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'cpf': cpf,
        'data_nascimento': birthDate,
        'nova_senha': newPassword,
      }),
    );

    print('[DEBUG] Status: ${response.statusCode}');
    print('[DEBUG] Body: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403 || response.statusCode == 401 || response.statusCode == 404) {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'Erro ao redefinir senha');
    } else {
      final data = jsonDecode(response.body);
      throw AuthException(data['error'] ?? 'Erro ao redefinir senha');
    }
  } catch (e) {
    print('[ERRO] $e');
    if (e is AuthException) rethrow;
    throw AuthException('Erro de conexão: $e');
  }
}
}