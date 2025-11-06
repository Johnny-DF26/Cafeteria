import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../global/global.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../global/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final double shippingFee = 4.0;
  List<Map<String, dynamic>> cartItems = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    fetchCartItems(userId);
  }

  Future<void> fetchCartItems(int? userId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_carrinho/$userId"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data.map((item) => {
            'idCarrinho_Produtos': item['id'],
            'Carrinho_idCarrinho': item['carrinho_id'],
            'id': item['produto_id'],
            'name': item['nome'],
            'description': item['descricao'],
            'price': item['valor'],
            'image': item['imagem'],
            'quantity': item['quantidade'],
          }).toList();
        });
      } else {
        print("⚠️ Erro ao buscar carrinho: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Erro ao buscar carrinho: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> updateCartItemQuantity(int cartProdId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "idCarrinho_Produtos": cartProdId,
          "quantidade": quantity,
        }),
      );
      if (response.statusCode != 200) {
        print("⚠️ Erro ao atualizar quantidade: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Erro ao atualizar quantidade: $e");
    }
  }

  Future<void> removeCartItem(int cartProdId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/remove_unidade_carrinho/$cartProdId"),
      );
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['idCarrinho_Produtos'] == cartProdId);
        });
      } else {
        print("⚠️ Erro ao remover item do carrinho: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Erro ao remover item do carrinho: $e");
    }
  }

  Future<void> removeAllOfThisProduct(int carrinhoId, int produtoId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/remove_produto_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "carrinho_id": carrinhoId,
          "produto_id": produtoId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Produto removido do carrinho'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        final userId = Provider.of<UserProvider>(context, listen: false).userData?['id'];
        await fetchCartItems(userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao remover produto'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print("⚠️ Erro ao remover produto: $e");
    }
  }

  Future<void> _showRemoveDialog(Map<String, dynamic> item) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Remover Item",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade900,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Deseja remover este item do carrinho?",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item['image'] != null && item['image'].isNotEmpty
                          ? Image.asset(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.coffee, color: Colors.grey.shade500, size: 24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? "Produto",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Quantidade: ${item['quantity']}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Cancelar", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text("Remover", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              onPressed: () {
                Navigator.of(context).pop();
                final cartId = item['Carrinho_idCarrinho'];
                final prodId = item['id'];
                if (cartId != null && prodId != null) {
                  removeAllOfThisProduct(cartId, prodId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  double calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0;
      total += price * (item['quantity'] ?? 1);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Café Gourmet',
          style: GoogleFonts.pacifico(
            fontSize: 30,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black26, offset: const Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 28),
              onPressed: () => Navigator.pushNamed(context, Routes.profile),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.brown.shade700, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    "Carregando carrinho...",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                      const SizedBox(height: 24),
                      Text(
                        "Seu carrinho está vazio",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Adicione produtos para começar",
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.home),
                        label: Text("Explorar Produtos", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => Navigator.pushNamed(context, Routes.home),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.shopping_cart, color: Colors.brown.shade700, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Meu Carrinho",
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.brown.shade900,
                                  ),
                                ),
                                Text(
                                  "${cartItems.length} ${cartItems.length == 1 ? 'item' : 'itens'}",
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(cartItems.length, (index) {
                          final item = cartItems[index];
                          bool isSmall = screenWidth < 500;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            shadowColor: Colors.brown.shade100,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Colors.brown.shade50.withOpacity(0.3)],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: isSmall
                                    ? Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: item['image'] != null && item['image'].isNotEmpty
                                                ? Image.asset(item['image'], width: double.infinity, height: 200, fit: BoxFit.cover)
                                                : Container(
                                                    width: double.infinity,
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.grey.shade200, Colors.grey.shade300],
                                                      ),
                                                    ),
                                                    child: Icon(Icons.coffee, size: 60, color: Colors.grey.shade400),
                                                  ),
                                          ),
                                          const SizedBox(height: 16),
                                          _buildCartItemInfo(item, index),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: item['image'] != null && item['image'].isNotEmpty
                                                ? Image.asset(item['image'], width: screenWidth * 0.35, height: 220, fit: BoxFit.cover)
                                                : Container(
                                                    width: screenWidth * 0.35,
                                                    height: 220,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.grey.shade200, Colors.grey.shade300],
                                                      ),
                                                    ),
                                                    child: Icon(Icons.coffee, size: 60, color: Colors.grey.shade400),
                                                  ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(child: _buildCartItemInfo(item, index)),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Subtotal",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                    Text(
                      "R\$ ${calculateTotal().toStringAsFixed(2).replaceAll('.', ',')}",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Frete",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                    Text(
                      "R\$ ${shippingFee.toStringAsFixed(2).replaceAll('.', ',')}",
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        "R\$ ${(calculateTotal() + shippingFee).toStringAsFixed(2).replaceAll('.', ',')}",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.brown.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (cartItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.warning, color: Colors.white),
                                SizedBox(width: 8),
                                Text("Carrinho vazio! Adicione itens antes de prosseguir."),
                              ],
                            ),
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, Routes.payment);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "Ir para Pagamento",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
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
          BottomNavigationBar(
            selectedItemColor: Colors.brown.shade700,
            unselectedItemColor: Colors.grey,
            currentIndex: 1,
            onTap: (index) async {
              if (index == 0) {
                await Navigator.pushNamed(context, Routes.favorites);
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
        ],
      ),
    );
  }

  Widget _buildCartItemInfo(Map<String, dynamic> item, int index) {
    double price = double.tryParse(item['price'].toString()) ?? 0;
    double totalItem = price * (item['quantity'] ?? 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item["name"] ?? "Produto",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.brown.shade900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          item["description"] ?? "",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              " x ${item['quantity']}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Total: R\$ ${totalItem.toStringAsFixed(2).replaceAll('.', ',')}",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.brown.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    color: Colors.orange.shade700,
                    onPressed: () {
                      if (item["quantity"] > 1) {
                        setState(() {
                          item["quantity"]--;
                        });
                        updateCartItemQuantity(item['idCarrinho_Produtos'], item["quantity"]);
                      } else {
                        _showRemoveDialog(item);
                      }
                    },
                    padding: const EdgeInsets.all(8),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${item["quantity"]}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.brown.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: Colors.green.shade700,
                    onPressed: () {
                      setState(() {
                        item["quantity"]++;
                      });
                      updateCartItemQuantity(item['idCarrinho_Produtos'], item["quantity"]);
                    },
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
              onPressed: () => _showRemoveDialog(item),
              tooltip: "Remover item",
            ),
          ],
        ),
      ],
    );
  }
}
