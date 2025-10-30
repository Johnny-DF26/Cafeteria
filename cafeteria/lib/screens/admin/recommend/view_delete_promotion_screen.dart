import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ViewDeletePromotionScreen extends StatefulWidget {
  final Map<String, dynamic> adminData; // Recebe o adminData completo
  const ViewDeletePromotionScreen({super.key, required this.adminData});

  @override
  State<ViewDeletePromotionScreen> createState() =>
      _ViewDeletePromotionScreenState();
}

class _ViewDeletePromotionScreenState extends State<ViewDeletePromotionScreen> {
  List<Map<String, dynamic>> promocoes = [];
  List<Map<String, dynamic>> promocoesFiltradas = [];
  bool carregando = false;
  final TextEditingController idController = TextEditingController();

  static const String baseUrl = 'http://192.168.0.167:5000';

  @override
  void initState() {
    super.initState();
    buscarPromocoes();
  }

  Future<void> buscarPromocoes() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/promocao'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          promocoes = List<Map<String, dynamic>>.from(data);
          promocoesFiltradas = List.from(promocoes);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar promoções!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
    setState(() => carregando = false);
  }

  Future<void> deletarPromocao(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/promocao/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoção excluída com sucesso!')),
        );
        buscarPromocoes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir promoção!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Future<void> atualizarPromocao(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/promocao/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoção atualizada com sucesso!')),
        );
        buscarPromocoes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar promoção!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Future<void> adicionarPromocao(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/promocao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoção adicionada com sucesso!')),
        );
        buscarPromocoes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao adicionar promoção!')),
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
      setState(() => promocoesFiltradas = List.from(promocoes));
      return;
    }
    final id = int.tryParse(idText);
    if (id == null) return;

    final filtrado =
        promocoes.where((p) => p['idProdutos'] == id).toList();
    setState(() => promocoesFiltradas = filtrado);
  }

  void abrirEdicao(Map<String, dynamic> produto) {
    final precoController =
        TextEditingController(text: produto['valor'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Promoção',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('ID Produto: ${produto['idProdutos']}'),
                const SizedBox(height: 12),
                _buildTextField('Preço Promocional', precoController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final dadosAtualizados = {
                      'preco_promocional':
                          double.tryParse(precoController.text) ?? 0.0,
                    };
                    Navigator.pop(context);
                    atualizarPromocao(produto['idProdutos'], dadosAtualizados);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void abrirAdicionarPromocao() {
    final produtoIdController = TextEditingController();
    final precoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adicionar Promoção',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTextField('ID do Produto', produtoIdController,
                    keyboardType: TextInputType.number),
                _buildTextField('Preço Promocional', precoController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final dados = {
                      'Produto_idProduto':
                          int.tryParse(produtoIdController.text) ?? 0,
                      'preco_promocional':
                          double.tryParse(precoController.text) ?? 0.0,
                    };
                    Navigator.pop(context);
                    adicionarPromocao(dados);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Adicionar Promoção'),
                ),
              ],
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
    final adminNome = widget.adminData['nome'] ?? 'Administrador';

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
                          'Mostrar todas',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gerenciar Promoções',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: abrirAdicionarPromocao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Adicionar Nova Promoção'),
                  ),
                  const SizedBox(height: 16),
                  carregando
                      ? const Center(child: CircularProgressIndicator())
                      : promocoesFiltradas.isEmpty
                          ? const Center(
                              child: Text('Nenhuma promoção encontrada.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: promocoesFiltradas.length,
                              itemBuilder: (_, index) {
                                final produto = promocoesFiltradas[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
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
                                              'ID Produto: ${produto['idProdutos']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text('Nome: ${produto['nome']}'),
                                            Text(
                                                'Descrição: ${produto['descricao']}'),
                                            Text(
                                                'Categoria: ${produto['categoria']}'),
                                            Text(
                                                'Preço Promocional: R\$ ${produto['valor'].toStringAsFixed(2)}'),
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
                                                            'Remover Promoção'),
                                                        content: Text(
                                                            'Deseja realmente remover a promoção do produto ID ${produto['idProdutos']}?'),
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
                                                              deletarPromocao(
                                                                  produto[
                                                                      'idProdutos']);
                                                            },
                                                            child: const Text(
                                                              'Remover',
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
                                            ),
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
