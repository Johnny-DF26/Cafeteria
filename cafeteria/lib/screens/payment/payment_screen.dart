import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/routes.dart';
import '../global/global.dart'; // importa global.dart
import '../global/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cafeteria/screens/global/config.dart' as GlobalConfig;

String get baseUrl => GlobalConfig.GlobalConfig.api();


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedPayment;
  String? deliveryOption;
  final TextEditingController couponController = TextEditingController();
  final deliveryAddressController = TextEditingController();
  final newDeliveryAddressController = TextEditingController();
  double shippingFee = 4.0;
  double discount = 0;

  // Controllers com máscaras
  final cardNumberController = MaskedTextController(mask: '0000 0000 0000 0000');
  final cardExpiryController = MaskedTextController(mask: '00/00');
  final cardCVVController = MaskedTextController(mask: '000');
  final cardNameController = TextEditingController();

  final String pixKey = "cafeteria.digital@pagamentos.com";

  List<Map<String, dynamic>> cartItems = [];
  Map<String, dynamic>? deliveryAddress;
  List<Map<String, dynamic>> userAddresses = [];
  int? selectedAddressIndex;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;
      final userId = userData?['id'];
      fetchCart(userId);
      _loadAddresses();
    });
  }

  // Busca no Carrinho 
  Future<void> fetchCart(int? userId) async {
    if (userId == null) return;
    final response = await http.get(Uri.parse('$baseUrl/get_carrinho/$userId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        cartItems = data.map((item) => {
          'idCarrinhoProduto': item['id'],
          'idCarrinho': item['carrinho_id'],
          'idProduto': item['produto_id'],
          'name': item['nome'],
          'price': "R\$ ${item['valor']}",
          'quantity': item['quantidade'],
        }).toList();
      });
    }
  }


  Future<void> _decreaseItem(Map<String, dynamic> item) async {
  if (item['quantity'] <= 1) {
    _removeItem(item);
    return;
  }

  final newQuantity = item['quantity'] - 1;
  final response = await http.post(
    Uri.parse('$baseUrl/update_carrinho'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "idCarrinho_Produtos": item['idCarrinhoProduto'],
      "quantidade": newQuantity
    }),
  );

  if (response.statusCode == 200) {
    setState(() {
      item['quantity'] = newQuantity;
    });
  }
}

  // Atualiza o carrinho
  Future<void> _increaseItem(Map<String, dynamic> item) async {
    final newQuantity = item['quantity'] + 1;
    final response = await http.post(
      Uri.parse('$baseUrl/update_carrinho'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idCarrinho_Produtos": item['idCarrinhoProduto'],
        "quantidade": newQuantity
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        item['quantity'] = newQuantity;
      });
    }
  }

  // Remove produto do carrinho
  Future<void> _removeItem(Map<String, dynamic> item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/remove_produto_carrinho'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "carrinho_id": item['idCarrinho'],
        "produto_id": item['idProduto'],
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        cartItems.remove(item);
      });
    }
  }


  // Busca o Endereço do usuário
  Future<void> _loadAddresses() async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) return;

    final response = await http.get(
        Uri.parse('$baseUrl/endereco_usuario/${userData['id']}')
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body); // data já é uma lista
      setState(() {
        userAddresses = data.map((e) => {
          'id': e['id'],
          'logradouro': e['logradouro'],
          'numero': e['numero'],
          'bairro': e['bairro'],
          'cidade': e['cidade'],
          'estado': e['estado'],
          'cep': e['cep'],
        }).toList();
        if (userAddresses.isNotEmpty) selectedAddressIndex = 0;
      });
    } else {
      setState(() {
        userAddresses = [];
        selectedAddressIndex = null;
      });
    }
  }

  // Cartão de Crédito
  Future<void> _sendPayment(double total) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) return;

    int? cartaoId;
    if (selectedPayment == "Cartão de Crédito") {
      final resCard = await http.post(
        Uri.parse('$baseUrl/payment_card'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": cardNameController.text,
          "numero": cardNumberController.text.replaceAll(' ', ''),
          "validade": cardExpiryController.text,
          "cvv": cardCVVController.text,
          "forma_pagamento_id": 1, // exemplo para cartão
          "usuario_id": userData['id'],
        }),
      );
      if (resCard.statusCode == 200) {
        cartaoId = jsonDecode(resCard.body)['id'];
      }
    }

    // Enviar pagamento
    await http.post(
      Uri.parse('$baseUrl/pagamento'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usuario_id": userData['id'],
        "carrinho_id": 1, // aqui você precisa do idCarrinho do banco
        "endereco_id": deliveryOption == 'novo' ? null : 1, // id do endereço cadastrado
        "cartao_id": cartaoId,
        "cupom_id": null, // opcional, se tiver cupom
        "forma_pagamento_id": selectedPayment == 'Pix' ? 2 : selectedPayment == 'Cartão de Crédito' ? 1 : 3,
        "frete": shippingFee,
        "desconto": discount,
        "total": total,
      }),
    );
  }

  void _confirmPayment(double total) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
      //print(cartItems);
      // ===== PROCESSA ENDEREÇO PARA ENVIO =====
        String endereco = '';
        String pagamento = '';

        // Condiciona a escolher um pagamento
        if (selectedPayment == null) { // começa nulo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Por favor, selecione uma forma de pagamento!")),
          );
          return; // impede continuar
        }

        //=====================================
        // Condiciona a escolha de um endereço
        //=====================================
        if (deliveryOption == null && deliveryOption != 'novo') { // começa nulo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Por favor, selecione uma opção de entrega!")),
          );
          return; // impede continuar
        }
        // Caso seja retirada no local
        if (deliveryOption == "retirada") {
          endereco = "Retirada no local";
        }
        // Caso seja endereço Cadastrado
        else if (deliveryOption == "cadastrado") {
          if (userAddresses.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Nenhum endereço cadastrado!")),
            );
            return; // Impede continuar
          }
          var addr = userAddresses[selectedAddressIndex!];
          endereco = "${addr['logradouro']}, ${addr['numero']} - ${addr['bairro']} - ${addr['cidade']}/${addr['estado']} - CEP ${addr['cep']}";
        }
        // Caso endereço manual
        else if (deliveryOption == "novo") {
          if (newDeliveryAddressController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Digite um novo endereço de entrega!")),
            );
            return;
          }
          endereco = newDeliveryAddressController.text.trim();
        }
        //====================================
        // Condiciona o pagamento
        //====================================
        

    // Envio para API    
    final response = await http.post(
      Uri.parse("$baseUrl/criar_pedido"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usuario_id": userData?["id"],
        "deliveryOption": deliveryOption,
        "endereco": endereco,
        "valor_total": total,
        "valor_frete": shippingFee,
        "valor_desconto": discount,
        "pagamento": selectedPayment,
        "items": cartItems.map((item) => {
          "id": item["idProduto"],
          "quantity": item["quantity"],
          "price": double.parse(item["price"].replaceAll("R\$ ", "").replaceAll(",", "."))
        }).toList(),
      }),

    );

    if (response.statusCode == 200) {
      clearCartBackend(userData?["id"]); // Essa função limpa o carrinho de compras do bd
      cartItems.clear();
      Navigator.pushNamedAndRemoveUntil(context, Routes.order, (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pagamento confirmado e pedido gerado!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao salvar pedido!")),
      );
    }
  }

  // Limpar Carrinho 
  Future<void> clearCartBackend(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/limpar_carrinho/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": userId}),
    );
    if (response.statusCode != 200) {
      print("Erro ao limpar carrinho no servidor");
    }
  }


  //Calculo do total
  double calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      String priceStr =
          item['price'].toString().replaceAll('R\$ ', '').replaceAll(',', '.');
      double price = double.tryParse(priceStr) ?? 0;
      total += price * (item['quantity'] ?? 1);
    }
    return total;
  }


  // Calculo do desconto
  double get totalWithDiscount {
    double total = calculateTotal() + shippingFee - discount;
    if (total < 0) total = 0;
    return total;
  }

  // Corpo da Tela 
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;
    //print('Seus dados ${userData?['nome']} chegou em Pagamentos: $userData');
    double subtotal = calculateTotal();
    double total = totalWithDiscount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        centerTitle: true,
        title: Text('Café Gourmet', style: GoogleFonts.pacifico(color: Colors.white, fontSize: 26)),
        //leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(icon: const Icon(Icons.settings, color: Colors.white), iconSize: 30, onPressed: () {
              Navigator.pushNamed(context, Routes.profile);
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Resumo do pedido
              Text("Resumo do pedido", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
              const SizedBox(height: 10),
              ...cartItems.map((item) {
                String priceStr = item['price'].toString().replaceAll('R\$ ', '').replaceAll(',', '.');
                double price = double.tryParse(priceStr) ?? 0;
                double totalItem = price * (item['quantity'] ?? 1);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${item['quantity']} x R\$ ${double.parse(item['price'].toString().replaceAll('R\$ ', '').replaceAll(',', '.')).toStringAsFixed(2).replaceAll('.', ',')}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Diminuir quantidade
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.orange),
                        onPressed: () => _decreaseItem(item),
                      ),
                      // Quantidade
                      Text("${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Aumentar quantidade
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () => _increaseItem(item),
                      ),
                      // Remover totalmente
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(item),
                      ),
                      const SizedBox(width: 8),
                      // Total do item
                      Text("R\$ ${totalItem.toStringAsFixed(2).replaceAll('.', ',')}",
                          style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const Divider(thickness: 2, color:Color.fromARGB(255, 95, 66, 57)),
              const SizedBox(height: 10),
              
              // ==========================
              // Seção de entrega
              // ==========================
              Text(
                "Endereço de entrega",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radios principais
                  RadioListTile<String>(
                    value: 'retirada',
                    groupValue: deliveryOption,
                    onChanged: (value) {
                      setState(() {
                        deliveryOption = value!;
                        shippingFee = 0;
                      });
                    },
                    activeColor: Colors.brown.shade700,
                    title: const Text('Retirada no local'),
                  ),

                  RadioListTile<String>(
                    value: 'cadastrado',
                    groupValue: deliveryOption,
                    onChanged: (value) {
                      setState(() {
                        deliveryOption = value!;
                        shippingFee = 4.0;
                        if (userAddresses.isNotEmpty) {
                          selectedAddressIndex = 0;
                          var addr = userAddresses[0];
                          deliveryAddressController.text =
                              "${addr['logradouro']}, ${addr['numero']} - ${addr['bairro']}, ${addr['cidade']}/${addr['estado']} - CEP: ${addr['cep']}";
                        }
                      });
                    },
                    activeColor: Colors.brown.shade700,
                    title: const Text('Entregar no endereço cadastrado'),
                  ),

                  RadioListTile<String>(
                    value: 'novo',
                    groupValue: deliveryOption,
                    onChanged: (value) {
                      setState(() {
                        deliveryOption = value!;
                        shippingFee = 4.0;
                        deliveryAddressController.clear();
                      });
                    },
                    activeColor: Colors.brown.shade700,
                    title: const Text('Entregar em outro endereço'),
                  ),

                  // Campo de novo endereço
                  if (deliveryOption == 'novo')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        controller: newDeliveryAddressController,
                        decoration: InputDecoration(
                          labelText: "Novo endereço de entrega",
                          hintText: "Informe outro endereço, se necessário",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),

                  // Linha separadora visível apenas quando "Cadastrado" estiver selecionado
                  if (deliveryOption == 'cadastrado') ...[
                    const SizedBox(height: 8),
                    const Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Lista de endereços cadastrados
                    if (userAddresses.isEmpty)
                      Text(
                        "Nenhum endereço cadastrado",
                        style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                      )
                    else
                      Column(
                        children: userAddresses.asMap().entries.map((entry) {
                          int index = entry.key;
                          var address = entry.value;
                          return RadioListTile<int>(
                            value: index,
                            groupValue: selectedAddressIndex,
                            onChanged: (value) {
                              setState(() {
                                selectedAddressIndex = value;
                                if (value != null) {
                                  var addr = userAddresses[value];
                                  deliveryAddressController.text =
                                      "${addr['logradouro']}, ${addr['numero']} - ${addr['bairro']}, ${addr['cidade']}/${addr['estado']} - CEP: ${addr['cep']}";
                                }
                              });
                            },
                            title: Text(
                              "${address['logradouro']}, ${address['numero']} - ${address['bairro']}, ${address['cidade']}/${address['estado']} - CEP: ${address['cep']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            activeColor: Colors.brown.shade700,
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),


              const Divider(thickness: 2, color: Color.fromARGB(255, 95, 66, 57)),
              const SizedBox(height: 20),

              // Cupom de desconto
              Text("Cupom de desconto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: couponController,
                      decoration: InputDecoration(
                        hintText: "Insira o código do cupom",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white),
                    onPressed: () async {
                      final code = couponController.text.trim();
                      final response = await http.post(
                        Uri.parse('$baseUrl/validar_cupom'),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({"codigo": code}),
                      );
                      if (response.statusCode == 200) {
                        final cupom = jsonDecode(response.body);
                        setState(() {
                          final double cupomValue = cupom['desconto'] is String 
                              ? double.parse(cupom['desconto']) 
                              : cupom['desconto'].toDouble();

                          discount = (cupom['tipo_desconto'] == 'percentual')
                              ? calculateTotal() * (cupomValue / 100)
                              : cupomValue;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cupom '${cupom['codigo']}' aplicado!")));
                      } else {
                        setState(() => discount = 0);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cupom inválido ou expirado")));
                      }
                    },
                    child: const Text("Aplicar"),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Método de pagamento
              Text("Método de pagamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
              const SizedBox(height: 10),
              _buildPaymentOption(Icons.pix, "Pix"),
              _buildPaymentOption(Icons.credit_card, "Cartão de Crédito"),
              _buildPaymentOption(Icons.attach_money, "Dinheiro"),
              if (selectedPayment == "Cartão de Crédito") _buildCardFields(),
              if (selectedPayment == "Pix") _buildPixCard(),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.brown.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildSummaryRow("Subtotal", calculateTotal()),
              _buildSummaryRow("Frete", shippingFee),
              if (discount > 0) _buildSummaryRow("Desconto", -discount, isDiscount: true),
              const Divider(height: 20, thickness: 1),
              _buildSummaryRow("Total", totalWithDiscount, isTotal: true),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 197, 0, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _confirmPayment(totalWithDiscount);
                  },
                  child: const Text("Confirmar Pagamento", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        BottomNavigationBar(
          selectedItemColor: Colors.brown.shade700,
          unselectedItemColor: Colors.grey,
          currentIndex: 1, // ou o índice que fizer sentido para PaymentScreen
          onTap: (index) async {
            if (index == 0) {
              await Navigator.pushNamed(context, Routes.cart);
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
      ],
    ),
    );
  }
  

  bool _validateCard() {
    String number = cardNumberController.text.replaceAll(' ', '');
    String expiry = cardExpiryController.text;
    String cvv = cardCVVController.text;
    String name = cardNameController.text.trim();

    if (number.length != 16 || int.tryParse(number) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Número do cartão inválido")));
      return false;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validade inválida (MM/AA)")));
      return false;
    }
    if (cvv.length != 3 || int.tryParse(cvv) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CVV inválido")));
      return false;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nome no cartão é obrigatório")));
      return false;
    }
    return true;
  }

  Widget _buildSummaryRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold, color: isDiscount ? Colors.green : Colors.black)),
        Text("${isDiscount ? '- ' : ''}R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}", style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold, color: isTotal ? Colors.brown.shade700 : (isDiscount ? Colors.green : Colors.black))),
      ],
    );
  }

  Widget _buildCardFields() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          TextField(controller: cardNumberController, decoration: InputDecoration(labelText: "Número do cartão", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 10),
          TextField(controller: cardNameController, decoration: InputDecoration(labelText: "Nome no cartão", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: cardExpiryController, decoration: InputDecoration(labelText: "Validade (MM/AA)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
              const SizedBox(width: 5),
              Expanded(child: TextField(controller: cardCVVController, decoration: InputDecoration(labelText: "CVV", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPixCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shadowColor: Colors.brown.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Pague com Pix",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
                fontSize: 18,

              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [Colors.brown.shade50, Colors.brown.shade100]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  QrImageView(
                    data: pixKey,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    pixKey,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.brown.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text("Copiar Chave"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pixKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chave Pix copiada!")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String method) {
    return RadioListTile<String>(
      value: method,
      groupValue: selectedPayment,
      onChanged: (value) { setState(() { selectedPayment = value!; }); },
      activeColor: Colors.brown.shade700,
      title: Row(children: [Icon(icon, color: Colors.brown.shade700), const SizedBox(width: 10), Text(method, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]),
    );
  }
}

