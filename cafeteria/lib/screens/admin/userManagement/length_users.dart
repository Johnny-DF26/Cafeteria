import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://192.168.0.167:5000'; // seu IP + porta da API

  // Busca quantidade de usuários no banco
  static Future<int> fetchUserCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/usuarios/count'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['quantidade'] ?? 0; // espera { "quantidade": 42 }
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
