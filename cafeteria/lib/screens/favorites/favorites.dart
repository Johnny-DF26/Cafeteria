import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../global/global.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../global/user_provider.dart';
import 'package:provider/provider.dart';


class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoanding = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // Buscar Favoritos
  Future<void> fetchFavorites() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userProvider.userData?['id'];
    //print('Seus dados ${userData?['nome']} chegou em Home: $userData');

    if (userId == null) return;  // Como eu chamo a variavel que esta no construtor

    try {
      final response = await http.get(Uri.parse("http://192.168.0.167:5000/favoritos/$userId"));
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
        print("Erro ao buscar favoritos: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao buscar favoritos: $e");
    }
  }

  // Remover Favoritos,
  Future<void> removeFavorite(int favId) async {
    try {
      final response = await http.delete(Uri.parse("http://192.168.0.167:5000/favoritos/$favId"));
      if (response.statusCode == 200) {
        setState(() {
          favorites.removeWhere((element) => element['idFavoritos'] == favId);
        });
      }
    } catch (e) {
      print("Erro ao remover favorito: $e");
    }
  }

  // Adicionar no Carrinho
  Future<void> addToCart(Map<String, dynamic> item) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userData?['id'];  // Como eu vou trazer para cá <------
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.167:5000/add_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "usuario_id": userId,
          "produto_id": item['id'],
          "quantidade": 1,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        //print("API retornou: $result");

        setState(() {
          final existingIndex = cartItems.indexWhere((e) => e['id'] == item['id']);
          if (existingIndex >= 0) {
            cartItems[existingIndex]['quantity']++;
          } else {
            cartItems.add({...item, 'quantity': 1});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item['nome']} adicionado ao carrinho!")),
        );
      } else {
        print("Erro ao adicionar no carrinho: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar no carrinho")),
        );
      }
    } catch (e) {
      print("Erro ao adicionar no carrinho: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao adicionar no carrinho")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;  // Sendo que a variavel foi crianda dentro da build
    final screenWidth = MediaQuery.of(context).size.width;
    //print('Seus dados chegou aqui ${userData?['name']}: $userData');
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 248, 232, 225),

      // ==========================
      // AppBar igual CartScreen
      // ==========================
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

      // ==========================
      // Corpo da tela de favoritos
      // ==========================
      body: favorites.isEmpty
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
                    Text(
                      "Favoritos",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0),
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
                                          ? Image.network(
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
                                          ? Image.network(
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
            ),

      // ==========================
      // Bottom navigation
      // ==========================
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) async {
        if (index == 0) {await Navigator.pushNamed(context, Routes.cart);
        } else if (index == 1) {Navigator.pushNamed(context, Routes.home);
        } else if (index == 2) {Navigator.pushNamed(context, Routes.order);
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
              "R\$ ${item['valor']?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}",
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
