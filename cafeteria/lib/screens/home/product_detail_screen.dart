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
      // falha silenciosa; botão continuará disponível
    } finally {
      setState(() => _loadingFav = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuário não autenticado")));
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao remover favorito")));
        }
      } else {
        final resp = await http.post(
          Uri.parse("$baseUrl/favoritos"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"Usuario_idUsuario": userId, "Produtos_idProdutos": widget.product['idProdutos']}),
        );
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          // tenta recarregar para obter idFavoritos
          await _loadFavoriteState();
          setState(() => isFav = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao adicionar favorito")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro de conexão")));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuário ou produto inválido")));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.product['nome']} adicionado ao carrinho")));
        Navigator.pushNamed(context, Routes.cart);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao adicionar ao carrinho")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro de conexão")));
    } finally {
      setState(() => _adding = false);
    }
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

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 232, 225),
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
            // imagem principal
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product['imagem'] != null && product['imagem'].toString().isNotEmpty
                        ? Image.asset(product['imagem'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200))
                        : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 80, color: Colors.grey)),
                  ),
                  // badge preço - movido para inferior direito
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade700.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Text('R\$ $priceStr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  // botão favorito - superior direito
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(166, 255, 255, 255),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: IconButton(
                        icon: _loadingFav
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown))
                            : Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 28),
                        onPressed: _loadingFav ? null : _toggleFavorite,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['nome']?.toString() ?? "Produto", 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        product['categoria']?.toString() ?? "",
                        style: TextStyle(color: Colors.brown.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // avaliação
                      Row(
                        children: List.generate(5, (i) {
                          final rating = double.tryParse(product['avaliacao']?.toString() ?? "0") ?? 0;
                          return Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border, 
                            size: 18, 
                            color: Colors.amber.shade700
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${product['avaliacao']?.toString() ?? ''}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product['descricao']?.toString() ?? "Sem descrição", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 20),

                  // quantidade + ações
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                            ),
                            Text(quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700, 
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _adding ? null : _addToCart,
                          icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.shopping_cart),
                          label: Text(
                            _adding ? "Adicionando..." : "Adicionar - R\$ ${(price * quantity).toStringAsFixed(2).replaceAll('.', ',')}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // campo de observação
                  const Text(
                    "Observações",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observationController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ex: Sem açúcar, extra quente, etc.",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
    selectedItemColor: Colors.brown.shade700,
    unselectedItemColor: Colors.grey,
    currentIndex: 1, // Carrinho ativo
    onTap: (index) async {
      if (index == 0) {
        Navigator.pushNamed(context, Routes.favorites);
      } else if (index == 1) {
        Navigator.pushNamed(context, Routes.home);
      } else if (index == 2) {
        Navigator.pushNamed(context, Routes.order);
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
    ],
  ),
    );
  }
}