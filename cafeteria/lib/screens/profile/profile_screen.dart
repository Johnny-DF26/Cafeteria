import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria/screens/global/user_provider.dart';
import '../../core/routes.dart';
import 'package:cafeteria/screens/profile/adress.dart';
import 'package:cafeteria/screens/profile/person.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 0;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {}); // força rebuild; se quiser, chame provider.fetch...
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar logout'),
        content: const Text('Deseja sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.pushNamedAndRemoveUntil(context, Routes.choose, (_) => false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) Navigator.pushNamed(context, Routes.cart);
    if (index == 1) Navigator.pushNamed(context, Routes.home);
    if (index == 2) Navigator.pushNamed(context, Routes.order);
  }

  String _formatDate(String? value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final s = value.toString();
    DateTime? dt = DateTime.tryParse(s);
    if (dt != null) return DateFormat('dd/MM/yyyy').format(dt.toLocal());
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(s);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}
    try {
      dt = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parseUtc(s).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {}
    return s;
  }

  // tenta extrair o primeiro valor não-nulo entre várias chaves possíveis
  String _pick(Map<String, dynamic>? userData, List<String> keys) {
    if (userData == null) return '-';
    for (final k in keys) {
      if (!userData.containsKey(k)) continue;
      final v = userData[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    // debug rápido quando não há dados (apenas em debug)
    if (kDebugMode && (userData == null || userData.isEmpty)) {
      // ignore: avoid_print
      print('ProfileScreen: userData vazio => $userData');
    }

    final name = _pick(userData, ['nome_completo', 'nome_social', 'nome']);
    final email = _pick(userData, ['email', 'email_usuario']);
    final img = _pick(userData, ['imagem', 'foto', 'avatar']);
    final cpf = _pick(userData, ['cpf', 'CPF', 'cpf_usuario']);
    final telefone = _pick(userData, ['telefone', 'telefone_celular', 'celular', 'fone']);
    final dataNascRaw = _pick(userData, ['data_nascimento', 'dataNascimento', 'data_nasc']);
    final dataNasc = dataNascRaw == '-' ? '-' : _formatDate(dataNascRaw);
    final isWide = MediaQuery.of(context).size.width > 600;

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrinho'),
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
    ];
    final safeIndex = (_currentIndex >= 0 && _currentIndex < navItems.length) ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.brown.shade700,
              expandedHeight: 110,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('Café Gourmet', style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.brown.shade700, Colors.brown.shade400]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (img != '-' && img.isNotEmpty) ? NetworkImage(img) as ImageProvider : null,
                      child: (img == '-' || img.isEmpty) ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 28, color: Colors.brown)) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                          const SizedBox(height: 12, width: 12),
                          Text(email != '-' ? email : '-', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                          const SizedBox(height: 12, width: 12),
                          // botões removidos conforme solicitado
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInfoCard(context, name, email, cpf, telefone, dataNasc)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSettingsCard(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildInfoCard(context, name, email, cpf, telefone, dataNasc),
                          const SizedBox(height: 12),
                          _buildSettingsCard(context),
                        ],
                      ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: safeIndex,
        onTap: _onNavTap,
        items: navItems,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.logout),
        label: const Text('Sair', style: TextStyle(color: Colors.white)),
        onPressed: _confirmLogout,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String nome, String email, String cpf, String telefone, String dataNasc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Meus Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
          const SizedBox(height: 8),
          _infoRow('Nome', nome),
          _infoRow('Email', email != '-' ? email : '-'),
          _infoRow('CPF', cpf != '-' ? cpf : '-'),
          _infoRow('Telefone', telefone != '-' ? telefone : '-'),
          _infoRow('Data de Nascimento', dataNasc != '-' ? dataNasc : '-'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalScreen())),
              child: const Text('Editar dados'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Endereços'),
            subtitle: const Text('Gerencie seus endereços'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar senha'),
            subtitle: const Text('Atualize sua senha'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Preferências'),
            subtitle: const Text('Configurações do app'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Privacidade'),
            subtitle: const Text('Segurança e privacidade'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value ?? '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
