import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isFav = false;
  int? favId; // idFavoritos retornado pela API (quando aplicável)
  bool _loadingFav = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavoriteState());
  }

  Future<void> _loadFavoriteState() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    if (userId == null) return;

    setState(() => _loadingFav = true);
    try {
      final resp = await http.get(Uri.parse("http://192.168.0.167:5000/favoritos/$userId"));
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
        final resp = await http.delete(Uri.parse("http://192.168.0.167:5000/favoritos/$favId"));
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
          Uri.parse("http://192.168.0.167:5000/favoritos"),
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
        Uri.parse("http://192.168.0.167:5000/add_carrinho"),
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
        title: Text("Cafeteria Gourmet", style: GoogleFonts.pacifico()),
        actions: [
          IconButton(
            icon: _loadingFav
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
            onPressed: _loadingFav ? null : _toggleFavorite,
          ),
        ],
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
                        ? Image.network(product['imagem'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200))
                        : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 80, color: Colors.grey)),
                  ),
                  // badge preço
                  Positioned(
                    left: 16,
                    top: 16,
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
                ],
              ),
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['nome']?.toString() ?? "Produto", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // avaliação se existir
                      if (product['avaliacao'] != null)
                        Row(
                          children: List.generate(5, (i) {
                            final rating = double.tryParse(product['avaliacao']?.toString() ?? "0") ?? 0;
                            return Icon(i < rating ? Icons.star : Icons.star_border, size: 16, color: Colors.amber);
                          }),
                        ),
                      const Spacer(),
                      Text(product['categoria']?.toString() ?? "", style: TextStyle(color: Colors.brown.shade700)),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _adding ? null : _addToCart,
                          icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.shopping_cart),
                          label: Text(_adding ? "Adicionando..." : "Adicionar ($quantity) - R\$ ${ (price * quantity).toStringAsFixed(2).replaceAll('.', ',') }"),
                        ),
                      ),
                    ],
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
        Navigator.pushNamed(context, Routes.cart);
      } else if (index == 2) {
        Navigator.pushNamed(context, Routes.order);
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrinho'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
    ],
  ),
    );
  }
}