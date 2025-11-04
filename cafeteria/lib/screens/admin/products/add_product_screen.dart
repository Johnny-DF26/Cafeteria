import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;


String get baseUrl => GlobalConfig.GlobalConfig.api();

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AddProductScreen({super.key, required this.adminData});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController imagemController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController avaliacaoController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();

  bool _loading = false;

  Future<void> cadastrarProduto() async {
    if (!_formKey.currentState!.validate()) return;
    print('Tipo: ${baseUrl.runtimeType}, URL: ${baseUrl}');

    setState(() => _loading = true);

    final produtoData = {
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'valor': double.tryParse(valorController.text) ?? 0,
      'quantidade_estoque': int.tryParse(quantidadeController.text) ?? 0,
      'imagem': imagemController.text,
      //'avaliacao': avaliacaoController.text.isNotEmpty ? avaliacaoController.text : null,
      'categoria': categoriaController.text.isNotEmpty ? categoriaController.text : 'geral',
      'vitrine_id': 1,         // Pode ser alterado conforme usuário/admin
      'administrador_id': widget.adminData['id'],    // Pode ser alterado conforme login
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(produtoData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar produto: ${response.body}')),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool obrigatorio = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: obrigatorio
            ? (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adicionar Produto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Nome', nomeController),
                        _buildTextField('Descrição', descricaoController),
                        _buildTextField('Categoria', categoriaController, obrigatorio: false),
                        _buildTextField('Valor', valorController, keyboardType: TextInputType.number),
                        _buildTextField('Imagem (URL)', imagemController),
                        _buildTextField('Quantidade em Estoque', quantidadeController, keyboardType: TextInputType.number),
                        //_buildTextField('Avaliação', avaliacaoController, obrigatorio: false),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : cadastrarProduto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Cadastrar Produto',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
