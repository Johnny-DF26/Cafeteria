import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/routes.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _birthCtrl = TextEditingController(); 
  final _cpfCtrl = TextEditingController(); 

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _birthCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final url = Uri.parse('$baseUrl/cadastro_usuario');
    print('entrou aqui!'); // IP do PC na rede
    final body = jsonEncode({
      'nome': _nameCtrl.text.trim(),
      'telefone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'senha': _passCtrl.text.trim(),
      'data_nascimento': _birthCtrl.text.trim(),
      'cpf': _cpfCtrl.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!')),
        );
        Navigator.pushReplacementNamed(context, Routes.choose);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    print('Entrou aqui');

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Preencha os dados para criar sua conta',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Nome completo
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha seu nome';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Telefone
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha seu telefone';
                          if (!RegExp(r'^\d{10,11}$')
                              .hasMatch(v.replaceAll(RegExp(r'\D'), ''))) {
                            return 'Telefone inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Data de nascimento
                      TextFormField(
                        controller: _birthCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento (AAAA-MM-DD)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha a data de nascimento';
                          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim())) return 'Formato inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // CPF
                      TextFormField(
                        controller: _cpfCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha o CPF';
                          if (!RegExp(r'^\d{11}$').hasMatch(v.trim())) return 'CPF inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha o email';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Senha
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Preencha a senha';
                          if (v.length < 6) return 'Senha mínima 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Confirmar senha
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon:
                                Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirme a senha';
                          if (v != _passCtrl.text) return 'Senhas não conferem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Botão criar conta
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Criar Conta',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
