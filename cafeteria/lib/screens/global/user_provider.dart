import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;

  // GETTER do usuário
  Map<String, dynamic>? get userData => _userData;

  // SETTER do usuário
  void setUser(Map<String, dynamic> user) {
    _userData = user;
    notifyListeners();
  }

  // ⚡ ATUALIZADO: Busca dados atualizados do servidor
  Future<void> fetchUserData() async {
    if (_userData == null || _userData!['id'] == null) {
      notifyListeners();
      return;
    }

    try {
      final userId = _userData!['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/get_usuario/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Atualiza os dados do usuário mantendo o ID
        _userData = {
          'id': data['idUsuario'],
          'nome': data['nome_completo'],
          'nome_completo': data['nome_completo'],
          'nome_social': data['nome_social'],
          'email': data['email'],
          'cpf': data['cpf'],
          'telefone': data['telefone'],
          'data_nascimento': data['data_nascimento'],
          'status': data['ativo'],
        };
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do usuário: $e');
      notifyListeners();
    }
  }

  // Limpa usuário
  void clearUser() {
    _userData = null;
    _addresses = [];
    notifyListeners();
  }

  // ------------------------
  // Nova parte: lista de endereços
  // ------------------------

  List<Map<String, dynamic>> _addresses = [];

  // GETTER da lista de endereços
  List<Map<String, dynamic>> get addresses => _addresses;

  // SETTER da lista de endereços
  set addresses(List<Map<String, dynamic>> value) {
    _addresses = value;
    notifyListeners();
  }

  // Adiciona endereço localmente
  void addAddress(Map<String, dynamic> address) {
    _addresses.add(address);
    notifyListeners();
  }

  // Atualiza endereço localmente
  void updateAddress(int index, Map<String, dynamic> address) {
    _addresses[index] = address;
    notifyListeners();
  }

  // Remove endereço localmente
  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }
}
