import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _categoryController = ScrollController();
  final ScrollController _promoController = ScrollController();
  final ScrollController _recommendController = ScrollController();
  bool _isLoading = true;

  String selectedCategory = "Todos";

  List<Map<String, dynamic>> promoItems = [];
  List<Map<String, dynamic>> recommendItems = [];
  List<Map<String, dynamic>> userFavorites = [];
  List<Map<String, dynamic>> cartItems = [];

  @override
void initState() {
  super.initState();
  fetchProdutos();
  _loadData();
  // dá tempo para o Provider nascer
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    
    if (userId != null) {
      fetchUserFavorites(userId);
    }
  });
}

Future<void> _loadData() async {
    try {
      await fetchProdutos();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final userId = userData?['id'];
      
      if (userId != null) {
        await fetchUserFavorites(userId);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================
  // API Favoritos
  // ==========================
  Future<void> fetchUserFavorites(int userId) async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.167:5000/favoritos/$userId"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          userFavorites = data
              .map((item) => {
                    'id': item['idProdutos'],
                    'idFavoritos': item['idFavoritos'],
                    'nome': item['nome'],
                    'descricao': item['descricao'],
                    'valor': item['valor'],
                    'imagem': item['imagem'],
                    'avaliacao': item['avaliacao'],
                    'categoria': item['categoria'],
                    'is_promotion': item['is_promotion'],
                  })
              .toList();
        });
      }
    } catch (e) {
      print("Erro ao carregar favoritos: $e");
    }
  }
  
  // Adicionar favoritos
  Future<void> addFavorite(int userId, int produtoId) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.167:5000/favoritos"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"Usuario_idUsuario": userId, "Produtos_idProdutos": produtoId}),
      );
      if (response.statusCode == 201) {
        print("✅ Favorito adicionado!");
        fetchUserFavorites(userId);
      }
    } catch (e) {
      print("Erro ao adicionar favorito: $e");
    }
  }

  // Remoção de favoritos
  Future<void> removeFavorite(int produtoId, int userId) async {
    try {
      final fav = userFavorites.firstWhere(
        (element) => element['id'] == produtoId,
        orElse: () => {},
      );
      if (fav.isNotEmpty) {
        final response =
            await http.delete(Uri.parse("http://192.168.0.167:5000/favoritos/${fav['idFavoritos']}"));
        if (response.statusCode == 200) {
          fetchUserFavorites(userId);
        } else {
          print("Erro ao remover favorito");
        }
      }
    } catch (e) {
      print("Erro ao remover favorito: $e");
    }
  }

  // ==========================
  // API Produtos
  // ==========================
  Future<void> fetchProdutos() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.167:5000/produtos"));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final data = rawData.map((e) => Map<String, dynamic>.from(e)).toList();
        setState(() {
          promoItems = data.where((item) => item['is_promotion'] == 1).toList();
          recommendItems = data;
        });
      }
    } catch (e) {
      print("Erro ao carregar produtos: $e");
    }
  }

  // ==========================
  // Utils
  // ==========================
  String capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  void _scroll(ScrollController controller, bool right, double screenWidth) {
    if (!controller.hasClients) return;
    final offset = right ? screenWidth * 0.5 : -screenWidth * 0.5;
    final newOffset = (controller.offset + offset).clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(newOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // ==========================
  // Build UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    // Carrega favoritos apenas se estiver vazio
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    final screenWidth = MediaQuery.of(context).size.width;
    final filteredItems = selectedCategory == "Todos"
        ? recommendItems
        : recommendItems.where((item) => item['categoria'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 232, 225),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.brown,
            ),
          )
      : CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text('Café Gourmet', style: GoogleFonts.pacifico(fontSize: 30, color: Colors.white)),
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
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 70, left: 20, bottom: 10),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text("Olá ${capitalize(userData?['nome'])} 👋",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryRow(screenWidth),
                  const SizedBox(height: 10),
                  _buildHorizontalScrollableSection(title: "Promoções", controller: _promoController, items: promoItems, userId: userId),
                  const SizedBox(height: 10),
                  _buildHorizontalScrollableSection(title: "Todos", controller: _recommendController, items: filteredItems, userId: userId),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) async {
          if (index == 0) {
            await Navigator.pushNamed(context, Routes.favorites);
          } else if (index == 1) {Navigator.pushNamed(context, Routes.cart);
          } else if (index == 2) {Navigator.pushNamed(context, Routes.order);
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

  // ==========================
  // Categorias
  // ==========================
  Widget _buildCategoryRow(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.0),
          child: Text("Categorias", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _scroll(_categoryController, false, screenWidth)),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ListView(
                  controller: _categoryController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip("Todos"),
                    _buildCategoryChip("Café"),
                    _buildCategoryChip("Doce"),
                    _buildCategoryChip("Bolo"),
                    _buildCategoryChip("Pães"),
                    _buildCategoryChip("Bebidas"),
                    _buildCategoryChip("Salgados"),
                    _buildCategoryChip("Combos"),
                  ],
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _scroll(_categoryController, true, screenWidth)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? Colors.brown.shade700 : Colors.brown.shade100,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================
  // Seção horizontal
  // ==========================
  Widget _buildHorizontalScrollableSection({
    required String title,
    required ScrollController controller,
    required List<Map<String, dynamic>> items,
    required int userId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text("Nenhum produto encontrado"),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = constraints.maxWidth / 1.8;
            return SizedBox(
              height: 280,
              child: ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (items.isEmpty) {
                    return const Text("Nenhum produto encontrado");
                  }
                  return SizedBox(width: cardWidth.clamp(200, 300), child: _buildProductCard(item, userId));
                },
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int userId) {
    final imageUrl = item["imagem"] ?? '';
    final rating = double.tryParse(item["avaliacao"]?.toString() ?? "0") ?? 0;
    final valorNum = double.tryParse((item["valor"] ?? "0").toString().replaceAll(",", ".")) ?? 0;
    final valorFormatado = valorNum.toStringAsFixed(2).replaceAll(".", ",");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.brown.shade200,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            height: 130,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                      child: IconButton(
                        icon: Icon(
                          userFavorites.any((element) => element['id'] == item['idProdutos'])
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () async {
                          final alreadyFav = userFavorites.any((element) => element['id'] == item['idProdutos']);
                          if (alreadyFav) {
                            await removeFavorite(item['idProdutos'], userId);
                          } else {
                            await addFavorite(userId, item['idProdutos']);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["nome"] ?? "Produto",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text(item["descricao"] ?? "Descrição não disponível",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 12);
                          }),
                        ),
                        
                        Text("R\$ ${(item["valor"] ?? 0).toStringAsFixed(2).replaceAll('.', ',')}",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    final produtoId = item['idProdutos'];
                    if (userId == null || produtoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erro: usuário ou produto inválido"))
                      );
                      return;
                    }

                    try {
                      final response = await http.post(
                        Uri.parse("http://192.168.0.167:5000/add_carrinho"),
                        headers: {"Content-Type": "application/json"},
                        body: json.encode({
                          "usuario_id": userId,
                          "produto_id": produtoId,
                          "quantidade": 1
                        }),
                      );

                      if (response.statusCode == 200) {
                        setState(() {
                          // padroniza 'id' no cartItems
                          final existingIndex = cartItems.indexWhere((e) => e['id'] == produtoId);
                          if (existingIndex >= 0) {
                            cartItems[existingIndex]['quantity'] = 
                                (cartItems[existingIndex]['quantity'] ?? 1) + 1;
                          } else {
                            cartItems.add({
                              ...item,
                              'id': produtoId,
                              'quantity': 1
                            });
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${item['nome']} adicionado ao carrinho!"))
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Erro ao adicionar no carrinho"))
                        );
                      }
                    } catch (e) {
                      print("Erro ao adicionar no carrinho: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erro de conexão"))
                      );
                    }
                  },
                  child: const Text("Adicionar ao Carrinho", style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
