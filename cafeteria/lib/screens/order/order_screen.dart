import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'dart:io';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();

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

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Future<List<Map<String, dynamic>>> _ordersFuture = Future.value([]);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      if (userData != null && userData['id'] != null) {
        setState(() {
          _ordersFuture = fetchOrders(userData['id']);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchOrders(int usuarioId) async {
    final url = Uri.parse('$baseUrl/listar_pedidos/$usuarioId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erro ao carregar pedidos');
    }
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
    return Colors.grey;
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final url = Uri.parse('$baseUrl/cancelar_pedido/$orderId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pedido cancelado com sucesso!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Recarrega a lista de pedidos
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final userData = userProvider.userData;
          if (userData != null && userData['id'] != null) {
            setState(() {
              _ordersFuture = fetchOrders(userData['id']);
            });
          }
        }
      } else {
        throw Exception('Erro ao cancelar pedido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao cancelar pedido: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(int orderId, String orderNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                'Cancelar Pedido',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja cancelar o $orderNumber?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Não',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sim, Cancelar',
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

  bool _canCancelOrder(String status) {
    return status.toLowerCase().contains('realizado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Barra superior
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.brown.shade700,
            expandedHeight: 110,
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.profile);
                  },
                ),
              ),
            ],
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
                    'Meus Pedidos',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acompanhe o histórico dos seus pedidos',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Lista de pedidos
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _ordersFuture,
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

              final orders = snapshot.data!;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[orders.length - 1 - index];
                      final dateStr = order['data_status'];
                      DateTime orderDate;

                      try {
                        orderDate = HttpDate.parse(dateStr);
                      } catch (_) {
                        orderDate = DateTime.now();
                      }

                      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(orderDate);
                      final status = order['status'] ?? 'realizado';
                      final orderId = order['idRelatorio_Pedido'] ?? (orders.length - index);
                      final canCancel = _canCancelOrder(status);

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
                                        "Pedido #${order['idRelatorio_Pedido'] ?? (orders.length - index)}",
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

                              // Produtos
                              Text(
                                "Produtos:",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.brown.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              ...order['items'].map<Widget>((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        "• ",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.brown.shade700,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "${item['quantidade']}x ${item['nome']} - R\$ ${item['preco_unitario'].toStringAsFixed(2).replaceAll('.', ',')}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              if (order['observacao'] != null && order['observacao'].toString().isNotEmpty) ...[
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
                                          order['observacao'],
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

                              _buildInfoRow(Icons.payment, "Pagamento", order['tipo_pagamento'] ?? 'Não informado'),
                              _buildInfoRow(Icons.calendar_today, "Data", formattedDate),
                              
                              if (order['valor_frete'] != null && order['valor_frete'] > 0)
                                _buildInfoRow(
                                  Icons.local_shipping,
                                  "Frete",
                                  "R\$ ${order['valor_frete'].toStringAsFixed(2).replaceAll('.', ',')}",
                                ),
                              
                              if (order['valor_desconto'] != null && order['valor_desconto'] > 0)
                                _buildInfoRow(
                                  Icons.discount,
                                  "Desconto",
                                  "- R\$ ${order['valor_desconto'].toStringAsFixed(2).replaceAll('.', ',')}",
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
                                      "R\$ ${order['valor_total'].toStringAsFixed(2).replaceAll('.', ',')}",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (order['endereco'] != null) ...[
                                const SizedBox(height: 12),
                                Divider(color: Colors.brown.shade200),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        order['endereco'],
                                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Botão de cancelar
                              if (canCancel) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCancelDialog(orderId, "Pedido #$orderId"),
                                    icon: const Icon(Icons.cancel, size: 20),
                                    label: Text(
                                      'Cancelar Pedido',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.brown.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) async {
          if (index == 0) {
            await Navigator.pushNamed(context, Routes.favorites);
          } else if (index == 1) {
            Navigator.pushNamed(context, Routes.home);
          } else if (index == 2) {
            Navigator.pushNamed(context, Routes.cart);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrinho'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown.shade700,
        onPressed: () {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final userData = userProvider.userData;
          if (userData != null && userData['id'] != null) {
            setState(() {
              _ordersFuture = fetchOrders(userData['id']);
            });
          }
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}


