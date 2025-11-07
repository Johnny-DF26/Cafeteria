import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    imagemController.dispose();
    quantidadeController.dispose();
    avaliacaoController.dispose();
    categoriaController.dispose();
    super.dispose();
  }

  Future<void> cadastrarProduto() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    print('Tipo: ${baseUrl.runtimeType}, URL: ${baseUrl}');

    setState(() => _loading = true);

    // Converte vírgula para ponto no valor
    final valorString = valorController.text.replaceAll(',', '.');
    final valorDouble = double.tryParse(valorString) ?? 0;

    final produtoData = {
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'valor': valorDouble,
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
          const SnackBar(
            content: Text('Produto cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Barra superior igual às outras telas
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 110,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Cafe Gourmet',
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
                  // Título fora da barra
                  Text(
                    'Adicionar Novo Produto',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados para adicionar um produto ao cardápio',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card do formulário
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Nome do produto
                                TextFormField(
                                  controller: nomeController,
                                  decoration: InputDecoration(
                                    labelText: 'Nome do produto',
                                    prefixIcon: const Icon(Icons.shopping_bag),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha o nome';
                                    return null;
                                  },
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
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha a descrição';
                                    return null;
                                  },
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

                                // Quantidade em estoque
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
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Preencha a quantidade';
                                    if (int.tryParse(v) == null) return 'Quantidade inválida';
                                    return null;
                                  },
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

                                // Botão cadastrar
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade700,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 2,
                                    ),
                                    onPressed: _loading ? null : cadastrarProduto,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Cadastrar Produto',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
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
    
    // Se estiver vazio, retorna
    if (text.isEmpty) return newValue;
    
    // Remove múltiplos separadores (mantém apenas o último)
    if (text.contains(',') && text.contains('.')) {
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        text = text.replaceAll('.', '');
      } else {
        text = text.replaceAll(',', '');
      }
    }
    
    // Permite apenas um separador decimal
    final separatorCount = ','.allMatches(text).length + '.'.allMatches(text).length;
    if (separatorCount > 1) {
      return oldValue;
    }
    
    // Limita 2 casas decimais após vírgula ou ponto
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
