import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;


String get baseUrl => GlobalConfig.GlobalConfig.api();

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
  String? categoriaSelecionada;
  List<String> categorias = [];

  @override
  void initState() {
    super.initState();
    buscarProdutos();
  }

  @override
  void dispose() {
    idController.dispose();
    super.dispose();
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
          categorias = produtos
              .map((p) => (p['categoria'] ?? '').toString().trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          categorias.sort();
          // Valor inicial do filtro
          if (!categorias.contains(categoriaSelecionada)) {
            categoriaSelecionada = '';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar produtos!'),
            backgroundColor: Colors.red,
          ),
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
          const SnackBar(
            content: Text('Produto excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        buscarProdutos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir produto!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  Future<void> atualizarProduto(int id, Map<String, dynamic> dados) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/produtos/$id'),
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
                Text("Produto atualizado com sucesso!"),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        buscarProdutos();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text("Erro ao atualizar produto!"),
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
              Text("Erro de conexão!"),
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

  void aplicarFiltros() {
    final idText = idController.text.trim();
    final id = int.tryParse(idText);

    setState(() {
      produtosFiltrados = produtos.where((p) {
        final categoriaOk = (categoriaSelecionada == null || categoriaSelecionada!.isEmpty)
            ? true
            : p['categoria'] == categoriaSelecionada;
        final idOk = (idText.isEmpty)
            ? true
            : p['idProdutos'] == id;
        return categoriaOk && idOk;
      }).toList();
    });
  }

  void filtrarPorId() {
    aplicarFiltros();
  }

  void filtrarPorCategoria(String? categoria) {
    setState(() {
      categoriaSelecionada = categoria ?? '';
      aplicarFiltros();
    });
  }

  void abrirEdicao(Map<String, dynamic> produto) {
    final idProdutoController = TextEditingController(text: produto['idProdutos'].toString());
    final nomeController = TextEditingController(text: produto['nome']);
    final descricaoController = TextEditingController(text: produto['descricao']);
    final valorController = TextEditingController(text: produto['valor'].toString().replaceAll('.', ','));
    final quantidadeController = TextEditingController(text: produto['quantidade_estoque'].toString());
    final imagemController = TextEditingController(text: produto['imagem']);
    final categoriaController = TextEditingController(text: produto['categoria'] ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.brown.shade700,
            width: 2,
          ),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Editar Produto',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: idProdutoController,
                  readOnly: true,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'ID do Produto',
                    prefixIcon: const Icon(Icons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField('Nome', nomeController, Icons.shopping_bag),
                _buildTextField('Descrição', descricaoController, Icons.description, maxLines: 2),
                _buildTextField('Categoria', categoriaController, Icons.category),
                _buildTextField(
                  'Valor (R\$)',
                  valorController,
                  Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                    _CurrencyInputFormatter(),
                  ],
                ),
                _buildTextField(
                  'Quantidade',
                  quantidadeController,
                  Icons.inventory,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildTextField('URL da Imagem', imagemController, Icons.image),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Salvar Alterações',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    onPressed: () {
                      final valorString = valorController.text.replaceAll(',', '.');
                      final dadosAtualizados = {
                        'nome': nomeController.text,
                        'descricao': descricaoController.text,
                        'valor': double.tryParse(valorString) ?? 0.0,
                        'quantidade_estoque': int.tryParse(quantidadeController.text) ?? 0,
                        'imagem': imagemController.text,
                        'categoria': categoriaController.text,
                      };
                      Navigator.pop(context);
                      atualizarProduto(produto['idProdutos'], dadosAtualizados);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Barra superior
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Café Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    'Gerenciar Produtos',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visualize, edite ou exclua produtos do cardápio',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card de busca
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: idController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.poppins(),
                              decoration: InputDecoration(
                                labelText: 'Buscar por ID',
                                hintText: 'Digite o ID do produto',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: filtrarPorId,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            child: const Icon(Icons.search),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              idController.clear();
                              setState(() {
                                categoriaSelecionada = '';
                              });
                              buscarProdutos();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            child: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filtro por categoria
                  if (categorias.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        value: categoriaSelecionada ?? '',
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down_circle, color: Colors.brown.shade700, size: 28),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todas as categorias'),
                          ),
                          ...categorias.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(Icons.local_offer, color: Colors.brown.shade400, size: 18),
                                const SizedBox(width: 8),
                                Text(cat, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )),
                        ],
                        onChanged: filtrarPorCategoria,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por categoria',
                          labelStyle: GoogleFonts.poppins(color: Colors.brown.shade700, fontWeight: FontWeight.w600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.brown.shade300, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.brown.shade300, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.brown.shade700),
                          filled: true,
                          fillColor: Colors.brown.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.brown.shade900),
                        dropdownColor: Colors.brown.shade50,
                      ),
                    ),

                  // Lista de produtos
                  carregando
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : produtosFiltrados.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhum produto encontrado',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: produtosFiltrados.length,
                              itemBuilder: (_, index) {
                                final produto = produtosFiltrados[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10), // Menor espaçamento entre cards
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Menor raio
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Imagem do produto
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: produto['imagem'] != null && produto['imagem'].isNotEmpty
                                            ? Image.asset(
                                                produto['imagem'],
                                                width: double.infinity,
                                                height: 100, // Altura reduzida
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: double.infinity,
                                                  height: 100,
                                                  color: Colors.brown.shade100,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.brown.shade400,
                                                    size: 40,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                width: double.infinity,
                                                height: 100,
                                                color: Colors.brown.shade100,
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.brown.shade400,
                                                  size: 40,
                                                ),
                                              ),
                                      ),

                                      // Informações do produto
                                      Padding(
                                        padding: const EdgeInsets.all(10), // Menor padding
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    produto['nome'] ?? 'Sem nome',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15, // Fonte menor
                                                      color: Colors.brown.shade900,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.brown.shade100,
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Text(
                                                    'ID: ${produto['idProdutos']}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.brown.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              produto['descricao'] ?? 'Sem descrição',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.category,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  produto['categoria'] ?? 'Sem categoria',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.inventory,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Estoque: ${produto['quantidade_estoque'] ?? 0}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: (produto['quantidade_estoque'] ?? 0) <= 5
                                                        ? Colors.red.shade700
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // ALERTA DE ESTOQUE BAIXO/CRÍTICO
                                            if ((produto['quantidade_estoque'] ?? 0) <= 5)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, left: 0, right: 0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.red.shade200, width: 1),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Estoque crítico!',
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.red.shade700,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            else if ((produto['quantidade_estoque'] ?? 0) < 10)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, left: 0, right: 0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.orange.shade200, width: 1),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Estoque baixo!',
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.orange.shade700,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'R\$ ${(produto['valor'] ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    // Botão editar
                                                    Material(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(8),
                                                        onTap: () => abrirEdicao(produto),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(8),
                                                          child: Icon(
                                                            Icons.edit,
                                                            color: Colors.blue.shade700,
                                                            size: 22,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    // Botão excluir
                                                    Material(
                                                      color: Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(8),
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) => Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                                side: BorderSide(
                                                                  color: Colors.red.shade700,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                              elevation: 8,
                                                              backgroundColor: Colors.white,
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(24.0),
                                                                child: ConstrainedBox(
                                                                  constraints: BoxConstraints(
                                                                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                                                                  ),
                                                                  child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
                                                                      const SizedBox(height: 16),
                                                                      Text(
                                                                        'Excluir Produto',
                                                                        style: GoogleFonts.poppins(
                                                                          fontSize: 20,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Colors.red.shade700,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 12),
                                                                      Text(
                                                                        'Deseja realmente excluir "${produto['nome']}"?',
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
                                                                                deletarProduto(produto['idProdutos']);
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.red.shade700,
                                                                                foregroundColor: Colors.white,
                                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                                elevation: 2,
                                                                              ),
                                                                              child: const Text('Excluir'),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(8),
                                                          child: Icon(
                                                            Icons.delete,
                                                            color: Colors.red.shade700,
                                                            size: 22,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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

// Formatador para aceitar vírgula no valor monetário
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    
    if (text.isEmpty) return newValue;
    
    if (text.contains(',') && text.contains('.')) {
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        text = text.replaceAll('.', '');
      } else {
        text = text.replaceAll(',', '');
      }
    }
    
    final separatorCount = ','.allMatches(text).length + '.'.allMatches(text).length;
    if (separatorCount > 1) {
      return oldValue;
    }
    
    if (text.contains(',')) {
      final parts = text.split(',');
      if (parts.length > 1 && parts[1].length > 2) {
        text = '${parts[0]},${parts[1].substring(0, 2)}';
      }
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 1 && parts[1].length > 2) {
        text = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
