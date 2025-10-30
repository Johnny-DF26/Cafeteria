import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';


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
  final ScrollController _scrollController = ScrollController(); // 👈 Adicionado

  @override
  void initState() {
    super.initState();
    _relatoriosFuture = fetchRelatorios();
  }

  //=================================
  // Busca o relatório dos Pedidos
  //=================================
  Future<List<Map<String, dynamic>>> fetchRelatorios() async {
    final url = Uri.parse('http://192.168.0.167:5000/relatorios_pedidos'); // endpoint GET
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erro ao carregar relatórios');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProdutosDoPedido(int pedidoId, int usuarioId) async {
    final url = Uri.parse('http://192.168.0.167:5000/listar_pedidos/$usuarioId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      // Encontra o pedido correto na lista do usuário
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

  //================================
  // Atualiza o Status do Pedido
  //================================
  Future<void> atualizarStatus(int id, String novoStatus) async {
    final url = Uri.parse('http://192.168.0.167:5000/update_relatorios_pedidos/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': novoStatus}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado com sucesso!')),
      );
      setState(() {
        _relatoriosFuture = fetchRelatorios();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: ${response.body}')),
      );
    }
  }

  // Mudança do status do pedido
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
          title: const Text('Atualizar Status'),
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
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                atualizarStatus(id, selecionado);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  //=========================
  // Corpo da tela
  //=========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 232, 225),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _relatoriosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum relatório encontrado"));
          }

          final relatorios = snapshot.data!;

          // 👇 Faz o scroll ir para o final assim que os dados carregarem
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });

          return SingleChildScrollView(
            controller: _scrollController, // scroll
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(relatorios.length, (index) {
                  final relatorio = relatorios[relatorios.length - 1 - index];
                  final dataStr = relatorio['data_status']?.toString() ?? '';
                  DateTime data;

                  try {
                    data = HttpDate.parse(dataStr);
                  } catch (_) {
                    data = DateTime.now();
                    print('Erro ao converter data, usando atual.');
                  }

                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(data);
                  final status = relatorio['status'] ?? 'realizado';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pedido #${relatorio['idRelatorio_Pedido']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          const Divider(thickness: 2, color: Colors.brown),
                          Text("ID Usuário: ${relatorio['Usuario_idUsuario']}"),
                          Text("Produtos:"),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchProdutosDoPedido(
                                relatorio['idRelatorio_Pedido'], relatorio['Usuario_idUsuario']),
                            builder: (context, snapshotProdutos) {
                              if (snapshotProdutos.connectionState == ConnectionState.waiting) {
                                return const Text("Carregando produtos...");
                              } else if (snapshotProdutos.hasError) {
                                return Text("Erro: ${snapshotProdutos.error}");
                              } else if (!snapshotProdutos.hasData || snapshotProdutos.data!.isEmpty) {
                                return const Text("Nenhum produto encontrado");
                              }

                              final produtos = snapshotProdutos.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: produtos.map<Widget>((item) {
                                  return Text(
                                    "-- ${item['quantidade']}x ${item['nome']} - R\$ ${item['preco_unitario'].toStringAsFixed(2).replaceAll('.', ',')}",
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          Text("Observação: ${relatorio['observacao'] ?? '---'}"),
                          const SizedBox(height: 6),
                          CustomPaint(
                            painter: DashedLinePainter(),
                            child: const SizedBox(height: 1, width: double.infinity),
                          ),
                          const SizedBox(height: 6),
                          Text("Pagamento: ${relatorio['tipo_pagamento'] ?? '---'}"),
                          Text("Data: $formattedDate"),
                          if (relatorio['valor_frete'] != null)
                            Text("Frete: R\$ ${relatorio['valor_frete'].toStringAsFixed(2).replaceAll('.', ',')}"),
                          if (relatorio['valor_desconto'] != null)
                            Text("Desconto: - R\$ ${relatorio['valor_desconto'].toStringAsFixed(2).replaceAll('.', ',')}",
                                style: const TextStyle(color: Colors.green)),
                          Text(
                            "Total: R\$ ${relatorio['valor_total'].toStringAsFixed(2).replaceAll('.', ',')}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          const Divider(thickness: 2, color: Colors.brown),
                          Text("Endereço: ${relatorio['endereco'] ?? 'Não informado'}"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Status: ",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(status),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.brown),
                                onPressed: () =>
                                    _mostrarDialogoStatus(relatorio['idRelatorio_Pedido'], status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
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

  // Cores dos Status
  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('realizado')) return const Color.fromARGB(255, 255, 17, 0);
    if (s.contains('produção')) return Colors.blue;
    if (s.contains('pronto')) return Colors.purple;
    if (s.contains('a caminho')) return Colors.teal;
    if (s.contains('entregue')) return Colors.green;
    if (s.contains('cancelado')) return Colors.grey;

    return Colors.grey;
  }
}
