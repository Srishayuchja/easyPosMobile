import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../models/cart_item_model.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _baseUrl = 'http://192.168.1.9/easypos/api';

  String? _token;
  String? _cashierId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<UserModel?> login(String username, String password, String role) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _token = data['token'] as String;
    final user = UserModel.fromMap(data['user'] as Map<String, dynamic>);
    _cashierId = user.id;
    return user;
  }

  Future<void> logout() async {
    _token = null;
    _cashierId = null;
  }

  // ─── Products ──────────────────────────────────────────────────────────────

  Future<List<ProductModel>> fetchProducts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    return product;
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    return product;
  }

  Future<void> deleteProduct(String id) async {}

  // ─── Purchases / Stock ────────────────────────────────────────────────────

  Future<void> recordPurchase({
    required String productId,
    required int qty,
    required double unitCost,
    String? supplier,
  }) async {}

  // ─── Sales ─────────────────────────────────────────────────────────────────

  Future<List<SaleModel>> fetchSales() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/sales'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return SaleModel(
        id: m['id'] as String,
        itemCount: m['itemCount'] as int,
        subtotal: (m['subtotal'] as num).toDouble(),
        tax: (m['tax'] as num).toDouble(),
        total: (m['total'] as num).toDouble(),
        timestamp: DateTime.parse(m['timestamp'] as String),
        cashier: m['cashier'] as String,
      );
    }).toList();
  }

  Future<SaleModel> submitSale({
    required List<CartItemModel> items,
    required double subtotal,
    required double tax,
    required double total,
    required String cashier,
    required String invoiceId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/sales'),
      headers: _headers,
      body: jsonEncode({
        'invoiceId': invoiceId,
        'cashierId': int.tryParse(_cashierId ?? '0') ?? 0,
        'cashier': cashier,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': 'cash',
        'items': items
            .map((i) => {
                  'productId': int.tryParse(i.product.id) ?? 0,
                  'qty': i.qty,
                  'price': i.price,
                })
            .toList(),
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to submit sale: ${res.body}');
    }
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return SaleModel(
      id: m['id'] as String,
      items: items,
      itemCount: m['itemCount'] as int,
      subtotal: (m['subtotal'] as num).toDouble(),
      tax: (m['tax'] as num).toDouble(),
      total: (m['total'] as num).toDouble(),
      timestamp: DateTime.parse(m['timestamp'] as String),
      cashier: cashier,
    );
  }
}
