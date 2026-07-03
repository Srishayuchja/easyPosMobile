import 'package:flutter/foundation.dart';
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/sale_model.dart';
import 'models/cart_item_model.dart';
import 'data/services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? currentUser;
  String? currentRole;

  List<ProductModel> products = [];
  List<SaleModel> sales = [];
  List<CartItemModel> cart = [];

  bool _loading = false;
  bool get loading => _loading;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    products = await ApiService.instance.fetchProducts();
    sales = await ApiService.instance.fetchSales();
    _loading = false;
    notifyListeners();
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password, String role) async {
    final user = await ApiService.instance.login(username, password, role);
    if (user == null) return false;
    currentUser = user;
    currentRole = user.role;
    notifyListeners();
    await initialize();
    return true;
  }

  void logout() {
    currentUser = null;
    currentRole = null;
    cart = [];
    notifyListeners();
  }

  // ─── Cart ──────────────────────────────────────────────────────────────────

  void addToCart(ProductModel product, {int qty = 1}) {
    final idx = cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(qty: cart[idx].qty + qty);
    } else {
      cart.add(CartItemModel(product: product, qty: qty, price: product.sell));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void changeQty(String productId, int qty) {
    final idx = cart.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(qty: qty);
      notifyListeners();
    }
  }

  void changePrice(String productId, double price) {
    final idx = cart.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(price: price);
      notifyListeners();
    }
  }

  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  double get cartTotal => cart.fold(0.0, (s, i) => s + i.lineTotal);

  // ─── Checkout ──────────────────────────────────────────────────────────────

  Future<SaleModel> submitSale() async {
    final subtotal = cartTotal;
    final tax = (subtotal * 0.05);
    final total = subtotal + tax;
    final invoiceId = 'INV-${2088 + sales.length}';

    final sale = await ApiService.instance.submitSale(
      items: List.from(cart),
      subtotal: subtotal,
      tax: tax,
      total: total,
      cashier: currentUser?.name ?? 'Cashier',
      invoiceId: invoiceId,
    );

    // Deduct stock
    for (final item in cart) {
      final idx = products.indexWhere((p) => p.id == item.product.id);
      if (idx >= 0) {
        products[idx] = products[idx].copyWith(
          stock: (products[idx].stock - item.qty).clamp(0, 999999),
        );
      }
    }

    sales.insert(0, sale);
    cart = [];
    notifyListeners();
    return sale;
  }

  // ─── Products (Admin) ──────────────────────────────────────────────────────

  Future<void> addProduct(ProductModel product) async {
    final saved = await ApiService.instance.createProduct(product);
    products.add(saved);
    notifyListeners();
  }

  Future<void> addStock(String productId, int qty) async {
    await ApiService.instance.recordPurchase(
      productId: productId,
      qty: qty,
      unitCost: products.firstWhere((p) => p.id == productId).buy,
    );
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      products[idx] = products[idx].copyWith(stock: products[idx].stock + qty);
      notifyListeners();
    }
  }

  // ─── Computed helpers ──────────────────────────────────────────────────────

  double get todayTotal => sales.fold(0.0, (s, x) => s + x.total);
  int get lowStockCount => products.where((p) => p.stock < 15).length;
  double get avgSale => sales.isEmpty ? 0 : todayTotal / sales.length;

  List<ProductModel> searchProducts(String q) {
    if (q.isEmpty) return products;
    final lower = q.toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(lower) || p.barcode.contains(q))
        .toList();
  }
}
