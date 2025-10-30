import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:intl/intl.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  int _currentIndex = 1;
  bool loading = false;
  bool editing = false;
  Map<String, dynamic>? userData;

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
  }

  Future<void> fetchUserData() async {
    setState(() => loading = true);

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user == null || user['id'] == null) {
      print('⚠️ Nenhum usuário logado');
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse('http://192.168.0.167:5000/get_usuario/${user['id']}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Conversão da data recebida
        DateTime? nascimento;
        if (data['data_nascimento'] != null) {
          nascimento ??= DateTime.tryParse(data['data_nascimento']);
          if (nascimento == null) {
            try {
              nascimento = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'")
                  .parseUtc(data['data_nascimento'])
                  .toLocal();
            } catch (e) {
              print('⚠️ Erro ao converter data: $e');
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
          dataNascimentoController.text = nascimento != null
              ? DateFormat('dd/MM/yyyy').format(nascimento)
              : '';
        });
      } else {
        print('Erro ao carregar usuário: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar com a API: $e');
    }

    setState(() => loading = false);
  }

  Future<void> updateUserData() async {
    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user == null || user['id'] == null) return;

    final url = Uri.parse('http://192.168.0.167:5000/update_usuario/${user['id']}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_social': nomeSocialController.text,
          'nome_completo': nomeCompletoController.text,
          'telefone': telefoneController.text,
          'data_nascimento': _formatDateForApi(dataNascimentoController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() => editing = false);
        fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Dados atualizados com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao atualizar dados.')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 100,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Dados',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700),
                        ),
                        const SizedBox(height: 25),
                        _buildTextField('Nome Social', nomeSocialController),
                        _buildTextField('Nome Completo', nomeCompletoController),
                        _buildTextField('Email', emailController, readOnly: true),
                        _buildTextField('CPF', cpfController, readOnly: true),
                        _buildTextField('Telefone', telefoneController),
                        _buildTextField('Data de Nascimento',
                          dataNascimentoController,
                          readOnly: true,
                          onTap: () async {
                            if (!editing) return;
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              locale: const Locale('pt', 'BR'),
                            );
                            if (pickedDate != null) {
                              dataNascimentoController.text =
                                  DateFormat('dd/MM/yyyy').format(pickedDate);
                            }
                          },
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                            ),
                            onPressed: () {
                              if (editing) {
                                updateUserData();
                              } else {
                                setState(() => editing = true);
                              }
                            },
                            child: Text(
                              editing ? 'Salvar Alterações' : 'Editar Dados',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrinho',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: !editing || readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
