import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreen();
}

class _PhoneScreen extends State<PhoneScreen> {
  int _currentIndex = 1; // Exemplo: começa na Home

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: CustomScrollView(
        slivers: [
          // Barra superior (igual às telas do app)
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            iconTheme: const IconThemeData(color: Colors.white),
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

          // Aqui é o espaço onde você vai construir a nova tela
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(
                  'Conteúdo da nova tela aqui',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Barra inferior (igual às outras telas)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushNamed(context, Routes.cart);
          } else if (index == 1) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 2) {
            Navigator.pushNamed(context, Routes.order);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrinho',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }
}
