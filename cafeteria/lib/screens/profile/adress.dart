import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  // Busca endereços do usuário via API e atualiza o Provider
  Future<void> fetchAddresses() async {
    setState(() => loading = true);
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    //print(userData);
    if (userData == null) {
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse('http://192.168.0.167:5000/get_endereco/${userData['id']}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Provider.of<UserProvider>(context, listen: false).addresses =
            List<Map<String, dynamic>>.from(data);
      } else {
        print('Erro ao buscar endereços: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar: $e');
    }
    setState(() => loading = false);
  }

  // Adiciona ou atualiza endereço via API
  Future<void> saveAddress(Map<String, dynamic> address, {int? idEndereco}) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    //print(userData);
    if (userData == null) return;

    final url = idEndereco == null
        ? Uri.parse('http://192.168.0.167:5000/add_endereco')
        : Uri.parse('http://192.168.0.167:5000/update_endereco/$idEndereco');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...address,
          'Usuario_idUsuario': userData['id'],
        }),
      );

      if (response.statusCode == 200) {
        // Atualiza a lista no Provider após salvar no banco
        fetchAddresses();
      } else {
        print('Erro ao salvar endereço: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar: $e');
    }
  }

  // Deleta endereço via API
  Future<void> deleteAddress(int idEndereco) async {
    final url = Uri.parse('http://192.168.0.167:5000/delete_endereco/$idEndereco');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        fetchAddresses();
      } else {
        print('Erro ao deletar endereço: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar: $e');
    }
  }

  // Dialog para adicionar/editar endereço (mantive por compatibilidade)
  void _showAddressDialog(BuildContext context, {Map<String, dynamic>? addr}) {
  final _formKey = GlobalKey<FormState>();

  final logradouroController = TextEditingController(text: addr?['logradouro'] ?? '');
  final numeroController = TextEditingController(text: addr?['numero'] ?? '');
  final bairroController = TextEditingController(text: addr?['bairro'] ?? '');
  final cidadeController = TextEditingController(text: addr?['cidade'] ?? '');
  final estadoController = TextEditingController(text: addr?['estado'] ?? '');
  final cepController = TextEditingController(text: addr?['cep'] ?? '');
  final complementoController = TextEditingController(text: addr?['complemento'] ?? '');
  final referenciaController = TextEditingController(text: addr?['referencia'] ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(addr == null ? 'Adicionar Endereço' : 'Editar Endereço'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: logradouroController,
                decoration: const InputDecoration(labelText: 'Logradouro'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o logradouro' : null,
              ),
              TextFormField(
                controller: numeroController,
                decoration: const InputDecoration(labelText: 'Número'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o número' : null,
              ),
              TextFormField(
                controller: bairroController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o bairro' : null,
              ),
              TextFormField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe a cidade' : null,
              ),
              TextFormField(
                controller: estadoController,
                decoration: const InputDecoration(labelText: 'Estado'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o estado' : null,
              ),
              TextFormField(
                controller: cepController,
                decoration: const InputDecoration(labelText: 'CEP'),
                validator: (value) => (value == null || value.isEmpty) ? 'Informe o CEP' : null,
              ),
              TextFormField(
                controller: complementoController,
                decoration: const InputDecoration(labelText: 'Complemento (opcional)'),
              ),
              TextFormField(
                controller: referenciaController,
                decoration: const InputDecoration(labelText: 'Referência (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
          onPressed: () {
            if (_formKey.currentState!.validate()) { // só salva se todos os campos obrigatórios estiverem preenchidos
              final newAddress = {
                'logradouro': logradouroController.text,
                'numero': numeroController.text,
                'bairro': bairroController.text,
                'cidade': cidadeController.text,
                'estado': estadoController.text,
                'cep': cepController.text,
                'complemento': complementoController.text,
                'referencia': referenciaController.text,
              };
              saveAddress(newAddress, idEndereco: addr?['idEndereco_usuario']);
              Navigator.pop(context);
            }
          },
          child: const Text('Salvar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final addresses = Provider.of<UserProvider>(context).addresses;
    final userData = Provider.of<UserProvider>(context, listen: false).userData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Barra superior igual à ProfileScreen
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Endereços',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 46, 33, 27),
                ),
              ),
            ),
          ),
          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : addresses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(child: Text('Nenhum endereço cadastrado')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final addr = addresses[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('${addr['logradouro']}, ${addr['numero']}'),
                                subtitle: Text('${addr['bairro']}, ${addr['cidade']} - ${addr['estado']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddressDialog(context, addr: addr),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteAddress(addr['idEndereco_usuario']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 36, 211, 0),
        child: const Icon(Icons.add),
        onPressed: () => _showAddressDialog(context),
      ),

      // Bottom Navigation idêntico ao ProfileScreen
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, Routes.cart);
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
}
