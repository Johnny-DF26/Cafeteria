import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;
  
  const EditUserScreen({super.key, required this.cliente});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomeCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _cpfCtrl;
  late TextEditingController _dataNascimentoCtrl;
  TextEditingController? _senhaCtrl;  // ⚡ Campo de senha
  
  bool _loading = false;
  bool _ativo = true;
  bool _alterarSenha = false;  // ⚡ Controla se deve alterar senha
  bool _senhaVisivel = false;  // ⚡ Controla visibilidade da senha

  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final maskCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final maskData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    
    // Debug: Mostra o conteúdo do objeto cliente
    debugPrint('===== DADOS DO CLIENTE =====');
    debugPrint('Cliente completo: ${widget.cliente}');
    debugPrint('ID: ${widget.cliente['id']}');
    debugPrint('idUsuario: ${widget.cliente['idUsuario']}');
    debugPrint('============================');
    
    _nomeCtrl = TextEditingController(text: widget.cliente['nome_completo'] ?? '');
    _emailCtrl = TextEditingController(text: widget.cliente['email'] ?? '');
    _telefoneCtrl = TextEditingController(text: _formatarTelefone(widget.cliente['telefone']));
    _cpfCtrl = TextEditingController(text: _formatarCPF(widget.cliente['cpf']));
    _dataNascimentoCtrl = TextEditingController(text: _formatarData(widget.cliente['data_nascimento']));
    _senhaCtrl = TextEditingController();  // ⚡ Inicializa vazio
    _ativo = widget.cliente['ativo'] == 1;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    _dataNascimentoCtrl.dispose();
    _senhaCtrl?.dispose();  // ⚡ Dispose seguro
    super.dispose();
  }

  String _formatarTelefone(String? telefone) {
    if (telefone == null || telefone.isEmpty) return '';
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return telefone;
  }

  String _formatarCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '';
    final numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 11) {
      return '${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}';
    }
    return cpf;
  }

  String _formatarData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return '';
    try {
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
      if (dataStr.contains('T')) {
        final data = DateTime.parse(dataStr);
        return DateFormat('dd/MM/yyyy').format(data);
      }
      if (dataStr.contains('-')) {
        final data = DateTime.parse(dataStr);
        return DateFormat('dd/MM/yyyy').format(data);
      }
      if (dataStr.contains('/')) {
        return dataStr;
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

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String dataFormatada = '';
      if (_dataNascimentoCtrl.text.isNotEmpty) {
        final parts = _dataNascimentoCtrl.text.split('/');
        if (parts.length == 3) {
          dataFormatada = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      final userId = widget.cliente['idUsuario'];
      
      if (userId == null) {
        throw Exception('ID do usuário não encontrado');
      }

      final bodyData = {
        'nome_completo': _nomeCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'cpf': _cpfCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'data_nascimento': dataFormatada,
        'ativo': _ativo ? 1 : 0,
      };

      // ⚡ Adiciona senha apenas se checkbox marcado e campo preenchido
      if (_alterarSenha && _senhaCtrl != null && _senhaCtrl!.text.isNotEmpty) {
        bodyData['senha'] = _senhaCtrl!.text.trim();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cliente atualizado com sucesso!',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Erro ao atualizar: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erro: $e',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
    //print(userId);
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Café Gourmet",
          style: GoogleFonts.pacifico(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar Cliente',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.brown.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Atualize as informações do cliente',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nomeCtrl,
                    label: 'Nome Completo',
                    icon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _telefoneCtrl,
                    label: 'Telefone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [maskTelefone],
                    validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _cpfCtrl,
                    label: 'CPF',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    inputFormatters: [maskCPF],
                    enabled: false,
                    validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _dataNascimentoCtrl,
                    label: 'Data de Nascimento',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    inputFormatters: [maskData],
                    validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // ⚡ SEÇÃO DE SENHA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Alterar Senha',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                            Switch(
                              value: _alterarSenha,
                              activeColor: Colors.orange.shade600,
                              onChanged: (value) {
                                setState(() {
                                  _alterarSenha = value;
                                  if (!value) _senhaCtrl?.clear();
                                });
                              },
                            ),
                          ],
                        ),
                        if (_alterarSenha && _senhaCtrl != null) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _senhaCtrl,
                            obscureText: !_senhaVisivel,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              labelText: 'Nova Senha',
                              labelStyle: GoogleFonts.poppins(),
                              hintText: 'Mínimo 6 caracteres',
                              hintStyle: GoogleFonts.poppins(fontSize: 12),
                              prefixIcon: Icon(Icons.lock, color: Colors.orange.shade700),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.orange.shade700,
                                ),
                                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                            ),
                            validator: (v) {
                              if (_alterarSenha && (v == null || v.isEmpty)) {
                                return 'Digite a nova senha';
                              }
                              if (_alterarSenha && v!.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _ativo ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _ativo ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _ativo ? Icons.check_circle : Icons.cancel,
                          color: _ativo ? Colors.green.shade700 : Colors.red.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status da Conta',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _ativo ? 'Ativo' : 'Inativo',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _ativo ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _ativo,
                          activeColor: Colors.green.shade600,
                          inactiveThumbColor: Colors.red.shade600,
                          onChanged: (value) => setState(() => _ativo = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade700,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 24),
                      label: Text(
                        _loading ? 'Salvando...' : 'Salvar Alterações',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _loading ? null : _salvarAlteracoes,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: Colors.brown.shade700),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: validator,
    );
  }
}