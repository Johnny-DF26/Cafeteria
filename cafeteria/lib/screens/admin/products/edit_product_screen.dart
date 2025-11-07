import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool salvando = false;

  @override
  void dispose() {
    idController.dispose();
    nomeController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    imagemController.dispose();
    quantidadeController.dispose();
    categoriaController.dispose();
    super.dispose();
  }

  Future<void> buscarProduto() async {
    final id = idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o ID do produto')),
      );
      return;
    }

    setState(() => carregando = true);
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/produtos/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          nomeController.text = data['nome'] ?? '';
          descricaoController.text = data['descricao'] ?? '';
          // Converte ponto para vírgula para exibição
          valorController.text = data['valor'].toString().replaceAll('.', ',');
          imagemController.text = data['imagem'] ?? '';
          quantidadeController.text = data['quantidade_estoque'].toString();
          categoriaController.text = data['categoria'] ?? '';
          produtoCarregado = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto carregado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto não encontrado.'),
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

  Future<void> atualizarProduto() async {
    FocusScope.of(context).unfocus();
    final id = idController.text.trim();
    if (!_formKey.currentState!.validate() || id.isEmpty) return;

    setState(() => salvando = true);

    // Converte vírgula para ponto no valor
    final valorString = valorController.text.replaceAll(',', '.');
    final valorDouble = double.tryParse(valorString) ?? 0;

    final body = {
      'nome': nomeController.text.trim(),
      'descricao': descricaoController.text.trim(),
      'valor': valorDouble,
      'imagem': imagemController.text.trim(),
      'quantidade_estoque': int.tryParse(quantidadeController.text) ?? 0,
      'categoria': categoriaController.text.trim(),
    };

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/produtos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }

    setState(() => salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Barra superior
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 120,
            automaticallyImplyLeading: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Cafe Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 32,
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
                  // Título fora da barra
                  Text(
                    'Editar Produto',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Busque o produto pelo ID e edite as informações',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card de busca
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.blue.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Buscar Produto',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.brown.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Campo ID
                              TextFormField(
                                controller: idController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'ID do Produto',
                                  hintText: 'Digite o ID',
                                  prefixIcon: const Icon(Icons.tag),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Botão buscar
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: carregando
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.search),
                                  label: Text(
                                    carregando ? 'Buscando...' : 'Buscar Produto',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 2,
                                  ),
                                  onPressed: carregando ? null : buscarProduto,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Formulário de edição (aparece após buscar)
                  if (produtoCarregado) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color: Colors.orange.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Dados do Produto',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.brown.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Nome
                                  TextFormField(
                                    controller: nomeController,
                                    decoration: InputDecoration(
                                      labelText: 'Nome do produto',
                                      prefixIcon: const Icon(Icons.shopping_bag),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Preencha o nome'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Descrição
                                  TextFormField(
                                    controller: descricaoController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Descrição',
                                      prefixIcon: const Icon(Icons.description),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignLabelWithHint: true,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Preencha a descrição'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Categoria
                                  TextFormField(
                                    controller: categoriaController,
                                    decoration: InputDecoration(
                                      labelText: 'Categoria',
                                      hintText: 'Ex: Café, Doces, Salgados',
                                      prefixIcon: const Icon(Icons.category),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Valor com formatação
                                  TextFormField(
                                    controller: valorController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                                      _CurrencyInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Valor (R\$)',
                                      hintText: '0,00',
                                      prefixIcon: const Icon(Icons.attach_money),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Preencha o valor';
                                      final valorConvertido = v.replaceAll(',', '.');
                                      if (double.tryParse(valorConvertido) == null) {
                                        return 'Valor inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Quantidade
                                  TextFormField(
                                    controller: quantidadeController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Quantidade em estoque',
                                      prefixIcon: const Icon(Icons.inventory),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Preencha a quantidade'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // URL da imagem
                                  TextFormField(
                                    controller: imagemController,
                                    decoration: InputDecoration(
                                      labelText: 'URL da imagem',
                                      hintText: 'https://...',
                                      prefixIcon: const Icon(Icons.image),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Preencha a URL';
                                      if (!v.startsWith('http')) return 'URL inválida';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Botão salvar
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: salvando
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(
                                        salvando ? 'Salvando...' : 'Salvar Alterações',
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
                                      onPressed: salvando ? null : atualizarProduto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
