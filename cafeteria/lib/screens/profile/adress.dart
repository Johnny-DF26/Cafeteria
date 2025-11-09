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

// Formatadores fora da classe principal
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String newText = '';
    if (text.length > 5) {
      newText = '${text.substring(0, 5)}-${text.substring(5, text.length > 8 ? 8 : text.length)}';
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

  Future<void> fetchAddresses() async {
    setState(() => loading = true);
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) {
      setState(() => loading = false);
      return;
    }
    final url = Uri.parse('$baseUrl/get_endereco/${userData['id']}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Provider.of<UserProvider>(context, listen: false).addresses =
            List<Map<String, dynamic>>.from(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Erro ao buscar endereços: ${response.statusCode}'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Erro de conexão: $e'))
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveAddress(Map<String, dynamic> address, {int? idEndereco}) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) return;
    final url = idEndereco == null
        ? Uri.parse('$baseUrl/add_endereco')
        : Uri.parse('$baseUrl/update_endereco/$idEndereco');
    try {
      final body = jsonEncode({...address, 'Usuario_idUsuario': userData['id']});
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Endereço salvo com sucesso'), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao salvar: ${response.statusCode}'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️Erro ao conectar: $e'))
      );
    }
  }

  Future<void> deleteAddress(int idEndereco) async {
    final url = Uri.parse('$baseUrl/delete_endereco/$idEndereco');
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await fetchAddresses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço removido com sucesso!'), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao deletar: ${response.statusCode}'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao conectar: $e'), backgroundColor: Colors.red)
      );
    }
  }

  String? _validateCEP(String? value) {
    if (value == null || value.isEmpty) return 'Informe o CEP';
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 8) return 'CEP deve ter 8 dígitos';
    if (RegExp(r'^(\d)\1{7}$').hasMatch(clean)) return '❌ CEP inválido';
    return null;
  }

  String? _validateUF(String? value) {
    if (value == null || value.isEmpty) return 'Informe o estado (UF)';
    if (value.length != 2) return 'UF deve ter 2 letras';
    const ufsValidas = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
      'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
      'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
    ];
    if (!ufsValidas.contains(value.toUpperCase())) return '❌ UF inválida';
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
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.brown.shade700,
              width: 2,
            ),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('📍', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          addr == null ? 'Novo Endereço' : 'Editar Endereço',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _buildStyledTextField(
                            label: 'CEP',
                            controller: cepController,
                            icon: Icons.local_post_office,
                            keyboardType: TextInputType.number,
                            enabled: !isSaving,
                            validator: _validateCEP,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                              _CepInputFormatter(),
                            ],
                          ),
                          _buildStyledTextField(
                            label: 'Logradouro',
                            controller: logradouroController,
                            icon: Icons.streetview,
                            enabled: !isSaving,
                            validator: (v) => (v == null || v.isEmpty) ? 'Informe o logradouro' : null,
                          ),
                          _buildStyledTextField(
                            label: 'Número',
                            controller: numeroController,
                            icon: Icons.confirmation_number,
                            enabled: !isSaving,
                            validator: (v) => (v == null || v.isEmpty) ? 'Informe o número' : null,
                          ),
                          _buildStyledTextField(
                            label: 'Bairro',
                            controller: bairroController,
                            icon: Icons.home_work,
                            enabled: !isSaving,
                            validator: (v) => (v == null || v.isEmpty) ? 'Informe o bairro' : null,
                          ),
                          _buildStyledTextField(
                            label: 'Cidade',
                            controller: cidadeController,
                            icon: Icons.location_city,
                            enabled: !isSaving,
                            validator: (v) => (v == null || v.isEmpty) ? 'Informe a cidade' : null,
                          ),
                          _buildStyledTextField(
                            label: 'Estado (UF)',
                            controller: estadoController,
                            icon: Icons.map,
                            enabled: !isSaving,
                            validator: _validateUF,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                              LengthLimitingTextInputFormatter(2),
                              _UpperCaseTextFormatter(),
                            ],
                          ),
                          _buildStyledTextField(
                            label: 'Complemento',
                            controller: complementoController,
                            icon: Icons.apartment,
                            enabled: !isSaving,
                          ),
                          _buildStyledTextField(
                            label: 'Referência',
                            controller: referenciaController,
                            icon: Icons.pin_drop,
                            enabled: !isSaving,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            //icon: Text(addr == null ? '➕' : '💾', style: TextStyle(fontSize: 18)),
                            label: Text(addr == null ? 'Salvar' : 'Atualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.brown.shade700),
          labelStyle: TextStyle(color: Colors.brown.shade700),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.brown.shade900, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade900, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
                            child: Center(child: Text('⚠️ Nenhum endereço cadastrado')),
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
