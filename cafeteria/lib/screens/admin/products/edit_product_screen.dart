import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;


String get baseUrl => GlobalConfig.GlobalConfig.api();


class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController idController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController imagemController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();

  bool produtoCarregado = false;
  bool carregando = false;

  //static const String baseUrl = 'http://192.168.0.167:5000';

  Future<void> buscarProduto() async {
    final id = idController.text.trim();
    if (id.isEmpty) return;

    setState(() => carregando = true);
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/produtos/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          nomeController.text = data['nome'] ?? '';
          descricaoController.text = data['descricao'] ?? '';
          valorController.text = data['valor'].toString();
          imagemController.text = data['imagem'] ?? '';
          quantidadeController.text = data['quantidade_estoque'].toString();
          categoriaController.text = data['categoria'] ?? '';
          produtoCarregado = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto não encontrado.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }

    setState(() => carregando = false);
  }

  Future<void> atualizarProduto() async {
    final id = idController.text.trim();
    if (!_formKey.currentState!.validate() || id.isEmpty) return;

    final body = {
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'valor': double.tryParse(valorController.text) ?? 0.0,
      'imagem': imagemController.text,
      'quantidade_estoque': int.tryParse(quantidadeController.text) ?? 0,
      'categoria': categoriaController.text,
    };

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/produtos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar produto.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Produto',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // -------------------- BUSCAR PRODUTO --------------------
                      TextFormField(
                        controller: idController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ID do Produto',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: carregando ? null : buscarProduto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: carregando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Buscar Produto',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // -------------------- FORMULARIO --------------------
                      if (produtoCarregado)
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField('Nome', nomeController),
                              _buildTextField('Descrição', descricaoController),
                              _buildTextField('Valor', valorController,
                                  keyboardType: TextInputType.number),
                              _buildTextField('Imagem (URL)', imagemController),
                              _buildTextField('Quantidade em Estoque',
                                  quantidadeController,
                                  keyboardType: TextInputType.number),
                              _buildTextField('Categoria', categoriaController),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: atualizarProduto,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade700,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'Salvar Alterações',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.brown)),
        ),
      ),
    );
  }
}
