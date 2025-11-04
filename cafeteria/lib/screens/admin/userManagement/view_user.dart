import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();
class BuscarClienteScreen extends StatefulWidget {
  const BuscarClienteScreen({super.key});

  @override
  State<BuscarClienteScreen> createState() => _BuscarClienteScreenState();
}

class _BuscarClienteScreenState extends State<BuscarClienteScreen>
    with SingleTickerProviderStateMixin {
  final _cpfCtrl = TextEditingController();
  final maskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Map<String, dynamic>? _cliente;
  bool _loading = false;
  bool _cpfValido = false;
  String? _mensagemCard;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  //final String baseUrl = 'http://192.168.0.167:5000'; // coloque seu IP

  @override
  void initState() {
    super.initState();
    _cpfCtrl.addListener(() {
      final unmasked = maskFormatter.getUnmaskedText();
      setState(() => _cpfValido = unmasked.length == 11);
    });

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> buscarCliente() async {
    if (!_cpfValido) return;
    setState(() {
      _loading = true;
      _cliente = null;
      _mensagemCard = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/cliente/${maskFormatter.getUnmaskedText()}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _cliente = data['cliente']);
      } else if (response.statusCode == 404) {
        setState(() => _mensagemCard = 'Cliente não encontrado.');
      } else {
        final data = json.decode(response.body);
        setState(() => _mensagemCard = data['error'] ?? 'Erro ao buscar cliente.');
      }
    } catch (e) {
      setState(() => _mensagemCard = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> excluirCliente() async {
    if (_cliente == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text('Excluir cliente ${_cliente!['cpf']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _loading = true);
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/cliente/${_cliente!['cpf']}'));
      if (response.statusCode == 200) {
        await _animController.forward();
        setState(() {
          _cliente = null;
          _mensagemCard = 'Cliente excluído com sucesso!';
        });
        _animController.reset();
      } else {
        final data = json.decode(response.body);
        setState(() => _mensagemCard = data['error'] ?? 'Erro ao excluir cliente.');
      }
    } catch (e) {
      setState(() => _mensagemCard = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void limparCampos() {
    setState(() {
      _cpfCtrl.clear();
      _cliente = null;
      _mensagemCard = null;
      _cpfValido = false;
    });
  }

  String formatarData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return '';
    try {
      final data = DateTime.parse(dataStr);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (_) {
      return dataStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Cliente'),
        backgroundColor: const Color.fromARGB(255, 228, 224, 223),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Digite o CPF para buscar o cliente',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cpfCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskFormatter],
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            label: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Buscar Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 234, 231, 230),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed:
                                (_loading || !_cpfValido) ? null : buscarCliente,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _loading ? null : limparCampos,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_cliente != null || _mensagemCard != null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildClienteCard(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClienteCard() {
    final ativo = _cliente != null && _cliente!['ativo'] == 1;
    final dataFormatada = formatarData(_cliente?['data_nascimento']);

    return Card(
      color: ativo ? Colors.green[50] : Colors.red[50],
      elevation: 4,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_cliente != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nome: ${_cliente!['nome_completo']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    ativo ? Icons.check_circle : Icons.cancel,
                    color: ativo ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Email: ${_cliente!['email']}'),
              Text('Telefone: ${_cliente!['telefone']}'),
              Text('CPF: ${_cliente!['cpf']}'),
              Text('Data de Nascimento: $dataFormatada'),
              Text('Ativo: ${ativo ? 'Sim' : 'Não'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(141, 249, 84, 72),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir Cliente'),
                  onPressed: excluirCliente,
                ),
              ),
            ],
            if (_mensagemCard != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    _mensagemCard!,
                    style: TextStyle(
                      color: _cliente == null ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
