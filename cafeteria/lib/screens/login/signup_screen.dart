import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/routes.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

  // Função para converter dd/MM/yyyy para yyyy-MM-dd
  String? _convertDateToMySQL(String dateStr) {
    try {
      // Remove espaços extras
      dateStr = dateStr.trim();
      
      // Tenta fazer o parse no formato brasileiro
      final DateFormat brFormat = DateFormat('dd/MM/yyyy');
      final DateTime date = brFormat.parseStrict(dateStr);
      
      // Converte para formato MySQL
      final DateFormat mysqlFormat = DateFormat('yyyy-MM-dd');
      return mysqlFormat.format(date);
    } catch (e) {
      return null;
    }
  }

  // Função para remover formatação
  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\D'), '');
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final url = Uri.parse('$baseUrl/cadastro_usuario');
    
    // Converte a data para o formato MySQL
    final String? dataNascimentoMySQL = _convertDateToMySQL(_birthCtrl.text);
    
    if (dataNascimentoMySQL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Data de nascimento inválida')),
      );
      setState(() => _loading = false);
      return;
    }
    
    final body = jsonEncode({
      'nome': _nameCtrl.text.trim(),
      'telefone': _cleanText(_phoneCtrl.text), // Remove a formatação
      'email': _emailCtrl.text.trim(),
      'senha': _passCtrl.text.trim(),
      'data_nascimento': dataNascimentoMySQL, // Formato MySQL
      'cpf': _cleanText(_cpfCtrl.text), // Remove a formatação
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Conta criada com sucesso!')),
        );
        Navigator.pushReplacementNamed(context, Routes.choose);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ E-mail já cadastrado!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro de conexão: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
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
                          hintText: '(XX) XXXXX-XXXX',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _PhoneInputFormatter(),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha seu telefone';
                          final cleanPhone = _cleanText(v);
                          if (!RegExp(r'^\d{10,11}$').hasMatch(cleanPhone)) {
                            return '❌ Telefone inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Data de nascimento
                      TextFormField(
                        controller: _birthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento',
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'dd/mm/aaaa',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _DateInputFormatter(),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Preencha a data de nascimento';
                          }
                          
                          // Valida formato
                          if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(v)) {
                            return 'Use o formato dd/mm/aaaa';
                          }
                          
                          // Valida se é uma data válida
                          if (_convertDateToMySQL(v) == null) {
                            return '❌ Data inválida';
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // CPF - MODIFICADO COM MÁSCARA
                      TextFormField(
                        controller: _cpfCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: 'XXX.XXX.XXX-XX',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CpfInputFormatter(), // Formatter customizado para CPF
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Preencha o CPF';
                          final cleanCpf = _cleanText(v);
                          if (!RegExp(r'^\d{11}$').hasMatch(cleanCpf)) {
                            return '❌ CPF inválido';
                          }
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
                          if (!v.contains('@')) return '❌ Email inválido';
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
                          if (v != _passCtrl.text) return '❌ Senhas não conferem';
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

// Formatter para telefone (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length > 11) {
      return oldValue;
    }

    String formatted = '';
    
    for (int i = 0; i < text.length; i++) {
      // Adiciona parênteses no DDD
      if (i == 0) {
        formatted += '(';
      }
      
      formatted += text[i];
      
      // Fecha parênteses após DDD
      if (i == 1) {
        formatted += ') ';
      }
      
      // Adiciona hífen na posição correta
      // Para celular (11 dígitos): (XX) XXXXX-XXXX - hífen após o 7º dígito
      // Para fixo (10 dígitos): (XX) XXXX-XXXX - hífen após o 6º dígito
      if (text.length >= 11 && i == 6) {
        formatted += '-';
      } else if (text.length == 10 && i == 5) {
        formatted += '-';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatter para CPF XXX.XXX.XXX-XX
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Limita a 11 dígitos
    if (text.length > 11) {
      return oldValue;
    }

    String formatted = '';
    
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      
      // Adiciona pontos após 3º e 6º dígitos
      if (i == 2 || i == 5) {
        formatted += '.';
      }
      
      // Adiciona hífen após 9º dígito
      if (i == 8) {
        formatted += '-';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatter customizado para formatar automaticamente dd/mm/aaaa
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length > 10) {
      return oldValue;
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 1 || i == 3) {
        formatted += '/';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
