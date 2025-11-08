import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:cafeteria/screens/home/product_detail_screen.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

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

  late final PageController _promoPageController;
  int _promoIndex = 0;

  @override
  void initState() {
    super.initState();
    _promoPageController = PageController(viewportFraction: 0.88);
    fetchProdutos();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      //print('Login com sucesso no Home: ${userData}');
      final userId = userData?['id'];
      if (userId != null) {
        fetchUserFavorites(userId);
      }
    });
  }

  @override
  void dispose() {
    _promoPageController.dispose();
    _categoryController.dispose();
    _promoController.dispose();
    _recommendController.dispose();
    super.dispose();
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
      final response = await http.get(Uri.parse("$baseUrl/favoritos/$userId"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
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
      }
    } catch (e) {
      print("⚠️ Erro ao carregar favoritos: $e");
    }
  }

  Future<void> addFavorite(int userId, int produtoId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/favoritos"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"Usuario_idUsuario": userId, "Produtos_idProdutos": produtoId}),
      );
      if (response.statusCode == 201) {
        fetchUserFavorites(userId);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Produto adicionado aos favoritos!"),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text("Erro ao adicionar favorito!"),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> removeFavorite(int produtoId, int userId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final fav = userFavorites.firstWhere(
        (element) => element['id'] == produtoId,
        orElse: () => {},
      );
      if (fav.isNotEmpty) {
        final response = await http.delete(Uri.parse("$baseUrl/favoritos/${fav['idFavoritos']}"));
        if (response.statusCode == 200) {
          fetchUserFavorites(userId);
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Produto removido dos favoritos!"),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print("⚠️ Erro ao remover favorito: $e");
    }
  }

  // ==========================
  // API Produtos
  // ==========================
  Future<void> fetchProdutos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/produtos"));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        final data = rawData.map((e) => Map<String, dynamic>.from(e)).toList();
        if (mounted) {
          setState(() {
            // Filtra apenas produtos com estoque > 0
            promoItems = data.where((item) => item['is_promotion'] == 1 && (item['quantidade_estoque'] ?? 0) > 0).toList();
            recommendItems = data.where((item) => (item['quantidade_estoque'] ?? 0) > 0).toList();
          });
        }
      }
    } catch (e) {
      print("⚠️ Erro ao carregar produtos: $e");
    }
  }

  // ==========================
  // Utils
  // ==========================
  String capitalize(String s) {
    if (s.isEmpty) return '';
    // Pega apenas o primeiro nome
    final firstName = s.split(' ').first;
    return firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
  }

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
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;
    final userId = userData?['id'];
    final screenWidth = MediaQuery.of(context).size.width;
    final filteredItems = (selectedCategory == "Todos"
    ? recommendItems
    : recommendItems.where((item) => item['categoria'] == selectedCategory).toList())
    .where((item) => (item['quantidade_estoque'] ?? 0) > 0).toList();
    //print(recommendItems.map((e) => '${e['nome']}: ${e['quantidade_estoque']}').toList());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.brown.shade700,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Carregando catálogo...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 110,
                  backgroundColor: Colors.brown.shade700,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Café Gourmet',
                    style: GoogleFonts.pacifico(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        iconSize: 28,
                        onPressed: () => Navigator.pushNamed(context, Routes.profile),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.brown.shade800,
                            Colors.brown.shade600,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 70, left: 20, bottom: 10),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              "Olá, ${capitalize(userData?['nome'] ?? 'Visitante')} 👋",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ...existing code...
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promoItems.isNotEmpty) ...[
                          _buildPromoCarousel(
                            title: "🔥 Promoções Especiais",
                            items: promoItems,
                            userId: userId,
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: 5),
                        ],
                        // Mova o filtro de categorias para cá
                        _buildCategoryRow(screenWidth),
                        const SizedBox(height: 10),
                        _buildHorizontalScrollableSection(
                          title: "☕ Nossos Produtos",
                          controller: _recommendController,
                          items: filteredItems,
                          userId: userId,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
          onTap: (index) async {
            if (index == 0) {
              await Navigator.pushNamed(context, Routes.favorites);
            } else if (index == 0) {
              // Já estamos na home
            } else if (index == 1) {
              Navigator.pushNamed(context, Routes.cart);
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
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Carrinho',
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

  // ==========================
  // Carrossel de Promoções
  // ==========================
  Widget _buildPromoCarousel({
    required String title,
    required List<Map<String, dynamic>> items,
    required int? userId,
    required double screenWidth,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _promoPageController,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _promoIndex = i),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildPromoCard(item, userId ?? -1, index);
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              items.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _promoIndex == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _promoIndex == i ? Colors.brown.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> item, int userId, int index) {
    final imageUrl = (item["imagem"] ?? '').toString();
    final name = item["nome"] ?? '-';
    final desc = item["descricao"] ?? '';
    final rating = double.tryParse(item["avaliacao"]?.toString() ?? "0") ?? 0;
    final valorNum = double.tryParse((item["valor"] ?? "0").toString().replaceAll(",", ".")) ?? 0;
    final valorFormatado = valorNum.toStringAsFixed(2).replaceAll(".", ",");
    final isFavorite = userFavorites.any((element) => element['id'] == item['idProdutos']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        shadowColor: Colors.brown.shade200,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 40,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: imageUrl.isNotEmpty
                          ? Image.asset(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: Icon(Icons.coffee, size: 80, color: Colors.grey.shade400),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Icon(Icons.coffee, size: 80, color: Colors.grey.shade400),
                            ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade700, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "PROMOÇÃO",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(142, 255, 255, 255),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red.shade600,
                            size: 26,
                          ),
                          onPressed: () async {
                            if (isFavorite) {
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
              ),
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.brown.shade900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "R\$ $valorFormatado",
                            style: GoogleFonts.poppins(
                              color: Colors.brown.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.brown.shade700, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: Colors.brown.shade700,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: item),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_rounded, size: 20),
                              label: Text(
                                'Detalhes',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 6,
                                shadowColor: Colors.brown.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => _addToCart(item, userId),
                              icon: const Icon(Icons.shopping_cart_rounded, size: 20, color: Colors.white),
                              label: Text(
                                'Adicionar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            "🏷️ Categorias",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            controller: _categoryController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.brown.shade800, Colors.brown.shade600],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.brown.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.brown.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.brown.shade800,
          ),
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
    required int? userId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.coffee_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhum produto encontrado",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 380,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              padding: const EdgeInsets.only(left: 4, right: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 280,
                  child: _buildProductCard(item, userId ?? -1),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int userId) {
    if ((item['quantidade_estoque'] ?? 0) <= 0) return const SizedBox.shrink();

    final imageUrl = item["imagem"] ?? '';
    final rating = double.tryParse(item["avaliacao"]?.toString() ?? "0") ?? 0;
    final valorNum = double.tryParse((item["valor"] ?? "0").toString().replaceAll(",", ".")) ?? 0;
    final valorFormatado = valorNum.toStringAsFixed(2).replaceAll(".", ",");
    final isFavorite = userFavorites.any((element) => element['id'] == item['idProdutos']);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.brown.shade200,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.brown.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl.isNotEmpty
                        ? Image.asset(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.coffee, size: 70, color: Colors.grey.shade400),
                            ),
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: Icon(Icons.coffee, size: 70, color: Colors.grey.shade400),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(99, 255, 255, 255),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red.shade600,
                          size: 24,
                        ),
                        onPressed: () async {
                          if (isFavorite) {
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["nome"] ?? "Produto",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown.shade900,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["descricao"] ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber.shade700, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "R\$ $valorFormatado",
                            style: GoogleFonts.poppins(
                              color: Colors.brown.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.brown.shade700, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: Colors.brown.shade700,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: item),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_rounded, size: 20),
                              label: Text(
                                'Detalhes',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _addToCart(item, userId),
                              icon: const Icon(Icons.shopping_cart_rounded, size: 20, color: Colors.white),
                              label: Text(
                                'Adicionar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> item, int userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final produtoId = item['idProdutos'];

    if (userId == -1 || produtoId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Erro: usuário ou produto inválido"),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_carrinho"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "usuario_id": userId,
          "produto_id": produtoId,
          "quantidade": 1,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          final existingIndex = cartItems.indexWhere((e) => e['id'] == produtoId);
          if (existingIndex >= 0) {
            cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] ?? 1) + 1;
          } else {
            cartItems.add({...item, 'id': produtoId, 'quantity': 1});
          }
        });
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${item['nome']} adicionado ao carrinho!",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text("Erro ao adicionar no carrinho"),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print("⚠️ Erro ao adicionar no carrinho: $e");
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Erro de conexão"),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}