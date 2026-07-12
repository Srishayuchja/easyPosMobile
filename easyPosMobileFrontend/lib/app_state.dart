import 'package:flutter/foundation.dart';
import 'models/user_model.dart';
import 'models/product_model.dart';
import 'models/sale_model.dart';
import 'models/cart_item_model.dart';
import 'models/approval_request_model.dart';
import 'data/services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? currentUser;
  String? currentRole;

  List<ProductModel> products = [];
  List<SaleModel> sales = [];
  List<CartItemModel> cart = [];
  List<String> brands = [];
  List<String> units = ['pcs', 'g', 'kg', 'ml', 'L', 'box', 'pack'];
  List<ApprovalRequestModel> pendingApprovals = [];
  List<ApprovalRequestModel> myRequests = [];

  bool _loading = false;
  bool get loading => _loading;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    products = await ApiService.instance.fetchProducts();
    sales = await ApiService.instance.fetchSales();
    brands = products.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().toList()..sort();
    if (currentRole == 'admin') {
      pendingApprovals = await ApiService.instance.fetchApprovals();
    } else if (currentRole == 'cashier') {
      myRequests = await ApiService.instance.fetchMyRequests();
    }
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

  void clearCart() {
    cart = [];
    notifyListeners();
  }

  // ─── Checkout ──────────────────────────────────────────────────────────────

  Future<SaleModel> submitSale() async {
    final subtotal = cartTotal;
    const tax = 0.0;
    final total = subtotal;
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

  /// Returns true if the product was created immediately (admin), false if it
  /// was submitted for admin approval instead (cashier).
  Future<bool> addProduct(ProductModel product) async {
    final saved = await ApiService.instance.createProduct(product);
    if (saved == null) return false;
    products.add(saved);
    notifyListeners();
    return true;
  }

  void addBrand(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || brands.any((b) => b.toLowerCase() == trimmed.toLowerCase())) return;
    brands.add(trimmed);
    brands.sort();
    notifyListeners();
  }

  void addUnit(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || units.any((u) => u.toLowerCase() == trimmed.toLowerCase())) return;
    units.add(trimmed);
    notifyListeners();
  }

  /// Returns true if stock was applied immediately (admin), false if it was
  /// submitted for admin approval instead (cashier).
  Future<bool> addStock(String productId, int qty) async {
    final applied = await ApiService.instance.recordPurchase(
      productId: productId,
      qty: qty,
      unitCost: products.firstWhere((p) => p.id == productId).buy,
    );
    if (!applied) return false;
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx >= 0) {
      products[idx] = products[idx].copyWith(stock: products[idx].stock + qty);
      notifyListeners();
    }
    return true;
  }

  // ─── Approvals (Admin) ──────────────────────────────────────────────────────

  Future<void> fetchApprovals() async {
    pendingApprovals = await ApiService.instance.fetchApprovals();
    notifyListeners();
  }

  Future<void> approveRequest(int id, {double? buy}) async {
    await ApiService.instance.approveRequest(id, buy: buy);
    pendingApprovals.removeWhere((r) => r.id == id);
    notifyListeners();
    await initialize();
  }

  Future<void> rejectRequest(int id) async {
    await ApiService.instance.rejectRequest(id);
    pendingApprovals.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> approveAllRequests() async {
    await ApiService.instance.approveAllRequests();
    pendingApprovals = [];
    notifyListeners();
    await initialize();
  }

  // ─── Requests (Cashier) ─────────────────────────────────────────────────────

  Future<void> fetchMyRequests() async {
    myRequests = await ApiService.instance.fetchMyRequests();
    notifyListeners();
  }

  // ─── Computed helpers ──────────────────────────────────────────────────────

  List<SaleModel> get todaySales {
    final now = DateTime.now();
    return sales.where((s) =>
        s.timestamp.year == now.year && s.timestamp.month == now.month && s.timestamp.day == now.day).toList();
  }

  double get todayTotal => todaySales.fold(0.0, (s, x) => s + x.total);
  int get lowStockCount => products.where((p) => p.stock < p.alertQty).length;
  double get avgSale => todaySales.isEmpty ? 0 : todayTotal / todaySales.length;

  List<ProductModel> searchProducts(String q) {
    if (q.isEmpty) return products;
    final lower = q.toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(lower) || p.barcode.contains(q))
        .toList();
  }

  ProductModel? findByBarcode(String code) {
    for (final p in products) {
      if (p.barcode == code) return p;
    }
    final loose = searchProducts(code);
    return loose.isNotEmpty ? loose.first : null;
  }
}
