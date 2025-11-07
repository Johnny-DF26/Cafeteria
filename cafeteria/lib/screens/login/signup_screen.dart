import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/routes.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String? _convertDateToMySQL(String dateStr) {
    try {
      dateStr = dateStr.trim();
      final DateFormat brFormat = DateFormat('dd/MM/yyyy');
      final DateTime date = brFormat.parseStrict(dateStr);
      final DateFormat mysqlFormat = DateFormat('yyyy-MM-dd');
      return mysqlFormat.format(date);
    } catch (e) {
      return null;
    }
  }

  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'\D'), '');
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final url = Uri.parse('$baseUrl/cadastro_usuario');
    
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
      'telefone': _cleanText(_phoneCtrl.text),
      'email': _emailCtrl.text.trim(),
      'senha': _passCtrl.text.trim(),
      'data_nascimento': dataNascimentoMySQL,
      'cpf': _cleanText(_cpfCtrl.text),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Conta criada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushReplacementNamed(context, Routes.choose);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('E-mail já cadastrado!'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro de conexão: $e')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Café Gourmet',
          style: GoogleFonts.pacifico(
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove o botão voltar
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
              child: Card(
                elevation: 8,
                shadowColor: Colors.brown.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone de cabeçalho
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            size: 48,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Crie sua conta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preencha os dados abaixo para começar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Nome completo
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nome completo',
                            hintText: 'Digite seu nome completo',
                            prefixIcon: Icon(Icons.person_rounded, color: Colors.brown.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Preencha seu nome';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Telefone e Data de Nascimento (lado a lado)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Telefone',
                                  hintText: '(XX) XXXXX-XXXX',
                                  prefixIcon: Icon(Icons.phone_rounded, color: Colors.brown.shade600),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _PhoneInputFormatter(),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                                  final cleanPhone = _cleanText(v);
                                  if (!RegExp(r'^\d{10,11}$').hasMatch(cleanPhone)) {
                                    return 'Inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _birthCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Nascimento',
                                  hintText: 'dd/mm/aaaa',
                                  prefixIcon: Icon(Icons.cake_rounded, color: Colors.brown.shade600),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _DateInputFormatter(),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(v)) {
                                    return 'Formato inválido';
                                  }
                                  if (_convertDateToMySQL(v) == null) {
                                    return 'Data inválida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // CPF
                        TextFormField(
                          controller: _cpfCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'CPF',
                            hintText: '000.000.000-00',
                            prefixIcon: Icon(Icons.credit_card_rounded, color: Colors.brown.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CpfInputFormatter(),
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
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'seu@email.com',
                            prefixIcon: Icon(Icons.email_rounded, color: Colors.brown.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Preencha o email';
                            if (!v.contains('@')) return '❌ Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Senha
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Mínimo 6 caracteres',
                            prefixIcon: Icon(Icons.lock_rounded, color: Colors.brown.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Preencha a senha';
                            if (v.length < 6) return 'Senha mínima 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmar senha
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            hintText: 'Digite a senha novamente',
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.brown.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirme a senha';
                            if (v != _passCtrl.text) return '❌ Senhas não conferem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botão criar conta
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Criar Conta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // Botão voltar (mantido no corpo do card)
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Voltar ao login'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.brown.shade700,
                          ),
                        ),
                      ],
                    ),
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
