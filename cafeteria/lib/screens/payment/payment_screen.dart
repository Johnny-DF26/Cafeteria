import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/routes.dart';
import '../global/global.dart';
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
    // Se a quantidade for 1, chama a função de remoção com confirmação
    await _removeItem(item);
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
    // Mostra diálogo de confirmação
    final shouldRemove = await showDialog<bool>(
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
              Expanded(
                child: Text(
                  'Remover Produto',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja remover "${item['name']}" do carrinho?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Remover',
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

    // Se o usuário confirmou a remoção
    if (shouldRemove == true) {
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

        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Produto removido com sucesso!',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );

        // Verifica se o carrinho está vazio após a remoção
        if (cartItems.isEmpty) {
          // Aguarda um momento para mostrar o SnackBar antes de sair
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // Volta para a tela de carrinho
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.cart,
              (route) => false,
            );
            
            // Mostra mensagem informando que o carrinho está vazio
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seu carrinho está vazio. Adicione produtos para continuar!',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erro ao remover produto',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
            const SnackBar(content: Text("⚠️ Por favor, selecione uma forma de pagamento!"), backgroundColor: Colors.red,),
          );
          return; // impede continuar
        }

        //=====================================
        // Condiciona a escolha de um endereço
        //=====================================
        if (deliveryOption == null && deliveryOption != 'novo') { // começa nulo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Por favor, selecione uma opção de entrega!"), backgroundColor: Colors.red,),
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
              const SnackBar(content: Text("⚠️ Nenhum endereço cadastrado!"), backgroundColor: Colors.red,),
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
              const SnackBar(content: Text("⚠️ Digite um novo endereço de entrega!"), backgroundColor: Colors.red,),
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
        SnackBar(
          content: Center(
            child: Text(
              "Pagamento confirmado e pedido gerado!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Erro ao salvar pedido!"), backgroundColor: Colors.red,),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Café Gourmet',
          style: GoogleFonts.pacifico(
            color: Colors.white,
            fontSize: 30,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título da seção
              Text(
                "Finalizar Pedido",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.brown.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Revise seu pedido e escolha o pagamento",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Card Resumo do pedido
              Card(
                elevation: 4,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shopping_bag,
                              color: Colors.brown.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Resumo do Pedido",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.brown.shade200),
                      const SizedBox(height: 8),
                      ...cartItems.map((item) {
                        String priceStr = item['price'].toString().replaceAll('R\$ ', '').replaceAll(',', '.');
                        double price = double.tryParse(priceStr) ?? 0;
                        double totalItem = price * (item['quantity'] ?? 1);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.brown.shade900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _removeItem(item),
                                    tooltip: 'Remover produto',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              color: Colors.orange.shade700,
                                              onPressed: () => _decreaseItem(item),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                "${item['quantity']}",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 16),
                                              color: Colors.green.shade700,
                                              onPressed: () => _increaseItem(item),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')} cada",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "R\$ ${totalItem.toStringAsFixed(2).replaceAll('.', ',')}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Endereço de entrega
              Card(
                elevation: 4,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Endereço de Entrega",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryOption(
                        Icons.store,
                        'Retirada no local',
                        'retirada',
                        'Retire seu pedido na loja',
                      ),
                      _buildDeliveryOption(
                        Icons.home,
                        'Endereço cadastrado',
                        'cadastrado',
                        'Use um endereço salvo',
                      ),
                      _buildDeliveryOption(
                        Icons.add_location,
                        'Outro endereço',
                        'novo',
                        'Informe um novo local',
                      ),

                      if (deliveryOption == 'novo') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: newDeliveryAddressController,
                          decoration: InputDecoration(
                            labelText: "Novo endereço",
                            hintText: "Rua, número, bairro, cidade...",
                            prefixIcon: Icon(Icons.edit_location, color: Colors.brown.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                            ),
                          ),
                        ),
                      ],

                      if (deliveryOption == 'cadastrado') ...[
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        if (userAddresses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Nenhum endereço cadastrado",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...userAddresses.asMap().entries.map((entry) {
                            int index = entry.key;
                            var address = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: selectedAddressIndex == index
                                    ? Colors.brown.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAddressIndex == index
                                      ? Colors.brown.shade700
                                      : Colors.grey.shade300,
                                  width: selectedAddressIndex == index ? 2 : 1,
                                ),
                              ),
                              child: RadioListTile<int>(
                                value: index,
                                groupValue: selectedAddressIndex,
                                onChanged: (value) {
                                  setState(() {
                                    selectedAddressIndex = value;
                                  });
                                },
                                title: Text(
                                  "${address['logradouro']}, ${address['numero']}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade900,
                                  ),
                                ),
                                subtitle: Text(
                                  "${address['bairro']}, ${address['cidade']}/${address['estado']} - CEP: ${address['cep']}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                activeColor: Colors.brown.shade700,
                              ),
                            );
                          }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Cupom
              Card(
                elevation: 4,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Cupom de Desconto",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: couponController,
                              decoration: InputDecoration(
                                hintText: "Código do cupom",
                                prefixIcon: Icon(Icons.confirmation_number, color: Colors.brown.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text("Cupom '${cupom['codigo']}' aplicado!"),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                              } else {
                                setState(() => discount = 0);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Expanded(child: Text("Cupom inválido ou expirado")),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "Aplicar",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Pagamento
              Card(
                elevation: 4,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Forma de Pagamento",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentOption(Icons.pix, "Pix", Colors.teal),
                      _buildPaymentOption(Icons.credit_card, "Cartão de Crédito", Colors.blue),
                      _buildPaymentOption(Icons.attach_money, "Dinheiro", Colors.green),
                      if (selectedPayment == "Cartão de Crédito") _buildCardFields(),
                      if (selectedPayment == "Pix") _buildPixCard(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow("Subtotal", calculateTotal()),
                _buildSummaryRow("Frete", shippingFee),
                if (discount > 0) _buildSummaryRow("Desconto", -discount, isDiscount: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSummaryRow("Total", totalWithDiscount, isTotal: true),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      _confirmPayment(totalWithDiscount);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "Confirmar Pagamento",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavigationBar(
            selectedItemColor: Colors.brown.shade700,
            unselectedItemColor: Colors.grey,
            currentIndex: 0,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Número do cartão inválido")));
      return false;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Validade inválida (MM/AA)")));
      return false;
    }
    if (cvv.length != 3 || int.tryParse(cvv) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ CVV inválido")));
      return false;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Nome no cartão é obrigatório")));
      return false;
    }
    return true;
  }

  Widget _buildSummaryRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? Colors.green.shade700 : Colors.grey.shade800,
            ),
          ),
          Text(
            "${isDiscount ? '- ' : ''}R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}",
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 20 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal
                  ? Colors.brown.shade700
                  : (isDiscount ? Colors.green.shade700 : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFields() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          TextField(
            controller: cardNumberController,
            decoration: InputDecoration(
              labelText: "Número do cartão",
              prefixIcon: const Icon(Icons.credit_card),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cardNameController,
            decoration: InputDecoration(
              labelText: "Nome no cartão",
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cardExpiryController,
                  decoration: InputDecoration(
                    labelText: "Validade",
                    hintText: "MM/AA",
                    prefixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cardCVVController,
                  decoration: InputDecoration(
                    labelText: "CVV",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPixCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pix, color: Colors.teal.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                "Pague com Pix",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: pixKey,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    pixKey,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 20),
              label: Text(
                "Copiar Chave Pix",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pixKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(child: Text("Chave Pix copiada!")),
                      ],
                    ),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String method, Color color) {
    final isSelected = selectedPayment == method;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: method,
        groupValue: selectedPayment,
        onChanged: (value) {
          setState(() {
            selectedPayment = value!;
          });
        },
        activeColor: color,
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              method,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(IconData icon, String title, String value, String subtitle) {
    final isSelected = deliveryOption == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.brown.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.brown.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: deliveryOption,
        onChanged: (val) {
          setState(() {
            deliveryOption = val!;
            shippingFee = val == 'retirada' ? 0 : 4.0;
          });
        },
        activeColor: Colors.brown.shade700,
        title: Row(
          children: [
            Icon(icon, color: Colors.brown.shade700, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      )
    );
  }
}

