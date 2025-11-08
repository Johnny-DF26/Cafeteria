import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ViewDeleteCouponScreen extends StatefulWidget {
  final int adminId;
  const ViewDeleteCouponScreen({super.key, required this.adminId});

  @override
  State<ViewDeleteCouponScreen> createState() => _ViewDeleteCouponScreenState();
}

class _ViewDeleteCouponScreenState extends State<ViewDeleteCouponScreen> {
  List<Map<String, dynamic>> cupons = [];
  List<Map<String, dynamic>> cuponsFiltrados = [];
  bool carregando = false;
  final TextEditingController codigoController = TextEditingController();
  String get baseUrl => GlobalConfig.GlobalConfig.api();

  @override
  void initState() {
    super.initState();
    buscarCupons();
  }

  // --------------------- BUSCAR CUPONS ---------------------
  Future<void> buscarCupons() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/cupons'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cupons = List<Map<String, dynamic>>.from(data['cupons']);
          cuponsFiltrados = List.from(cupons);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar cupons!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
    setState(() => carregando = false);
  }

  // --------------------- DELETAR CUPOM ---------------------
  Future<void> deletarCupom(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/cupons/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupom excluído com sucesso!')),
        );
        buscarCupons();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir cupom!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  // --------------------- ATUALIZAR CUPOM ---------------------
  Future<void> atualizarCupom(int id, Map<String, dynamic> dados) async {
    try {
      // Converte DD/MM/YYYY para YYYY-MM-DD
      if (dados['data_validade'] != null && dados['data_validade'].isNotEmpty) {
        dados['data_validade'] = formatarParaBanco(dados['data_validade']);
      }

      final response = await http.put(
        Uri.parse('$baseUrl/cupons/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupom atualizado com sucesso!')),
        );
        buscarCupons();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar cupom: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  // --------------------- ADICIONAR CUPOM ---------------------
  Future<void> adicionarCupom(Map<String, dynamic> dados) async {
    try {
      // Converte DD/MM/YYYY para YYYY-MM-DD
      if (dados['data_validade'] != null && dados['data_validade'].isNotEmpty) {
        dados['data_validade'] = formatarParaBanco(dados['data_validade']);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cupons'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cupom adicionado com sucesso!')),
        );
        buscarCupons();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao adicionar cupom: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Erro de conexão: $e')),
      );
    }
  }

  // --------------------- CONVERTE DD/MM/YYYY -> YYYY-MM-DD ---------------------
  String formatarParaBanco(String data) {
    try {
      if (data.contains('/')) {
        final partes = data.split('/');
        if (partes.length == 3) {
          return '${partes[2]}-${partes[1]}-${partes[0]}';
        }
      }
      return data;
    } catch (_) {
      return data;
    }
  }

  // --------------------- CONVERTE YYYY-MM-DD -> DD/MM/YYYY ---------------------
  String formatarParaTela(dynamic data) {
    try {
      // Se for null ou vazio
      if (data == null || data.toString().isEmpty) {
        return '';
      }

      String dataStr = data.toString();

      // Se já vier em DD/MM/YYYY, retorna
      if (dataStr.contains('/') && !dataStr.contains('GMT')) {
        return dataStr;
      }

      DateTime dt;

      // Se vier do MySQL como GMT: "Mon, 29 Dec 2025 00:00:00 GMT"
      if (dataStr.contains('GMT')) {
        // Extrai apenas a parte da data: "29 Dec 2025"
        final regex = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})');
        final match = regex.firstMatch(dataStr);
        
        if (match != null) {
          final dia = int.parse(match.group(1)!);
          final mesStr = match.group(2)!;
          final ano = int.parse(match.group(3)!);
          
          // Mapa de meses
          final meses = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 
            'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 
            'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final mes = meses[mesStr] ?? 1;
          dt = DateTime(ano, mes, dia);
        } else {
          return dataStr;
        }
      }
      // Se vier no formato ISO: "2025-12-29T00:00:00.000Z"
      else if (dataStr.contains('T') || dataStr.contains('Z')) {
        dt = DateTime.parse(dataStr);
      }
      // Se vier no formato YYYY-MM-DD
      else if (dataStr.contains('-')) {
        final partes = dataStr.split('-');
        if (partes.length == 3) {
          // Remove qualquer hora se existir
          final diaLimpo = partes[2].split(' ')[0].split('T')[0];
          dt = DateTime(
            int.parse(partes[0]),
            int.parse(partes[1]),
            int.parse(diaLimpo),
          );
        } else {
          return dataStr;
        }
      } else {
        return dataStr;
      }

      // Formata para DD/MM/YYYY
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      print('Erro ao formatar data: $e - Data original: $data');
      return data.toString();
    }
  }

  // --------------------- FILTRAR ---------------------
  void filtrarPorCodigo() {
    final codigo = codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() => cuponsFiltrados = List.from(cupons));
      return;
    }
    final filtrado = cupons.where((c) => c['codigo'].contains(codigo)).toList();
    setState(() => cuponsFiltrados = filtrado);
  }

  // --------------------- MODAL ADICIONAR ---------------------
  void abrirAdicionarCupom() {
    final codigoControllerModal = TextEditingController();
    final descricaoControllerModal = TextEditingController();
    final descontoControllerModal = TextEditingController();
    final validadeControllerModal = TextEditingController();
    String tipoDesconto = 'percentual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adicionar Cupom', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTextField('Código', codigoControllerModal),
                _buildTextField('Descrição', descricaoControllerModal),
                _buildTextField('Desconto', descontoControllerModal, keyboardType: TextInputType.number),
                DropdownButtonFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: tipoDesconto,
                  items: const [
                    DropdownMenuItem(value: 'percentual', child: Text('Percentual')),
                    DropdownMenuItem(value: 'valor', child: Text('Valor Fixo')),
                  ],
                  onChanged: (value) => tipoDesconto = value!,
                ),
                const SizedBox(height: 12),
                _buildTextField('Data de Validade', validadeControllerModal, 
                  keyboardType: TextInputType.number,
                  useMask: true),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final dados = {
                      'codigo': codigoControllerModal.text,
                      'descricao': descricaoControllerModal.text,
                      'desconto': double.tryParse(descontoControllerModal.text) ?? 0,
                      'tipo_desconto': tipoDesconto,
                      'data_validade': validadeControllerModal.text,
                      'Administrador_idAdministrador': widget.adminId,
                    };
                    Navigator.pop(context);
                    adicionarCupom(dados);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Adicionar Cupom'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------- MODAL EDITAR ---------------------
  void abrirEdicao(Map<String, dynamic> cupom) {
    final codigoControllerModal = TextEditingController(text: cupom['codigo']);
    final descricaoControllerModal = TextEditingController(text: cupom['descricao']);
    final descontoControllerModal = TextEditingController(text: cupom['desconto'].toString());
    final validadeControllerModal = TextEditingController(
      text: formatarParaTela(cupom['data_validade'])
    );
    String tipoDesconto = cupom['tipo_desconto'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar Cupom', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTextField('Código', codigoControllerModal),
                _buildTextField('Descrição', descricaoControllerModal),
                _buildTextField('Desconto', descontoControllerModal, keyboardType: TextInputType.number),
                DropdownButtonFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: tipoDesconto,
                  items: const [
                    DropdownMenuItem(value: 'percentual', child: Text('Percentual')),
                    DropdownMenuItem(value: 'valor', child: Text('Valor Fixo')),
                  ],
                  onChanged: (value) => tipoDesconto = value!,
                ),
                const SizedBox(height: 12),
                _buildTextField('Data de Validade', validadeControllerModal, 
                  keyboardType: TextInputType.number,
                  useMask: true),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final dados = {
                      'codigo': codigoControllerModal.text,
                      'descricao': descricaoControllerModal.text,
                      'desconto': double.tryParse(descontoControllerModal.text) ?? 0,
                      'tipo_desconto': tipoDesconto,
                      'data_validade': validadeControllerModal.text,
                    };
                    Navigator.pop(context);
                    atualizarCupom(cupom['idCupom'], dados);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------- TEXTFIELD ---------------------
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool useMask = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: useMask ? [
          MaskTextInputFormatter(
            mask: '##/##/####',
            filter: {"#": RegExp(r'[0-9]')},
          )
        ] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: useMask ? 'DD/MM/AAAA' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // --------------------- BUILD ---------------------
  @override
  Widget build(BuildContext context) {
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
                'Café Gourmet',
                style: GoogleFonts.pacifico(fontSize: 30, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codigoController,
                          decoration: InputDecoration(
                            labelText: 'Código do Cupom',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.confirmation_num),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: filtrarPorCodigo,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade900),
                        child: const Text('Buscar', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () {
                          codigoController.clear();
                          filtrarPorCodigo();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                        child: const Text('Mostrar todos', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Gerenciar Cupons', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: abrirAdicionarCupom,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Adicionar Novo Cupom'),
                  ),
                  const SizedBox(height: 16),
                  carregando
                      ? const Center(child: CircularProgressIndicator())
                      : cuponsFiltrados.isEmpty
                          ? const Center(child: Text('Nenhum cupom encontrado.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cuponsFiltrados.length,
                              itemBuilder: (_, index) {
                                final cupom = cuponsFiltrados[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Código: ${cupom['codigo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('Descrição: ${cupom['descricao']}'),
                                        Text('Desconto: ${cupom['desconto']} ${cupom['tipo_desconto'] == 'percentual' ? '%' : 'R\$'}'),
                                        Text('Validade: ${formatarParaTela(cupom['data_validade'])}'),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => abrirEdicao(cupom)),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: const Text('Remover Cupom'),
                                                    content: Text('Deseja realmente remover o cupom "${cupom['codigo']}"?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          deletarCupom(cupom['idCupom']);
                                                        },
                                                        child: const Text('Remover', style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade200.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      ),
    );
  }
}
