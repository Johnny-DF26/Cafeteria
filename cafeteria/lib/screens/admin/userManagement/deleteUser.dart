import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteUserScreen extends StatefulWidget {
  final int userId; // ID do usuário que será excluído

  const DeleteUserScreen({super.key, required this.userId});

  @override
  State<DeleteUserScreen> createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  bool _loading = false;

  void _deleteUser() async {
    setState(() => _loading = true);

    final url = Uri.parse('http://192.168.0.167:5000/usuario');

    try {
      final response = await http.delete(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário excluído com sucesso!')),
        );
        Navigator.pop(context, true); // retorna true para indicar sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excluir Usuário'), backgroundColor: Colors.brown),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tem certeza que deseja excluir este usuário?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _deleteUser,
                          child: const Text('Excluir'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
