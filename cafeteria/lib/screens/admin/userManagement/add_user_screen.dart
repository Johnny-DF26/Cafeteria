import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class AddUserScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AddUserScreen({super.key, required this.adminData});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
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
    final adminId = widget.adminData['id'];
    print('ID: $adminId');
    final url = Uri.parse('$baseUrl/adicionar_usuario/$adminId');
    print(url);
    
    // Remove máscaras antes de enviar
    final body = jsonEncode({
      'nome': _nameCtrl.text.trim(),
      'telefone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'email': _emailCtrl.text.trim(),
      'senha': _passCtrl.text.trim(),
      'data_nascimento': _birthCtrl.text.trim(),
      'cpf': _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    print('Dados do usuário recebidos em adicionar usuário: ${widget.adminData}');
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Barra superior igual às outras telas
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 70,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Café Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título fora da barra
                  Text(
                    'Adicionar Novo Usuário',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados para criar uma nova conta',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Card do formulário
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Nome completo
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Nome completo',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha seu nome';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // CPF com máscara
                                TextFormField(
                                  controller: _cpfCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                    _CpfInputFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'CPF',
                                    hintText: '000.000.000-00',
                                    prefixIcon: const Icon(Icons.credit_card),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha o CPF';
                                    final cpf = v.replaceAll(RegExp(r'\D'), '');
                                    if (cpf.length != 11) return 'CPF inválido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Data de nascimento com máscara
                                TextFormField(
                                  controller: _birthCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(8),
                                    _DateInputFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Data de nascimento',
                                    hintText: 'DD/MM/AAAA',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha a data';
                                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(v.trim())) {
                                      return 'Formato inválido';
                                    }
                                    // Converte DD/MM/AAAA para AAAA-MM-DD antes de enviar
                                    final parts = v.split('/');
                                    _birthCtrl.text = '${parts[2]}-${parts[1]}-${parts[0]}';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Telefone com máscara
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                    _PhoneInputFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Telefone',
                                    hintText: '(00) 00000-0000',
                                    prefixIcon: const Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha o telefone';
                                    final phone = v.replaceAll(RegExp(r'\D'), '');
                                    if (phone.length < 10) return 'Telefone inválido';
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
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha o email';
                                    if (!v.contains('@')) return 'Email inválido';
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
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                const SizedBox(height: 16),

                                // Confirmar senha
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Confirme a senha';
                                    if (v != _passCtrl.text) return 'Senhas não conferem';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Botão criar conta
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 2,
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Criar Conta',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade200.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      ),
    );
  }
}

// Formatadores de máscara
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    buffer.write('(');
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
