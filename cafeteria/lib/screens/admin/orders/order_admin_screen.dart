import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

// Altera o formato da linha (divisória dos produtos)
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 1;

    double startX = 0;
    const y = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrderAdminScreen extends StatefulWidget {
  const OrderAdminScreen({super.key});
  
  @override
  State<OrderAdminScreen> createState() => _OrderAdminScreenState();
}

class _OrderAdminScreenState extends State<OrderAdminScreen> {
  Future<List<Map<String, dynamic>>> _relatoriosFuture = Future.value([]);
  final ScrollController _scrollController = ScrollController();
  String _filtroSelecionado = 'Todos';

  @override
  void initState() {
    super.initState();
    _relatoriosFuture = fetchRelatorios();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchRelatorios() async {
    final url = Uri.parse('$baseUrl/relatorios_pedidos');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erro ao carregar relatórios');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProdutosDoPedido(int pedidoId, int usuarioId) async {
    final url = Uri.parse('$baseUrl/listar_pedidos/$usuarioId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final pedido = data.firstWhere(
        (p) => p['idRelatorio_Pedido'] == pedidoId,
        orElse: () => null,
      );
      if (pedido != null && pedido['items'] != null) {
        return List<Map<String, dynamic>>.from(pedido['items']);
      }
      return [];
    } else {
      throw Exception('Erro ao carregar produtos do pedido $pedidoId');
    }
  }

  List<Map<String, dynamic>> _filtrarPedidos(List<Map<String, dynamic>> pedidos) {
    if (_filtroSelecionado == 'Todos') {
      return pedidos;
    }
    return pedidos.where((p) {
      final status = (p['status'] ?? 'realizado').toString().toLowerCase();
      return status == _filtroSelecionado.toLowerCase();
    }).toList();
  }

  Future<void> atualizarStatus(int id, String novoStatus) async {
    final url = Uri.parse('$baseUrl/update_relatorios_pedidos/$id');
    final messenger = ScaffoldMessenger.of(context);
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': novoStatus}),
    );

    if (response.statusCode == 200) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Status atualizado com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {
        _relatoriosFuture = fetchRelatorios();
      });
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erro ao atualizar status!'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _mostrarDialogoStatus(int id, String statusAtual) {
    final List<String> opcoes = [
      'realizado',
      'produção',
      'pronto',
      'a caminho',
      'entregue',
      'cancelado'
    ];

    String selecionado = statusAtual.toLowerCase();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Atualizar Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButton<String>(
                value: selecionado,
                isExpanded: true,
                onChanged: (valor) {
                  if (valor != null) {
                    setStateDialog(() => selecionado = valor);
                  }
                },
                items: opcoes.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s, style: GoogleFonts.poppins()),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                atualizarStatus(id, selecionado);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Salvar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: valueColor ?? Colors.grey.shade800,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('realizado')) return const Color.fromARGB(255, 255, 17, 0);
    if (s.contains('produção')) return Colors.blue;
    if (s.contains('pronto')) return Colors.purple;
    if (s.contains('a caminho')) return Colors.teal;
    if (s.contains('entregue')) return Colors.green;
    if (s.contains('cancelado')) return Colors.grey;
    if (s == 'todos') return Colors.brown.shade700;
    return Colors.grey;
  }

  String formatarTelefone(String telefone) {
    // Remove tudo que não for número
    final numeros = telefone.replaceAll(RegExp(r'\D'), '');
    if (numeros.length == 11) {
      // Celular: (99) 99999-9999
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 10) {
      // Fixo: (99) 9999-9999
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return telefone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 110,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Cafe Gourmet',
                style: GoogleFonts.pacifico(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie e acompanhe todos os pedidos',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filtro de status
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.filter_list,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Filtrar por Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.brown.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Todos',
                              'realizado',
                              'produção',
                              'pronto',
                              'a caminho',
                              'entregue',
                              'cancelado'
                            ].map((status) {
                              final isSelected = _filtroSelecionado == status;
                              return FilterChip(
                                selected: isSelected,
                                label: Text(
                                  status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.brown.shade700,
                                  ),
                                ),
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: _statusColor(status),
                                onSelected: (selected) {
                                  setState(() {
                                    _filtroSelecionado = status;
                                  });
                                },
                                checkmarkColor: Colors.white,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Lista de pedidos
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _relatoriosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro: ${snapshot.error}',
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhum pedido encontrado",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final relatorios = snapshot.data!;
              final relatoriosFiltrados = _filtrarPedidos(relatorios);

              if (relatoriosFiltrados.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhum pedido com status '$_filtroSelecionado'",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final relatorio = relatoriosFiltrados[relatoriosFiltrados.length - 1 - index];
                      final dataStr = relatorio['data_status']?.toString() ?? '';
                      DateTime data;

                      try {
                        data = HttpDate.parse(dataStr);
                      } catch (_) {
                        data = DateTime.now();
                      }

                      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(data);
                      final status = relatorio['status'] ?? 'realizado';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.brown.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: Colors.brown.shade700,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Pedido #${relatorio['idRelatorio_Pedido']}",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: Colors.brown.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _statusColor(status), width: 1.5),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.brown.shade200),
                              const SizedBox(height: 12),

                              _buildInfoRow(Icons.person, "ID Usuário", "${relatorio['Usuario_idUsuario']}"),
                              _buildInfoRow(Icons.account_circle, "Nome", relatorio['nome_usuario'] ?? '---'),
                              _buildInfoRow(
  Icons.phone,
  "Telefone",
  relatorio['telefone_usuario'] != null && relatorio['telefone_usuario'].toString().isNotEmpty
      ? formatarTelefone(relatorio['telefone_usuario'].toString())
      : '---',
),
                              const SizedBox(height: 12),

                              Text(
                                "Produtos:",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.brown.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: fetchProdutosDoPedido(
                                  relatorio['idRelatorio_Pedido'],
                                  relatorio['Usuario_idUsuario'],
                                ),
                                builder: (context, snapshotProdutos) {
                                  if (snapshotProdutos.connectionState == ConnectionState.waiting) {
                                    return Text("Carregando...", style: GoogleFonts.poppins(fontSize: 13));
                                  }
                                  if (snapshotProdutos.hasError || !snapshotProdutos.hasData) {
                                    return Text("Erro ao carregar", style: GoogleFonts.poppins(fontSize: 13));
                                  }

                                  final produtos = snapshotProdutos.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: produtos.map<Widget>((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Text("• ", style: GoogleFonts.poppins(fontSize: 13, color: Colors.brown.shade700)),
                                            Expanded(
                                              child: Text(
                                                "${item['quantidade']}x ${item['nome']} - R\$ ${item['preco_unitario'].toStringAsFixed(2).replaceAll('.', ',')}",
                                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                              if (relatorio['observacao'] != null && relatorio['observacao'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          relatorio['observacao'],
                                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              CustomPaint(
                                painter: DashedLinePainter(),
                                child: const SizedBox(height: 1, width: double.infinity),
                              ),
                              const SizedBox(height: 12),

                              _buildInfoRow(Icons.payment, "Pagamento", relatorio['tipo_pagamento'] ?? '---'),
                              _buildInfoRow(Icons.calendar_today, "Data", formattedDate),
                              
                              if (relatorio['valor_frete'] != null)
                                _buildInfoRow(
                                  Icons.local_shipping,
                                  "Frete",
                                  "R\$ ${relatorio['valor_frete'].toStringAsFixed(2).replaceAll('.', ',')}",
                                ),
                              
                              if (relatorio['valor_desconto'] != null)
                                _buildInfoRow(
                                  Icons.discount,
                                  "Desconto",
                                  "- R\$ ${relatorio['valor_desconto'].toStringAsFixed(2).replaceAll('.', ',')}",
                                  valueColor: Colors.green,
                                ),

                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                    Text(
                                      "R\$ ${relatorio['valor_total'].toStringAsFixed(2).replaceAll('.', ',')}",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              Divider(color: Colors.brown.shade200),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      relatorio['endereco'] ?? 'Não informado',
                                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(
                                    'Alterar Status',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.brown.shade700,
                                    side: BorderSide(color: Colors.brown.shade700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _mostrarDialogoStatus(relatorio['idRelatorio_Pedido'], status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: relatoriosFiltrados.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown.shade700,
        onPressed: () {
          setState(() {
            _relatoriosFuture = fetchRelatorios();
          });
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
