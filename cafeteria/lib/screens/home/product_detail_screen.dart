import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isFav = false;
  int? favId;
  bool _loadingFav = false;
  bool _adding = false;
  final TextEditingController _observationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavoriteState());
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteState() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    if (userId == null) return;

    setState(() => _loadingFav = true);
    try {
      final resp = await http.get(Uri.parse("$baseUrl/favoritos/$userId"));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        final match = data.firstWhere(
          (e) => e['idProdutos'] == widget.product['idProdutos'],
          orElse: () => null,
        );
        if (match != null) {
          setState(() {
            isFav = true;
            favId = match['idFavoritos'];
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() => _loadingFav = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    if (userId == null) {
      _showSnackBar("Usuário não autenticado", Colors.red.shade700);
      return;
    }

    setState(() => _loadingFav = true);
    try {
      if (isFav && favId != null) {
        final resp = await http.delete(Uri.parse("$baseUrl/favoritos/$favId"));
        if (resp.statusCode == 200) {
          setState(() {
            isFav = false;
            favId = null;
          });
          _showSnackBar("Removido dos favoritos", Colors.orange.shade700);
        } else {
          _showSnackBar("Erro ao remover favorito", Colors.red.shade700);
        }
      } else {
        final resp = await http.post(
          Uri.parse("$baseUrl/favoritos"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"Usuario_idUsuario": userId, "Produtos_idProdutos": widget.product['idProdutos']}),
        );
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          await _loadFavoriteState();
          setState(() => isFav = true);
          _showSnackBar("Adicionado aos favoritos!", Colors.green.shade700);
        } else {
          _showSnackBar("Erro ao adicionar favorito", Colors.red.shade700);
        }
      }
    } catch (e) {
      _showSnackBar("Erro de conexão", Colors.red.shade700);
    } finally {
      setState(() => _loadingFav = false);
    }
  }

  Future<void> _addToCart() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    final produtoId = widget.product['idProdutos'];
    if (userId == null || produtoId == null) {
      _showSnackBar("Usuário ou produto inválido", Colors.red.shade700);
      return;
    }

    setState(() => _adding = true);
    try {
      final resp = await http.post(
        Uri.parse("$baseUrl/add_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"usuario_id": userId, "produto_id": produtoId, "quantidade": quantity}),
      );
      if (resp.statusCode == 200) {
        _showSnackBar("${widget.product['nome']} adicionado!", Colors.green.shade700);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pushNamed(context, Routes.cart);
      } else {
        _showSnackBar("Erro ao adicionar ao carrinho", Colors.red.shade700);
      }
    } catch (e) {
      _showSnackBar("Erro de conexão", Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green.shade700
                  ? Icons.check_circle_rounded
                  : backgroundColor == Colors.orange.shade700
                      ? Icons.info_rounded
                      : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _parsePrice(dynamic value) {
    try {
      final s = (value ?? "0").toString().replaceAll(",", ".").replaceAll("R\$", "").trim();
      return double.tryParse(s) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = _parsePrice(product['valor']);
    final priceStr = price.toStringAsFixed(2).replaceAll('.', ',');
    final rating = double.tryParse(product['avaliacao']?.toString() ?? "0") ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Café Gourmet",
          style: GoogleFonts.pacifico(color: Colors.white, fontSize: 30),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Imagem com Hero Animation
            Hero(
              tag: 'product_${product['idProdutos']}',
              child: Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Imagem
                    Positioned.fill(
                      child: product['imagem'] != null && product['imagem'].toString().isNotEmpty
                          ? Image.asset(
                              product['imagem'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.coffee, size: 80, color: Colors.grey.shade400),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.coffee, size: 80, color: Colors.grey.shade400),
                            ),
                    ),
                    // Gradiente inferior
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge de Preço
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'R\$ $priceStr',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botão Favorito
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: _loadingFav
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.brown.shade700,
                                  ),
                                )
                              : Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red.shade600 : Colors.grey.shade600,
                                  size: 28,
                                ),
                          onPressed: _loadingFav ? null : _toggleFavorite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria
                  if (product['categoria'] != null && product['categoria'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee, size: 16, color: Colors.brown.shade700),
                          const SizedBox(width: 6),
                          Text(
                            product['categoria'].toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.brown.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Nome do Produto
                  Text(
                    product['nome']?.toString() ?? "Produto",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.brown.shade900,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Avaliação
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border,
                            size: 20,
                            color: Colors.amber.shade700,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descrição
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, size: 20, color: Colors.brown.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "Descrição",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.brown.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product['descricao']?.toString() ?? "Sem descrição disponível.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quantidade e Adicionar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Controle de Quantidade
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: quantity > 1 ? Colors.brown.shade700 : Colors.grey.shade400,
                                    ),
                                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                                  ),
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      quantity.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown.shade900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline, color: Colors.brown.shade700),
                                    onPressed: () => setState(() => quantity++),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Total
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.brown.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "R\$ ${(price * quantity).toStringAsFixed(2).replaceAll('.', ',')}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.brown.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Botão Adicionar ao Carrinho
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.brown.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _adding ? null : _addToCart,
                            child: _adding
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shopping_cart_rounded, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Adicionar ao Carrinho",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Observações
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note, size: 22, color: Colors.brown.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "Observações",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.brown.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _observationController,
                          maxLines: 4,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Ex: Sem açúcar, extra quente, com leite de aveia...",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.brown.shade800,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          currentIndex: 1,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          onTap: (index) {
            if (index == 0) {
              Navigator.pushNamed(context, Routes.favorites);
            } else if (index == 1) {
              Navigator.pushNamed(context, Routes.home);
            } else if (index == 2) {
              Navigator.pushNamed(context, Routes.order);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
          ],
        ),
      ),
    );
  }
}