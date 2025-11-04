import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

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

    // marcar alterações quando usuário digitar
    [
      nomeSocialController,
      nomeCompletoController,
      telefoneController,
      dataNascimentoController
    ].forEach((c) {
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

  Future<void> fetchUserData() async {
    setState(() => loading = true);

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user == null || user['id'] == null) {
      print('⚠️ Nenhum usuário logado');
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse('$baseUrl/get_usuario/${user['id']}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Conversão da data recebida
        DateTime? nascimento;
        if (data['data_nascimento'] != null && data['data_nascimento'].toString().isNotEmpty) {
          nascimento = DateTime.tryParse(data['data_nascimento']);
          if (nascimento == null) {
            try {
              nascimento = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(data['data_nascimento']).toLocal();
            } catch (_) {
              // fallback: deixar em branco
            }
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
      } else {
        print('Erro ao carregar usuário: ${response.statusCode}');
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

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_social': nomeSocialController.text.trim(),
          'nome_completo': nomeCompletoController.text.trim(),
          'telefone': telefoneController.text.trim(),
          'data_nascimento': _formatDateForApi(dataNascimentoController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          editing = false;
          _hasChanges = false;
        });
        await fetchUserData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Dados atualizados com sucesso!')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Erro ao atualizar dados.')));
      }
    } catch (e) {
      print('Erro ao atualizar: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Erro de conexão ao salvar.')));
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
      print('⚠️ Erro ao converter data para API: $e');
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
    );
    if (pickedDate != null) {
      dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                style: GoogleFonts.pacifico(fontSize: 30, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meus Dados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                          const SizedBox(height: 20),
                          Center(child: _buildAvatar()),
                          const SizedBox(height: 20),
                          _buildTextFormField('Nome Social', nomeSocialController, validator: (v) => null),
                          _buildTextFormField('Nome Completo', nomeCompletoController, validator: (v) => (v==null || v.trim().isEmpty) ? 'Obrigatório' : null),
                          _buildTextFormField('Email', emailController, readOnly: true),
                          _buildTextFormField('CPF', cpfController, readOnly: true),
                          _buildTextFormField('Telefone', telefoneController, validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (v.replaceAll(RegExp(r'\D'), '').length < 8) return 'Telefone inválido';
                            return null;
                          }),
                          GestureDetector(
                            onTap: editing ? _pickDate : null,
                            child: AbsorbPointer(
                              absorbing: false,
                              child: _buildTextFormField('Data de Nascimento', dataNascimentoController, readOnly: true, validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                try {
                                  DateFormat('dd/MM/yyyy').parseStrict(v);
                                  return null;
                                } catch (_) {
                                  return 'Formato dd/MM/yyyy';
                                }
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 220,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
                                onPressed: saving
                                    ? null
                                    : editing
                                        ? (_hasChanges ? () { updateUserData(); } : null)
                                        : () { setState(() => editing = true); },
                                child: saving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(editing ? 'Salvar Alterações' : 'Editar Dados', style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                          if (editing)
                            Center(
                              child: TextButton(
                                onPressed: saving
                                    ? null
                                    : () {
                                        // desfazer alterações
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
                                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
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
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (img != null && img.isNotEmpty) ? NetworkImage(img) : null,
          child: (img == null || img.isEmpty) ? Text((userData?['nome_completo'] ?? 'U').toString().substring(0,1).toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.brown)) : null,
        ),
        if (editing)
          Positioned(
            right: -6,
            bottom: -6,
            child: IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.edit, size: 18, color: Colors.brown)),
              onPressed: () {
                // aqui você pode abrir um seletor de imagem ou outra tela
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Implementar seleção de avatar')));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, {bool readOnly = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: !editing || readOnly,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
