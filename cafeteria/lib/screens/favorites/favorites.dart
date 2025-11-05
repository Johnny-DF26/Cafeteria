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

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // Buscar Favoritos
  Future<void> fetchFavorites() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['id'];

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse("$baseUrl/favoritos/$userId"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          favorites = data.map((item) => {
                'id': item['idProdutos'],
                'idFavoritos': item['idFavoritos'],
                'nome': item['nome'],
                'descricao': item['descricao'],
                'valor': item['valor'],
                'imagem': item['imagem'],
                'avaliacao': item['avaliacao'],
                'categoria': item['categoria'],
                'is_promotion': item['is_promotion'],
              }).toList();
        });
      } else {
        print("⚠️ Erro ao buscar favoritos: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Erro ao buscar favoritos: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Remover Favoritos
  Future<void> removeFavorite(int favId) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/favoritos/$favId"));
      if (response.statusCode == 200) {
        setState(() {
          favorites.removeWhere((element) => element['idFavoritos'] == favId);
        });
      }
    } catch (e) {
      print("⚠️ Erro ao remover favorito: $e");
    }
  }

  // Adicionar no Carrinho
  Future<void> addToCart(Map<String, dynamic> item) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['id'];
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "usuario_id": userId,
          "produto_id": item['id'],
          "quantidade": 1,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        setState(() {
          final existingIndex = cartItems.indexWhere((e) => e['id'] == item['id']);
          if (existingIndex >= 0) {
            cartItems[existingIndex]['quantity']++;
          } else {
            cartItems.add({...item, 'quantity': 1});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${item['nome']} adicionado ao carrinho!")),
        );
      } else {
        print("Erro ao adicionar no carrinho: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Erro ao adicionar no carrinho")),
        );
      }
    } catch (e) {
      print("⚠️ Erro ao adicionar no carrinho: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao adicionar no carrinho")),
      );
    }
  }

  String _formatPrice(dynamic valor) {
    if (valor == null) return "0,00";
    double v;
    if (valor is num) {
      v = valor.toDouble();
    } else {
      v = double.tryParse(valor.toString()) ?? 0.0;
    }
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 232, 225),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (favorites.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum favorito encontrado.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Favoritos",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(favorites.length, (index) {
                          final item = favorites[index];
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
                                          child: item['imagem'] != null && item['imagem'].isNotEmpty
                                              ? Image.asset(
                                                  item['imagem'],
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, color: Colors.grey),
                                                ),
                                        ),
                                        const SizedBox(height: 10),
                                        _buildFavoriteItemInfo(item, index),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: item['imagem'] != null && item['imagem'].isNotEmpty
                                              ? Image.asset(
                                                  item['imagem'],
                                                  width: screenWidth * 0.35,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: screenWidth * 0.35,
                                                  height: 180,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, color: Colors.grey),
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildFavoriteItemInfo(item, index)),
                                      ],
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                )),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) async {
          if (index == 0) {
            await Navigator.pushNamed(context, Routes.cart);
          } else if (index == 1) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 2) {
            Navigator.pushNamed(context, Routes.order);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrinho'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
        ],
      ),
    );
  }

  Widget _buildFavoriteItemInfo(Map<String, dynamic> item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item["nome"] ?? "Produto",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item["descricao"] ?? "",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 255, 0, 0)),
                  onPressed: () async {
                    if (item['idFavoritos'] != null) {
                      await removeFavorite(item['idFavoritos']);
                    }
                  },
                ),
              ],
            ),
            Text(
              "R\$ ${_formatPrice(item['valor'])}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown.shade700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 76, 49, 49),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => addToCart(item),
            child: const Text(
              "Adicionar no carrinho",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}