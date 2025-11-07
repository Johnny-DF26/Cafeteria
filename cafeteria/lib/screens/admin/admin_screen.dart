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
                    leading: const Icon(Icons.insert_chart),
                    title: const Text('Relatório'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),

                  // Configurações do app
                  /*ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Configurações do app'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),*/

                  // Privacidade
                  ListTile(
                    leading: const Icon(Icons.shield),
                    title: const Text('Privacidade e Segurança'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),

                  // Sair
                  ListTile( 
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(context,'/choose',
                        (Route<dynamic> route) => false,
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
