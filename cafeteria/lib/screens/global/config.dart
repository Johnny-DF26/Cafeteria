import 'package:flutter/material.dart';

class GlobalConfig {
  // true = online, false = local
  static bool useOnline = true;

  // Retorna a URL da API com base na configuração
  static String api() {
    return useOnline
        ? "https://cafeteria-production-7f52.up.railway.app" // Online
        : "http://192.168.0.167:5000"; // Local
  }

  // Retorna a string de conexão com o banco, se precisar direto no Flutter
  static String dbConnection() {
    return useOnline
        ? "usuario_online:senha@host_online/db_online"
        : "usuario_local:senha@127.0.0.1/db_local";
  }
}



