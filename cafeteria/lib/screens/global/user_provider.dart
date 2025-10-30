import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;

  // GETTER do usuário
  Map<String, dynamic>? get userData => _userData;

  // SETTER do usuário
  void setUser(Map<String, dynamic> user) {
    _userData = user;
    notifyListeners();
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
