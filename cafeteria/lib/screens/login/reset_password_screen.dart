import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // Máscaras
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    _birthDateCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Remove máscara do CPF
      final cpfLimpo = _cpfCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Converte data DD/MM/YYYY para YYYY-MM-DD
      final dateParts = _birthDateCtrl.text.split('/');
      final birthDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      await _auth.resetPassword(
        email: _emailCtrl.text.trim(),
        cpf: cpfLimpo,
        birthDate: birthDate,
        newPassword: _newPassCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Senha alterada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
      
      // Se a conta foi bloqueada, exibe diálogo
      if (e.message.contains('bloqueada')) {
        _showBlockedAccountDialog();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao redefinir senha. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBlockedAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Conta Bloqueada'),
          ],
        ),
        content: const Text(
          'Sua conta foi bloqueada por excesso de tentativas inválidas.\n\n'
          'Entre em contato com o suporte para desbloqueá-la.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Digite o email';
    if (!value.contains('@')) return 'Email inválido';
    return null;
  }

  String? _validateCPF(String? value) {
    if (value == null || value.isEmpty) return 'Digite o CPF';
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return 'CPF inválido';
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) return 'Digite a data de nascimento';
    if (value.length != 10) return 'Data incompleta';
    
    final parts = value.split('/');
    if (parts.length != 3) return 'Formato inválido';
    
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return 'Data inválida';
    if (day < 1 || day > 31) return 'Dia inválido';
    if (month < 1 || month > 12) return 'Mês inválido';
    if (year < 1900 || year > DateTime.now().year) return 'Ano inválido';

    return null;
  }

  double _getTentativasProgress() {
    if (_errorMessage == null || !_errorMessage!.contains('tentativa')) {
      return 0.0;
    }
    
    // Extrai o número de tentativas restantes da mensagem
    final regex = RegExp(r'(\d+) tentativa');
    final match = regex.firstMatch(_errorMessage!);
    
    if (match != null) {
      final tentativasRestantes = int.parse(match.group(1)!);
      return (5 - tentativasRestantes) / 5; // Progresso de 0 a 1
    }
    
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
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
                        'Para redefinir sua senha, confirme seus dados',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _errorMessage!.contains('bloqueada') 
                                ? Colors.red.shade100 
                                : (_errorMessage!.contains('tentativa')
                                    ? Colors.orange.shade50
                                    : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _errorMessage!.contains('bloqueada')
                                  ? Colors.red.shade700
                                  : (_errorMessage!.contains('tentativa')
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _errorMessage!.contains('bloqueada')
                                    ? Icons.block
                                    : (_errorMessage!.contains('tentativa')
                                        ? Icons.warning_amber
                                        : Icons.error_outline),
                                color: _errorMessage!.contains('bloqueada')
                                    ? Colors.red.shade700
                                    : (_errorMessage!.contains('tentativa')
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _errorMessage!.contains('bloqueada')
                                          ? '🔒 Conta Bloqueada'
                                          : (_errorMessage!.contains('tentativa')
                                              ? '⚠️ Atenção'
                                              : '❌ Erro'),
                                      style: TextStyle(
                                        color: _errorMessage!.contains('bloqueada')
                                            ? Colors.red.shade900
                                            : (_errorMessage!.contains('tentativa')
                                                ? Colors.orange.shade900
                                                : Colors.red.shade900),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: _errorMessage!.contains('bloqueada')
                                            ? Colors.red.shade800
                                            : (_errorMessage!.contains('tentativa')
                                                ? Colors.orange.shade800
                                                : Colors.red.shade800),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_errorMessage!.contains('tentativa')) ...[
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: _getTentativasProgress(),
                                        backgroundColor: Colors.orange.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          hintText: 'seu@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),

                      // CPF com máscara
                      TextFormField(
                        controller: _cpfCtrl,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.badge),
                          hintText: '000.000.000-00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [_cpfMask],
                        validator: _validateCPF,
                      ),
                      const SizedBox(height: 12),

                      // Data de Nascimento com máscara
                      TextFormField(
                        controller: _birthDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Data de Nascimento',
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'DD/MM/AAAA',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [_dateMask],
                        validator: _validateDate,
                      ),
                      const SizedBox(height: 20),

                      const Divider(),
                      const SizedBox(height: 12),

                      // Nova senha
                      TextFormField(
                        controller: _newPassCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Digite a nova senha';
                          if (v.length < 6) return 'Senha mínima 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Confirmar senha
                      TextFormField(
                        controller: _confirmPassCtrl,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        obscureText: _obscureConfirm,
                        validator: (v) {
                          if (v != _newPassCtrl.text) return 'Senhas não conferem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Alterar senha'),
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
    );
  }
}
