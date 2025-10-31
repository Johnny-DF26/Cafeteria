import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../global/global.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../global/user_provider.dart';
import 'package:provider/provider.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final double shippingFee = 4.0; // frete fixo
  List<Map<String, dynamic>> cartItems = [];

  @override
  void didChangeDependencies() {
  super.didChangeDependencies();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userData = userProvider.userData;
  final userId = userData?['id'];

  fetchCartItems(userId);
}


  // Visualizar os produtos no carrinho
  Future<void> fetchCartItems(int? userId) async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.0.167:5000/get_carrinho/$userId"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data.map((item) => {
            'idCarrinho_Produtos': item['id'],       // PK da tabela Carrinho_Produtos
            'Carrinho_idCarrinho': item['carrinho_id'], // precisa existir no mapa!
            'id': item['produto_id'],                // ID do produto
            'name': item['nome'],
            'description': item['descricao'],
            'price': item['valor'],
            'image': item['imagem'],
            'quantity': item['quantidade'],
          }).toList();
        });

      } else {
        print("Erro ao buscar carrinho: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao buscar carrinho: $e");
    }
  }

  // Atualizar o carrinho no botão
  Future<void> updateCartItemQuantity(int cartProdId, int quantity) async {
  try {
    final response = await http.post(
      Uri.parse("http://192.168.0.167:5000/update_carrinho"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "idCarrinho_Produtos": cartProdId,
        "quantidade": quantity,
      }),
    );

    if (response.statusCode == 200) {
      //print("Quantidade atualizada com sucesso");
    } else {
      print("Erro ao atualizar quantidade: ${response.statusCode}");
    }
  } catch (e) {
    print("Erro ao atualizar quantidade: $e");
  }
}

  //Remover a quatidade do carrinho_produto (-)
  Future<void> removeCartItem(int cartProdId) async {
    try {
      final response = await http.delete(
        Uri.parse("http://192.168.0.167:5000/remove_unidade_carrinho/$cartProdId"),
      );
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['idCarrinho_Produtos'] == cartProdId);
        });
      } else {
        print("Erro ao remover item do carrinho: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao remover item do carrinho: $e");
    }
  }

  //Remover tudo do Carrinho
  Future<void> removeAllOfThisProduct(int carrinhoId, int produtoId) async {
  try {
    final response = await http.post(
      Uri.parse("http://192.168.0.167:5000/remove_produto_carrinho"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "carrinho_id": carrinhoId,
        "produto_id": produtoId,
      }),
    );

    if (response.statusCode == 200) {
      print("Produto removido do carrinho com sucesso");

      final userId = Provider.of<UserProvider>(context, listen: false).userData?['id'];
      await fetchCartItems(userId); // 👈 recarrega certo
    } else {
      print("Erro ao remover produto: ${response.statusCode}");
    }
  } catch (e) {
    print("Erro ao remover produto: $e");
  }
}

  
  // Calculadora
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
      backgroundColor: Color.fromARGB(255, 248, 232, 225),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Café Gourmet',
          style: GoogleFonts.pacifico(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), 
              child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              iconSize: 30,
              onPressed: () => Navigator.pushNamed(context, Routes.profile),
            ),
          ),
        ],
      ),
      
      body: cartItems.isEmpty
          ? const Center(child: Text("Seu carrinho está vazio", style: TextStyle(fontSize: 18)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Carrinho",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(cartItems.length, (index) {
                      final item = cartItems[index];
                      bool isSmall = screenWidth < 500;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: isSmall
                              ? Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item['image'] != null && item['image'].isNotEmpty
                                          ? Image.asset(item['image'], width: double.infinity, height: 180, fit: BoxFit.cover)
                                          : Container(
                                              width: double.infinity,
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildCartItemInfo(item, index),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item['image'] != null && item['image'].isNotEmpty
                                          ? Image.asset(item['image'], width: screenWidth * 0.35, height: 180, fit: BoxFit.cover)
                                          : Container(
                                              width: screenWidth * 0.35,
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildCartItemInfo(item, index)),
                                  ],
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
            color: Colors.brown.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("R\$ ${calculateTotal().toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Frete", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("R\$ ${shippingFee.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("R\$ ${(calculateTotal() + shippingFee).toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (cartItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Carrinho vazio! Adicione itens antes de prosseguir."),
                          backgroundColor: Colors.redAccent, 
                          duration: Duration(seconds: 2)));
                      } else {
                        Navigator.pushNamed(context, Routes.payment);
                      }
                    },
                    child: const Text("Pagamento", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold)),
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
              if (index == 0) {await Navigator.pushNamed(context, Routes.favorites);
              } else if (index == 1) {Navigator.pushNamed(context, Routes.home);
              } else if (index == 2) {Navigator.pushNamed(context, Routes.order);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item["name"] ?? "Produto", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(item["description"] ?? "", style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.brown),
                  onPressed: () {
                    if (item["quantity"] > 1) {
                      setState(() {
                        item["quantity"]--;});
                      updateCartItemQuantity(item['idCarrinho_Produtos'], item["quantity"]);
                    }else {
                      removeAllOfThisProduct(item['Carrinho_idCarrinho'], item['id']);
                      
                    }
                  },
                ),
                Text("${item["quantity"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.brown),
                  onPressed: () {
                    if (item["quantity"] >= 1) {
                      setState(() {
                        item["quantity"]++;
                      });
                      updateCartItemQuantity(item['idCarrinho_Produtos'], item["quantity"]);
                    }
                  },

                ),
              ],
            ),
            Text(
              "R\$ ${(double.tryParse(item['price'].toString()) ?? 0 * (item['quantity'] ?? 1)).toStringAsFixed(2).replaceAll('.', ',')}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown.shade700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
            final cartProdId = item['Carrinho_idCarrinho'];
            final produtoId = item['id'];

            if (cartProdId != null && produtoId != null) {
              removeAllOfThisProduct(cartProdId, produtoId);
            }},
            child: const Text(
              "Remover do carrinho",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
