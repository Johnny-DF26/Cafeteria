import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'view_delete_product_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductsScreen extends StatelessWidget {
  final Map<String, dynamic> adminData;
  const ProductsScreen({super.key, required this.adminData});

  Widget _buildTopicTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.brown.shade700),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminId = adminData['id'] ?? 1;
    final adminName = adminData['nome'] ?? 'Desconhecido';
    final adminEmail = adminData['email'] ?? 'Sem email';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Barra superior igual AdminScreen
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Café Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // Conteúdo da tela
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título da tela fora da AppBar
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Gerenciar Produtos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  // Cards de navegação
                  _buildTopicTile(
                    context: context,
                    icon: Icons.add_box_outlined,
                    label: 'Adicionar novo produto',
                    iconColor: Colors.green.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(
                            adminData: {
                              'id': adminId,
                              'nome': adminName,
                              'email': adminEmail,
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _buildTopicTile(
                    context: context,
                    icon: Icons.remove_red_eye_outlined,
                    label: 'Visualizar / Editar / Excluir Produto',
                    iconColor: Colors.red.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewDeleteProductScreen(),
                        ),
                      );
                    },
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
