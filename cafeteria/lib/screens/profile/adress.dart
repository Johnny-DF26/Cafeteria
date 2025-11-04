import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();



class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    if (!mounted) return;
    setState(() => loading = true);

    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    final url = Uri.parse('$baseUrl/get_endereco/${userData['id']}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).addresses =
              List<Map<String, dynamic>>.from(data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar endereços: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveAddress(Map<String, dynamic> address, {int? idEndereco}) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) {
      return;
    }

    final url = idEndereco == null
        ? Uri.parse('$baseUrl/add_endereco')
        : Uri.parse('$baseUrl/update_endereco/$idEndereco');

    try {
      final body = jsonEncode({
        ...address,
        'Usuario_idUsuario': userData['id'],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await fetchAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço salvo com sucesso'))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${response.statusCode}'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar: $e'))
        );
      }
    }
  }

  Future<void> deleteAddress(int idEndereco) async {
    final url = Uri.parse('$baseUrl/delete_endereco/$idEndereco');
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await fetchAddresses();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço removido')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar: ${response.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao conectar: $e')));
    }
  }

  String? _validateCEP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o CEP';
    }
    
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (clean.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    
    // Verifica se não são todos números iguais (ex: 00000-000, 11111-111)
    if (RegExp(r'^(\d)\1{7}$').hasMatch(clean)) {
      return 'CEP inválido';
    }
    
    return null;
  }

  String? _validateUF(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o estado (UF)';
    }
    
    if (value.length != 2) {
      return 'UF deve ter 2 letras';
    }
    
    // Lista de UFs válidas no Brasil
    const ufsValidas = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
      'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
      'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
    ];
    
    if (!ufsValidas.contains(value.toUpperCase())) {
      return 'UF inválida';
    }
    
    return null;
  }

  void _showAddressDialog(BuildContext context, {Map<String, dynamic>? addr}) {
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final logradouroController = TextEditingController(text: addr?['logradouro'] ?? '');
    final numeroController = TextEditingController(text: addr?['numero']?.toString() ?? '');
    final bairroController = TextEditingController(text: addr?['bairro'] ?? '');
    final cidadeController = TextEditingController(text: addr?['cidade'] ?? '');
    final estadoController = TextEditingController(text: addr?['estado'] ?? '');
    final cepController = TextEditingController(text: addr?['cep'] ?? '');
    final complementoController = TextEditingController(text: addr?['complemento'] ?? '');
    final referenciaController = TextEditingController(text: addr?['referencia'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(addr == null ? 'Adicionar Endereço' : 'Editar Endereço'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cepController,
                    decoration: const InputDecoration(
                      labelText: 'CEP',
                      hintText: '12345-678',
                    ),
                    enabled: !isSaving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      _CepInputFormatter(),
                    ],
                    validator: _validateCEP,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: logradouroController,
                    decoration: const InputDecoration(labelText: 'Logradouro'),
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value == null || value.isEmpty) ? 'Informe o logradouro' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: numeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                    enabled: !isSaving,
                    keyboardType: TextInputType.text,
                    validator: (value) => (value == null || value.isEmpty) ? 'Informe o número' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: bairroController,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value == null || value.isEmpty) ? 'Informe o bairro' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cidadeController,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value == null || value.isEmpty) ? 'Informe a cidade' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: estadoController,
                    decoration: const InputDecoration(
                      labelText: 'Estado (UF)',
                      hintText: 'SP',
                    ),
                    enabled: !isSaving,
                    maxLength: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(2),
                      _UpperCaseTextFormatter(),
                    ],
                    validator: _validateUF,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: complementoController,
                    decoration: const InputDecoration(
                      labelText: 'Complemento (opcional)',
                      hintText: 'Apt 101, Bloco A',
                    ),
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: referenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Referência (opcional)',
                      hintText: 'Próximo ao mercado',
                    ),
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSaving = true);
                  
                  final newAddress = {
                    'logradouro': logradouroController.text.trim(),
                    'numero': numeroController.text.trim(),
                    'bairro': bairroController.text.trim(),
                    'cidade': cidadeController.text.trim(),
                    'estado': estadoController.text.trim(),
                    'cep': cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                    'complemento': complementoController.text.trim(),
                    'referencia': referenciaController.text.trim(),
                  };
                  
                  await saveAddress(newAddress, idEndereco: addr?['idEndereco_usuario']);
                  
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((_) {
      logradouroController.dispose();
      numeroController.dispose();
      bairroController.dispose();
      cidadeController.dispose();
      estadoController.dispose();
      cepController.dispose();
      complementoController.dispose();
      referenciaController.dispose();
    });
  }

  Future<void> _confirmDelete(BuildContext context, int idEndereco) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: const Text('Deseja realmente remover este endereço?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await deleteAddress(idEndereco);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = Provider.of<UserProvider>(context).addresses;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: fetchAddresses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.brown.shade700,
              expandedHeight: 110,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : addresses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Center(child: Text('Nenhum endereço cadastrado')),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final addr = addresses[index];
                              final title = '${addr['logradouro'] ?? ''}, ${addr['numero'] ?? ''}';
                              final subtitle = '${addr['bairro'] ?? ''}, ${addr['cidade'] ?? ''} - ${addr['estado'] ?? ''}';
                              return Dismissible(
                                key: Key('${addr['idEndereco_usuario']}_${index}'),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await _confirmDelete(context, addr['idEndereco_usuario']);
                                  // Não remover automaticamente; a função delete atualiza a lista
                                  return false;
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                                  child: ListTile(
                                    title: Text(title),
                                    subtitle: Text(subtitle),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showAddressDialog(context, addr: addr),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDelete(context, addr['idEndereco_usuario']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 0, 218, 15),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddressDialog(context),
      ),
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

class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String newText = '';

    if (text.length >= 5) {
      newText = '${text.substring(0, 5)}-${text.substring(5)}';
    } else {
      newText = text;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
