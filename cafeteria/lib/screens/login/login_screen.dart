import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../services/auth_service.dart';
import '../choose/choose_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria/screens/global/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMessage;

  int _tentativasRestantes = 5; // Valor padrão

  // Escala da imagem
  static const double imageScale = 1.17;

  double _getTentativasProgress() {
    return (5 - _tentativasRestantes) / 5;
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
              'Sua conta foi bloqueada por excesso de tentativas inválidas de login.',
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ChooseProfileScreen()),
              );
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _auth.signInWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      final status = userData['status'];
      final isActive = status == 1 || status == '1' || status == true || status == 'ativo' || status == 'Ativo';

      if (!isActive) {
        setState(() => _errorMessage = 'Sua conta está inativa. Entre em contato com o administrador.');
        return;
      }

      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(userData);
      setState(() {
        _tentativasRestantes = 5;
      });
      Navigator.pushReplacementNamed(context, Routes.home);
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;

        // Extrai tentativas restantes da mensagem da API
        final match = RegExp(r'Restam (\d+) tentativa').firstMatch(e.message);
        if (match != null) {
          _tentativasRestantes = int.tryParse(match.group(1) ?? '5') ?? 5;
        }

        // Se bloqueada, mostra o dialog e navega
        if (e.message.contains('bloqueada')) {
          _showBlockedAccountDialog();
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão Voltar
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChooseProfileScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // LOGO com escala ajustável
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.shade200,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Center(
                            child: Transform.scale(
                              scale: imageScale,
                              child: Image.asset(
                                'assets/images/pngtree-coffee-logo-design-png-image_6352424.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.coffee,
                                  size: 80,
                                  color: Colors.brown.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Café Gourmet',
                          style: GoogleFonts.pacifico(
                            fontSize: 30,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Faça seu Login',
                            style: TextStyle(color: Colors.black54)),

                        // No build, mantenha o card vermelho igual ao reset:
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
                                  ? Colors.red.shade100
                                  : (_errorMessage!.contains('tentativa')
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
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
                                  _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
                                      ? Icons.block_rounded
                                      : (_errorMessage!.contains('tentativa')
                                          ? Icons.warning_amber_rounded
                                          : Icons.error_outline_rounded),
                                  color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
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
                                        _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
                                            ? '🔒 Conta Bloqueada'
                                            : (_errorMessage!.contains('tentativa')
                                                ? '⚠️ Atenção'
                                                : '❌ Erro'),
                                        style: TextStyle(
                                          color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
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
                                          color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
                                              ? Colors.red.shade800
                                              : (_errorMessage!.contains('tentativa')
                                                  ? Colors.orange.shade800
                                                  : Colors.red.shade800),
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      // Só mostra barra de progresso se NÃO estiver bloqueada/inativa
                                      if (_errorMessage!.contains('tentativa') &&
                                          !_errorMessage!.contains('bloqueada') &&
                                          !_errorMessage!.contains('inativa')) ...[
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

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Preencha o email';
                            }
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          obscureText: _obscure,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Preencha a senha';
                            if (v.length < 6) {
                              return 'Senha mínima 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, Routes.resetPassword),
                              child: const Text(
                                'Esqueci a senha',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, Routes.signup),
                              child: const Text(
                                'Cadastrar conta',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12),
                              ),
                            ),
                          ],
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
