import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;
import 'package:google_fonts/google_fonts.dart';
import 'edit_user_screen.dart';

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
      final cpfLimpo = maskFormatter.getUnmaskedText();
      
      final response = await http.get(
        Uri.parse('$baseUrl/cliente/$cpfLimpo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['idUsuario'] == null) {
          setState(() => _mensagemCard = 'Erro: Cliente sem ID válido.');
          return;
        }
        
        setState(() => _cliente = data);
      } else if (response.statusCode == 404) {
        setState(() => _mensagemCard = 'Cliente não encontrado.');
      } else {
        final data = json.decode(response.body);
        setState(() => _mensagemCard = data['error'] ?? 'Erro ao buscar cliente.');
      }
    } catch (e) {
      setState(() => _mensagemCard = 'Erro de conexão: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> excluirCliente() async {
    if (_cliente == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmação',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Excluir cliente ${_cliente!['cpf']}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Excluir',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
      // Fallback: extrai a data manualmente do formato GMT
      if (dataStr.contains('GMT') || dataStr.contains(',')) {
        final parts = dataStr.split(',')[1].trim().split(' ');
        if (parts.length >= 3) {
          final dia = int.parse(parts[0]);
          final mes = _mesParaNumero(parts[1]);
          final ano = int.parse(parts[2]);
          
          if (mes > 0) {
            final data = DateTime(ano, mes, dia);
            return DateFormat('dd/MM/yyyy').format(data);
          }
        }
      }
      
      // Formato ISO: 2000-01-15T00:00:00.000Z
      if (dataStr.contains('T')) {
        final data = DateTime.parse(dataStr);
        return DateFormat('dd/MM/yyyy').format(data);
      }
      
      // Formato: 2000-01-15 ou 1998-10-07
      if (dataStr.contains('-')) {
        final data = DateTime.parse(dataStr);
        return DateFormat('dd/MM/yyyy').format(data);
      }
      
      // Formato: 15/01/2000
      if (dataStr.contains('/')) {
        final parts = dataStr.split('/');
        if (parts.length == 3) {
          final data = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return DateFormat('dd/MM/yyyy').format(data);
        }
      }
      
      return dataStr;
    } catch (e) {
      return dataStr;
    }
  }

  int _mesParaNumero(String mes) {
    const meses = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return meses[mes] ?? 0;
  }

  String formatarCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '';
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 11) return cpf;
    return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
  }

  String formatarTelefone(String? telefone) {
    if (telefone == null || telefone.isEmpty) return '';
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return telefone;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Café Gourmet",
          style: GoogleFonts.pacifico(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width > 600 ? 480 : width),
            child: Column(
              children: [
                // Título fora da AppBar
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Buscar Cliente',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Digite o CPF para buscar o cliente',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cpfCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [maskFormatter],
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            labelText: 'CPF',
                            labelStyle: GoogleFonts.poppins(),
                            prefixIcon: Icon(Icons.credit_card, color: Colors.brown.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.search, size: 20),
                                label: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Buscar',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: (_loading || !_cpfValido) ? null : buscarCliente,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade700),
                                label: Text(
                                  'Limpar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClienteCard() {
    final ativo = _cliente != null && _cliente!['ativo'] == 1;
    final dataFormatada = formatarData(_cliente?['data_nascimento']);
    final cpfFormatado = formatarCPF(_cliente?['cpf']);
    final telefoneFormatado = formatarTelefone(_cliente?['telefone']);

    return Card(
      color: ativo ? Colors.green.shade50 : Colors.red.shade50,
      elevation: 4,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      _cliente!['nome_completo'] ?? 'Nome não disponível',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade900,
                      ),
                    ),
                  ),
                  Icon(
                    ativo ? Icons.check_circle : Icons.cancel,
                    color: ativo ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email, 'Email', _cliente!['email'] ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Telefone', telefoneFormatado.isNotEmpty ? telefoneFormatado : 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.credit_card, 'CPF', cpfFormatado.isNotEmpty ? cpfFormatado : 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.cake, 'Data de Nascimento', dataFormatada.isNotEmpty ? dataFormatada : 'N/A'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ativo ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ativo ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ativo ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 18,
                      color: ativo ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${ativo ? 'Ativo' : 'Inativo'}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: ativo ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.brown.shade700, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.brown.shade700,
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 22),
                      label: Text(
                        'Editar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUserScreen(cliente: _cliente!),
                          ),
                        ).then((_) {
                          if (_cpfCtrl.text.isNotEmpty) {
                            buscarCliente();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 22),
                      label: Text(
                        'Excluir',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: excluirCliente,
                    ),
                  ),
                ],
              ),
            ],
            if (_mensagemCard != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cliente == null ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _cliente == null ? Colors.red.shade300 : Colors.green.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cliente == null ? Icons.error_outline : Icons.check_circle_outline,
                        color: _cliente == null ? Colors.red.shade700 : Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensagemCard!,
                          style: GoogleFonts.poppins(
                            color: _cliente == null ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.brown.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade900,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
