import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/routes.dart';
import '../global/user_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();
class SolidLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  SolidLinePainter({this.color = Colors.brown, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      //print('Ey, $userData?["nome"] seus dados entrou aqui: $userData');
      if (userData != null && userData['id'] != null) {
        setState(() {
          _ordersFuture = fetchOrders(userData['id']);
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchOrders(int usuarioId) async {
    final url = Uri.parse('$baseUrl/listar_pedidos/$usuarioId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      //print(data);
      return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Erro ao carregar pedidos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 232, 225),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Café Gourmet',
          style: GoogleFonts.pacifico(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              iconSize: 30,
              onPressed: () {
                Navigator.pushNamed(context, Routes.profile);
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum pedido encontrado"));
          }

          final orders = snapshot.data!;
        
          //print(orders);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(orders.length, (index) {
                  final order = orders[orders.length - 1 - index];
                  // Data segura
                  final dateStr = order['data_status']; // "Tue, 28 Oct 2025 00:31:54 GMT
                  DateTime orderDate;
                  try {
                    orderDate = HttpDate.parse(dateStr); // já entende RFC 1123
                  } catch (_) {
                    orderDate = DateTime.now(); // fallback
                  }
                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(orderDate);
          

                  // Status
                  String status = order['status'] ?? "realizado";
                  // Cardo com as informações
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
                            "Pedido #${orders.length - index}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),

                          const SizedBox(height: 4),
                          const Divider(thickness: 2, color: Colors.brown),
                          ...order['items'].map<Widget>((item) => Text(
                              "${item['quantidade']}x ${item['nome']} - R\$ ${item['preco_unitario'].toStringAsFixed(2).replaceAll('.', ',')}")),
                          const SizedBox(height: 6),
                          CustomPaint(
                            painter: DashedLinePainter(),
                            child: const SizedBox(height: 1, width: double.infinity),
                          ),
                          const SizedBox(height: 6),
                          Text("Pagamento: ${order['tipo_pagamento'] ?? 'Não informado'}"),

                          Text("Data/Hora: $formattedDate"),
                          if (order['valor_frete'] != null && order['valor_frete'] > 0)
                            Text(
                              "Frete: R\$ ${order['valor_frete'].toStringAsFixed(2).replaceAll('.', ',')}",
                            ),
                          if (order['valor_desconto'] != null && order['valor_desconto'] > 0)
                            Text(
                              "Desconto: - R\$ ${order['valor_desconto'].toStringAsFixed(2).replaceAll('.', ',')}",
                              style: const TextStyle(color: Colors.green),
                            ),
                          Text(
                              "Total: R\$ ${order['valor_total'].toStringAsFixed(2).replaceAll('.', ',')}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          CustomPaint(
                            painter: SolidLinePainter(),
                            child: const SizedBox(height: 2, width: double.infinity),
                          ),
                          const SizedBox(height: 6),
                          if (order['endereco'] != null)
                            Text("Entrega: ${order['endereco']}"),
                          const SizedBox(height: 6),
                          Row(
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


