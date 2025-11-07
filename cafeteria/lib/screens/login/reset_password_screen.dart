import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('✅ Senha alterada com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Conta Bloqueada',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua conta foi bloqueada por excesso de tentativas inválidas de redefinição de senha.',
              style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
            ),
            SizedBox(height: 16),
            Text(
              '📧 Entre em contato com o suporte:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text('• Email: suporte@cafegourmet.com', style: TextStyle(fontFamily: 'Poppins')),
            Text('• Telefone: (XX) XXXXX-XXXX', style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.brown.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'ENTENDI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
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
                            Icons.lock_reset_rounded,
                            size: 48,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Redefinir Senha',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para redefinir sua senha, confirme seus dados',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

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
                              borderRadius: BorderRadius.circular(12),
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
                                      ? Icons.block_rounded
                                      : (_errorMessage!.contains('tentativa')
                                          ? Icons.warning_amber_rounded
                                          : Icons.error_outline_rounded),
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
                                          fontFamily: 'Poppins',
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
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      if (_errorMessage!.contains('tentativa')) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: _getTentativasProgress(),
                                            minHeight: 6,
                                            backgroundColor: Colors.orange.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            hintText: 'seu@email.com',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
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
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // CPF com máscara
                        TextFormField(
                          controller: _cpfCtrl,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            labelText: 'CPF',
                            labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            hintText: '000.000.000-00',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [_cpfMask],
                          validator: _validateCPF,
                        ),
                        const SizedBox(height: 16),

                        // Data de Nascimento com máscara
                        TextFormField(
                          controller: _birthDateCtrl,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            labelText: 'Data de Nascimento',
                            labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            hintText: 'DD/MM/AAAA',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [_dateMask],
                          validator: _validateDate,
                        ),
                        const SizedBox(height: 24),

                        Divider(color: Colors.grey.shade300, thickness: 1),
                        const SizedBox(height: 16),

                        // Nova senha
                        TextFormField(
                          controller: _newPassCtrl,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            hintText: 'Mínimo 6 caracteres',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
                            prefixIcon: Icon(Icons.lock_rounded, color: Colors.brown.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
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
                          obscureText: _obscure,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Digite a nova senha';
                            if (v.length < 6) return 'Senha mínima 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmar senha
                        TextFormField(
                          controller: _confirmPassCtrl,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            hintText: 'Digite a senha novamente',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
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
                          obscureText: _obscureConfirm,
                          validator: (v) {
                            if (v != _newPassCtrl.text) return 'Senhas não conferem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

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
                            onPressed: _loading ? null : _resetPassword,
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
                                        'Alterar Senha',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
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
        ),
      ),
    );
  }
}
