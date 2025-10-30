import 'package:cafeteria/screens/admin/userManagement/view_user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_user_screen.dart';
import 'length_users.dart'; // ou UserService.dart, onde está fetchUserCount()

class UserManagementScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const UserManagementScreen({super.key, required this.adminData});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int userCount = 0;
  bool _loadingCount = false;


  Future<void> fetchUserCount() async {
    setState(() => _loadingCount = true);
    try {
      final count = await UserService.fetchUserCount(); // CORREÇÃO AQUI
      setState(() {
        userCount = count;
      });
    } catch (e) {
      debugPrint('Erro ao buscar quantidade de usuários: $e');
    } finally {
      setState(() => _loadingCount = false);
    }
  }

  Widget _buildTopicTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown.shade700),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.brown.shade800,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Dados do administrador recebidos no Management: ${widget.adminData}");
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Cafe Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopicTile(
                    icon: Icons.person_add,
                    label: 'Adicionar Usuário',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddUserScreen(adminData: widget.adminData),
                        ),
                      );
                    },
                  ),
                  _buildTopicTile(
                    icon: Icons.visibility,
                    label: 'Visualizar Usuários',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuscarClienteScreen(),
                        ),
                      );
                    },
                  ),
                  _buildTopicTile(
                    icon: Icons.edit,
                    label: 'Editar Usuário',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  // Quantidade de usuários
                  ListTile(
                    leading: const Icon(Icons.people_alt, color: Colors.brown),
                    title: Text(
                      'Usuários cadastrados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    trailing: _loadingCount
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.brown.shade700,
                            ),
                          )
                        : Text(
                            userCount.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.brown.shade900,
                            ),
                          ),
                    onTap: _loadingCount ? null : () => fetchUserCount(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
