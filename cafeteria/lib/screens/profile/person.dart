import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;
import 'package:flutter/services.dart';

String get baseUrl => GlobalConfig.GlobalConfig.api();

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  int _currentIndex = 1;
  bool loading = false;
  bool editing = false;
  bool saving = false;
  Map<String, dynamic>? userData;

  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  // Controllers
  final nomeSocialController = TextEditingController();
  final nomeCompletoController = TextEditingController();
  final emailController = TextEditingController();
  final cpfController = TextEditingController();
  final telefoneController = TextEditingController();
  final dataNascimentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, fetchUserData);

    [nomeSocialController, nomeCompletoController, telefoneController, dataNascimentoController].forEach((c) {
      c.addListener(() {
        if (!mounted) return;
        final changed = _detectChanges();
        if (changed != _hasChanges) setState(() => _hasChanges = changed);
      });
    });
  }

  bool _detectChanges() {
    if (userData == null) return false;
    return (nomeSocialController.text != (userData!['nome_social'] ?? '')) ||
        (nomeCompletoController.text != (userData!['nome_completo'] ?? '')) ||
        (telefoneController.text != (userData!['telefone'] ?? '')) ||
        (dataNascimentoController.text != _formatDateDisplayFromApi(userData!['data_nascimento'] ?? ''));
  }

  @override
  void dispose() {
    nomeSocialController.dispose();
    nomeCompletoController.dispose();
    emailController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    dataNascimentoController.dispose();
    super.dispose();
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) return phone;
    
    final ddd = digitsOnly.substring(0, 2);
    final firstPart = digitsOnly.substring(2, digitsOnly.length >= 7 ? 7 : digitsOnly.length);
    final secondPart = digitsOnly.length > 7 ? digitsOnly.substring(7) : '';
    
    return secondPart.isNotEmpty ? '($ddd) $firstPart-$secondPart' : '($ddd) $firstPart';
  }

  String _formatCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '';
    final digitsOnly = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 11) return cpf;
    
    return '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3, 6)}.${digitsOnly.substring(6, 9)}-${digitsOnly.substring(9)}';
  }

  Future<void> fetchUserData() async {
    setState(() => loading = true);

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user == null || user['id'] == null) {
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse('$baseUrl/get_usuario/${user['id']}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        DateTime? nascimento;
        if (data['data_nascimento'] != null && data['data_nascimento'].toString().isNotEmpty) {
          nascimento = DateTime.tryParse(data['data_nascimento']);
          if (nascimento == null) {
            try {
              nascimento = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(data['data_nascimento']).toLocal();
            } catch (_) {}
          }
        }

        setState(() {
          userData = data;
          nomeSocialController.text = data['nome_social'] ?? '';
          nomeCompletoController.text = data['nome_completo'] ?? '';
          emailController.text = data['email'] ?? '';
          cpfController.text = data['cpf'] ?? '';
          telefoneController.text = data['telefone'] ?? '';
          dataNascimentoController.text = nascimento != null ? DateFormat('dd/MM/yyyy').format(nascimento) : '';
          _hasChanges = false;
        });
      }
    } catch (e) {
      print('Erro ao conectar com a API: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user == null || user['id'] == null) return;

    setState(() => saving = true);

    final url = Uri.parse('$baseUrl/update_usuario/${user['id']}');
    print(url);
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_social': nomeSocialController.text.trim(),
          'nome_completo': nomeCompletoController.text.trim(),
          'telefone': telefoneController.text.replaceAll(RegExp(r'\D'), ''),
          'data_nascimento': _formatDateForApi(dataNascimentoController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          editing = false;
          _hasChanges = false;
        });
        await fetchUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Dados atualizados com sucesso!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('❌ Erro ao atualizar dados.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('❌ Erro de conexão ao salvar.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _formatDateForApi(String date) {
    if (date.isEmpty) return '';
    try {
      final parsedDate = DateFormat('dd/MM/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatDateDisplayFromApi(String value) {
    if (value.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(value);
    if (dt != null) return DateFormat('dd/MM/yyyy').format(dt);
    try {
      dt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(value).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return value;
    }
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (dataNascimentoController.text.isNotEmpty) {
      try {
        initial = DateFormat('dd/MM/yyyy').parse(dataNascimentoController.text);
      } catch (_) {}
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.brown.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.brown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 110,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Café Gourmet',
                style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.brown.shade700, Colors.brown.shade400],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Carregando seus dados...'),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título fora da AppBar
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              editing ? 'Editando Perfil ✏️' : 'Meus Dados Pessoais',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade800,
                              ),
                            ),
                          ),

                          // Avatar sem card
                          Center(
                            child: Column(
                              children: [
                                _buildAvatar(),
                                const SizedBox(height: 16),
                                Text(
                                  nomeCompletoController.text.isNotEmpty
                                      ? nomeCompletoController.text
                                      : 'Nome do Usuário',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (emailController.text.isNotEmpty)
                                  Text(
                                    emailController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Form Card
                          Card(
                            elevation: 4,
                            shadowColor: Colors.brown.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.brown.shade700, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Informações Pessoais',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildStyledTextField(
                                    label: 'Nome Social',
                                    controller: nomeSocialController,
                                    icon: Icons.face,
                                  ),
                                  _buildStyledTextField(
                                    label: 'Nome Completo',
                                    controller: nomeCompletoController,
                                    icon: Icons.person_outline,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? '❌ Obrigatório' : null,
                                  ),
                                  _buildStyledTextField(
                                    label: 'Email',
                                    controller: emailController,
                                    icon: Icons.email_outlined,
                                    readOnly: true,
                                    enabled: false,
                                  ),
                                  _buildStyledTextField(
                                    label: 'CPF',
                                    controller: TextEditingController(text: _formatCPF(cpfController.text)),
                                    icon: Icons.badge_outlined,
                                    readOnly: true,
                                    enabled: false,
                                  ),
                                  _buildStyledTextField(
                                    label: 'Telefone',
                                    controller: TextEditingController(text: _formatPhone(telefoneController.text)),
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {
                                      telefoneController.text = value.replaceAll(RegExp(r'\D'), '');
                                    },
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return null;
                                      if (v.replaceAll(RegExp(r'\D'), '').length < 8) return '❌ Telefone inválido';
                                      return null;
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: editing ? _pickDate : null,
                                    child: AbsorbPointer(
                                      child: _buildStyledTextField(
                                        label: 'Data de Nascimento',
                                        controller: dataNascimentoController,
                                        icon: Icons.cake_outlined,
                                        readOnly: true,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return null;
                                          try {
                                            DateFormat('dd/MM/yyyy').parseStrict(v);
                                            return null;
                                          } catch (_) {
                                            return '❌ Formato dd/MM/yyyy';
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botões
                          if (!editing)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => setState(() => editing = true),
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  'Editar Dados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          if (editing) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges ? Colors.brown : Colors.grey,
                                  foregroundColor: Colors.white,
                                  elevation: _hasChanges ? 4 : 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: saving ? null : (_hasChanges ? updateUserData : null),
                                icon: saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: Text(
                                  saving ? 'Salvando...' : 'Salvar Alterações',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade400, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: saving
                                    ? null
                                    : () {
                                        setState(() {
                                          editing = false;
                                          if (userData != null) {
                                            nomeSocialController.text = userData!['nome_social'] ?? '';
                                            nomeCompletoController.text = userData!['nome_completo'] ?? '';
                                            telefoneController.text = userData!['telefone'] ?? '';
                                            dataNascimentoController.text = _formatDateDisplayFromApi(userData!['data_nascimento'] ?? '');
                                            _hasChanges = false;
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.cancel),
                                label: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) Navigator.pushNamed(context, Routes.cart);
          if (index == 1) Navigator.pushNamed(context, Routes.home);
          if (index == 2) Navigator.pushNamed(context, Routes.order);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrinho'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final img = userData != null ? (userData!['imagem'] ?? '') : '';
    final initial = (userData?['nome_completo'] ?? 'U').toString().substring(0, 1).toUpperCase();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.brown.shade300, Colors.brown.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.shade200,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.brown.shade100,
            backgroundImage: (img.isNotEmpty) ? NetworkImage(img) : null,
            child: (img.isEmpty)
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700,
                    ),
                  )
                : null,
          ),
        ),
        if (editing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.white),
                          SizedBox(width: 12),
                          Text('📸 Implementar seleção de avatar'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: !editing || readOnly,
        enabled: enabled,
        validator: validator,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: enabled ? Colors.brown.shade700 : Colors.grey),
          filled: true,
          fillColor: enabled && editing ? Colors.white : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}
