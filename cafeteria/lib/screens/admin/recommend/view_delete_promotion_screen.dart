import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

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

  //static const String baseUrl = 'http://192.168.0.167:5000';

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

  Future<void> atualizarPromocao(int id, Map<String, dynamic> dados) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/promocao/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Promoção atualizada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        buscarPromocoes();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao atualizar promoção!'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erro de conexão!'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> adicionarPromocao(Map<String, dynamic> dados) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/promocao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 201) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Promoção adicionada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        buscarPromocoes();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao adicionar promoção!'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erro de conexão!'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> deletarPromocao(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.delete(Uri.parse('$baseUrl/promocao/$id'));
      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Promoção excluída com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        buscarPromocoes();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao excluir promoção!'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erro de conexão!'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
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
    final precoController = TextEditingController(
      text: produto['valor'] != null
          ? produto['valor'].toString().replaceAll('.', ',')
          : '',
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.green.shade700,
            width: 2,
          ),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Editar Promoção',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('ID Produto: ${produto['idProdutos']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildTextField('Preço Promocional', precoController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      final precoStr = precoController.text.replaceAll(',', '.');
                      final dadosAtualizados = {
                        'preco_promocional': double.tryParse(precoStr) ?? 0.0,
                      };
                      Navigator.pop(context);
                      atualizarPromocao(produto['idProdutos'], dadosAtualizados);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
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

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.green.shade700,
            width: 2,
          ),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Adicionar Promoção',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildTextField('ID do Produto', produtoIdController, keyboardType: TextInputType.number),
                _buildTextField('Preço Promocional', precoController, keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Adicionar Promoção', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      final precoStr = precoController.text.replaceAll(',', '.');
                      final dados = {
                        'Produto_idProduto': int.tryParse(produtoIdController.text) ?? 0,
                        'preco_promocional': double.tryParse(precoStr) ?? 0.0,
                      };
                      Navigator.pop(context);
                      adicionarPromocao(dados);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
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
    //print(promocoesFiltradas[34]['imagem']);
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
                                            ? Image.asset(
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
                                              'Preço Promocional: R\$ ${produto['valor'].toStringAsFixed(2).replaceAll('.', ',')}',
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
                                                      builder: (_) => Dialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(24),
                                                          side: BorderSide(
                                                            color: Colors.red.shade700,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        elevation: 8,
                                                        backgroundColor: Colors.white,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(24.0),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
                                                              const SizedBox(height: 16),
                                                              Text(
                                                                'Remover Promoção',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.red.shade700,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 12),
                                                              Text(
                                                                'Deseja realmente remover a promoção do produto ID ${produto['idProdutos']}?',
                                                                textAlign: TextAlign.center,
                                                                style: GoogleFonts.poppins(fontSize: 16),
                                                              ),
                                                              const SizedBox(height: 24),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: TextButton(
                                                                      onPressed: () => Navigator.pop(context),
                                                                      child: const Text('Cancelar'),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 12),
                                                                  Expanded(
                                                                    child: ElevatedButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                        deletarPromocao(produto['idProdutos']);
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: Colors.red.shade700,
                                                                        foregroundColor: Colors.white,
                                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                        elevation: 2,
                                                                      ),
                                                                      child: const Text('Remover'),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
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
