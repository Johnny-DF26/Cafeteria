import 'package:flutter/material.dart';
import '../../core/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/admin/products/products.dart';
import 'package:cafeteria/screens/admin/userManagement/user_management_screen.dart';
import 'package:cafeteria/screens/admin/recommend/view_delete_promotion_screen.dart';
import 'package:cafeteria/screens/admin/cupom/view_delete_screen.dart';
import 'package:cafeteria/screens/admin/orders/order_admin_screen.dart';


class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminScreen({super.key, required this.adminData});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    // Pegando nome e email passados no login
    print('Login com sucesso no AdminScreen: ${widget.adminData}');
    final nome = widget.adminData['nome'] ?? 'Administrador';
    final email = widget.adminData['email'] ?? 'Sem e-mail';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Barra superior fixa
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 60,
            automaticallyImplyLeading: false,
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

          // Conteúdo da tela de perfil
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.brown.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nome e email (vindos do adminData)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          nome,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Configurações
                  Text(
                    'Administração',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Cadastro de usuários
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Cadastro de Usuários'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserManagementScreen(adminData: widget.adminData),
                        ),
                      );
                    },
                  ),

                  // Produtos
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Produtos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductsScreen(adminData: widget.adminData),
                        ),
                      );
                    },
                  ),

                  // Pedidos
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Pedidos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderAdminScreen(),
                        ),
                      );},
                  ),

                  // Recomendações
                  ListTile(
                    leading: const Icon(Icons.recommend),
                    title: const Text('Recomendações'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewDeletePromotionScreen(adminData: widget.adminData),
                        ),
                      );
                    },
                  ),

                  // Cupons
                  ListTile(
                    leading: const Icon(Icons.local_offer),
                    title: const Text('Cupons'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewDeleteCouponScreen(adminId: widget.adminData['id']),
                        ),
                      );
                    },
                  ),

                  // Relatório
                  ListTile(
                    leading: Icon(Icons.insert_chart, color: Colors.grey.withOpacity(0.5)),
                    title: Text(
                      'Relatório',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.5),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.withOpacity(0.8)),
                    onTap: () {},
                  ),

                  // Configurações do app
                  /*ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Configurações do app'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),

                  // Privacidade
                  ListTile(
                    leading: const Icon(Icons.shield),
                    title: const Text('Privacidade e Segurança'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),*/

                  // Sair
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade700),
                    title: Text(
                      'Sair',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red.shade400),
                    tileColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Deseja realmente sair?', style: TextStyle(color: Colors.red.shade700)),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text('Sair'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamedAndRemoveUntil(context, '/choose', (route) => false);
                              },
                            ),
                          ],
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
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade200.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      ),
    );
  }
}
