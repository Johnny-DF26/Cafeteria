//import 'package:cafeteria/screens/admin/admin_screen.dart';
import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../services/auth_service.dart';
import '../choose/choose_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMessage;

  int _tentativas = 0;
  final int _maxTentativas = 5;

  static const double imageScale = 1.17;

  double _getTentativasProgress() {
    return (_tentativas / _maxTentativas).clamp(0.0, 1.0);
  }

  void _showBlockedDialog() {
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
              'Conta de administrador bloqueada por excesso de tentativas.',
              style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
            ),
            SizedBox(height: 16),
            Text(
              '📧 Contate o suporte.',
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
              backgroundColor: Colors.red.shade700,
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

    // Se já atingiu o limite, mostra card suspenso e card vermelho
    if (_tentativas >= _maxTentativas) {
      setState(() {
        _errorMessage = 'Conta bloqueada por excesso de tentativas. Contate o suporte.';
      });
      _showBlockedDialog();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final adminData = await _auth.signInAdmin(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _tentativas = 0;
      });
      Navigator.pushReplacementNamed(
        context,
        Routes.admin,
        arguments: adminData,
      );
    } on AuthException catch (e) {
      // Se já está bloqueada/inativa, NÃO incrementa tentativas!
      if (e.message.contains('bloqueada') || e.message.contains('inativa')) {
        setState(() => _errorMessage = e.message);
        // Não incrementa _tentativas, não mostra barra!
        return;
      }
      // Erro comum: incrementa tentativas normalmente
      setState(() {
        _tentativas++;
        int restantes = (_maxTentativas - _tentativas);
        if (restantes > 0) {
          _errorMessage = '${e.message}\nRestam $restantes tentativa${restantes > 1 ? 's' : ''}.';
        } else {
          _errorMessage = 'Conta bloqueada por excesso de tentativas. Contate o suporte.';
          _showBlockedDialog();
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
                                color: Colors.red.shade200,
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
                                  Icons.admin_panel_settings_rounded,
                                  size: 80,
                                  color: Colors.red.shade600,
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
                        const Text('Administrador',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _errorMessage!.contains('bloqueada') || _errorMessage!.contains('inativa')
                                  ? Colors.red.shade100
                                  : (_errorMessage!.contains('tentativa')
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50),
                              borderRadius: BorderRadius.circular(8),
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
                            if (v == null || v.isEmpty)
                              return 'Preencha a senha';
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
