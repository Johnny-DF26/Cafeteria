import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ViewDeleteProductScreen extends StatefulWidget {
  const ViewDeleteProductScreen({super.key});

  @override
  State<ViewDeleteProductScreen> createState() =>
      _ViewDeleteProductScreenState();
}

class _ViewDeleteProductScreenState extends State<ViewDeleteProductScreen> {
  List<Map<String, dynamic>> produtos = [];
  List<Map<String, dynamic>> produtosFiltrados = [];
  bool carregando = false;
  final TextEditingController idController = TextEditingController();

  static const String baseUrl = 'http://192.168.0.167:5000';

  @override
  void initState() {
    super.initState();
    buscarProdutos();
  }

  Future<void> buscarProdutos() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_products'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          produtos = List<Map<String, dynamic>>.from(data['produtos']);
          produtosFiltrados = List.from(produtos);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar produtos!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
    setState(() => carregando = false);
  }

  Future<void> deletarProduto(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/produtos/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso!')),
        );
        buscarProdutos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir produto!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Future<void> atualizarProduto(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/produtos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
        buscarProdutos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar produto!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  void filtrarPorId() {
    final idText = idController.text.trim();
    if (idText.isEmpty) {
      setState(() => produtosFiltrados = List.from(produtos));
      return;
    }
    final id = int.tryParse(idText);
    if (id == null) return;

    final filtrado = produtos.where((p) => p['idProdutos'] == id).toList();
    setState(() => produtosFiltrados = filtrado);
  }

  void abrirEdicao(Map<String, dynamic> produto) {
  final idProdutoController =
      TextEditingController(text: produto['idProdutos'].toString());
  final nomeController = TextEditingController(text: produto['nome']);
  final descricaoController =
      TextEditingController(text: produto['descricao']);
  final valorController =
      TextEditingController(text: produto['valor'].toString());
  final quantidadeController =
      TextEditingController(text: produto['quantidade_estoque'].toString());
  final imagemController = TextEditingController(text: produto['imagem']);
  final categoriaController =
      TextEditingController(text: produto['categoria'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        // Aumenta a altura mínima do box flutuante
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Produto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Campo ID (somente leitura) com espaçamento maior
              TextField(
                controller: idProdutoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'ID do Produto',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20), // aumento de espaçamento
              _buildTextField('Nome', nomeController),
              _buildTextField('Descrição', descricaoController),
              _buildTextField('Valor', valorController,
                  keyboardType: TextInputType.number),
              _buildTextField('Quantidade', quantidadeController,
                  keyboardType: TextInputType.number),
              _buildTextField('Imagem (URL)', imagemController),
              _buildTextField('Categoria', categoriaController),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final dadosAtualizados = {
                    'nome': nomeController.text,
                    'descricao': descricaoController.text,
                    'valor': double.tryParse(valorController.text) ?? 0.0,
                    'quantidade_estoque':
                        int.tryParse(quantidadeController.text) ?? 0,
                    'imagem': imagemController.text,
                    'categoria': categoriaController.text,
                  };
                  Navigator.pop(context);
                  atualizarProduto(produto['idProdutos'], dadosAtualizados);
                },
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                foregroundColor: Colors.white, // muda a cor do texto e ícones
                minimumSize: const Size(double.infinity, 50),
              ),
                child: const Text('Salvar Alterações'),
              ),],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          // Barra superior igual AdminScreen
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
                  // Campo para filtrar por ID
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: idController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'ID do Produto',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.confirmation_num),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: filtrarPorId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade900,
                        ),
                        child: const Text(
                          'Buscar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () {
                          idController.clear();
                          filtrarPorId();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                        ),
                        child: const Text(
                          'Mostrar todos',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gerenciar Produtos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  carregando
                      ? const Center(child: CircularProgressIndicator())
                      : produtosFiltrados.isEmpty
                          ? const Center(
                              child: Text('Nenhum produto encontrado.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: produtosFiltrados.length,
                              itemBuilder: (_, index) {
                                final produto = produtosFiltrados[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12)),
                                        child: produto['imagem'] != null &&
                                                produto['imagem'].isNotEmpty
                                            ? Image.network(
                                                produto['imagem'],
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: double.infinity,
                                                height: 200,
                                                color: Colors.brown.shade200,
                                                child: const Icon(Icons.image,
                                                    color: Colors.white,
                                                    size: 50),
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              produto['nome'] ?? 'Sem nome',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            const SizedBox(height: 6),
                                            // ID do produto
                                            Text(
                                              'ID: ${produto['idProdutos']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey),
                                            ),
                                            Text(
                                                'Descrição: ${produto['descricao'] ?? 'Sem descrição'}'),
                                            Text(
                                                'Categoria: ${produto['categoria'] ?? 'Não informada'}'),
                                            Text(
                                                'Estoque: ${produto['quantidade_estoque'] ?? 0}'),
                                            Text(
                                              'Valor: R\$ ${produto['valor']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () =>
                                                      abrirEdicao(produto),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Excluir Produto'),
                                                        content: Text(
                                                            'Deseja realmente excluir "${produto['nome']}"?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: const Text(
                                                                'Cancelar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              deletarProduto(
                                                                  produto['idProdutos']);
                                                            },
                                                            child: const Text(
                                                              'Excluir',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
