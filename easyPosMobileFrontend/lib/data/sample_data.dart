// All sample data lives here.
// TODO: Replace each method in ApiService with real HTTP calls to the MySQL backend.

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class SampleData {
  SampleData._();

  // ─── Users ─────────────────────────────────────────────────────────────────
  // TODO (backend): GET /api/auth/login  { username, password, role } → token + user
  static final List<UserModel> users = [
    const UserModel(id: 'u1', name: 'Nimal', username: 'nimal', role: 'cashier'),
    const UserModel(id: 'u2', name: 'Saman', username: 'saman', role: 'cashier'),
    const UserModel(id: 'u3', name: 'Admin', username: 'admin', role: 'admin'),
    const UserModel(id: 'u4', name: 'Kamal', username: 'kamal', role: 'admin'),
  ];

  // ─── Products ──────────────────────────────────────────────────────────────
  // TODO (backend): GET /api/products → List<Product>
  // TODO (backend): POST /api/products → Product (create)
  // TODO (backend): PUT  /api/products/:id → Product (update)
  // TODO (backend): DELETE /api/products/:id (delete)
  static final List<ProductModel> products = [
    const ProductModel(id: 'p1', name: 'Anchor Full Cream Milk',    barcode: '4792024031019', unit: '1L',      buy: 480, sell: 590, stock: 24),
    const ProductModel(id: 'p2', name: 'Maliban Cream Cracker',     barcode: '4792003001125', unit: '190g',    buy: 180, sell: 240, stock: 56),
    const ProductModel(id: 'p3', name: 'Munchee Marie',             barcode: '4792003002023', unit: '200g',    buy: 145, sell: 200, stock: 38),
    const ProductModel(id: 'p4', name: 'Dilmah Premium Tea',        barcode: '9312631121247', unit: '100 bags',buy: 720, sell: 950, stock: 14),
    const ProductModel(id: 'p5', name: 'Coca-Cola Bottle',          barcode: '5449000133335', unit: '500ml',   buy: 220, sell: 290, stock: 72),
    const ProductModel(id: 'p6', name: 'Highland Yoghurt',          barcode: '4792024088112', unit: '80g',     buy: 95,  sell: 130, stock: 41),
    const ProductModel(id: 'p7', name: 'Sunlight Detergent',        barcode: '8901030711015', unit: '1kg',     buy: 540, sell: 690, stock: 9),
    const ProductModel(id: 'p8', name: 'Elephant House Cream Soda', barcode: '4792024099051', unit: '400ml',   buy: 130, sell: 180, stock: 60),
  ];

  // ─── Sales History ─────────────────────────────────────────────────────────
  // TODO (backend): GET /api/sales?from=&to=&cashier= → List<Sale>
  // TODO (backend): POST /api/sales → Sale (create after checkout)
  static List<SaleModel> get sales {
    final now = DateTime.now();
    return [
      SaleModel(id: 'INV-2087', itemCount: 6,  subtotal: 2200, tax: 110, total: 2310, timestamp: now.subtract(const Duration(minutes: 14)),  cashier: 'Nimal'),
      SaleModel(id: 'INV-2086', itemCount: 2,  subtotal: 448,  tax: 22,  total: 470,  timestamp: now.subtract(const Duration(minutes: 47)),  cashier: 'Nimal'),
      SaleModel(id: 'INV-2085', itemCount: 11, subtotal: 5562, tax: 278, total: 5840, timestamp: now.subtract(const Duration(minutes: 92)),  cashier: 'Saman'),
      SaleModel(id: 'INV-2084', itemCount: 3,  subtotal: 1067, tax: 53,  total: 1120, timestamp: now.subtract(const Duration(minutes: 140)), cashier: 'Nimal'),
      SaleModel(id: 'INV-2083', itemCount: 8,  subtotal: 3581, tax: 179, total: 3760, timestamp: now.subtract(const Duration(hours: 4)),     cashier: 'Saman'),
      SaleModel(id: 'INV-2082', itemCount: 1,  subtotal: 276,  tax: 14,  total: 290,  timestamp: now.subtract(const Duration(hours: 5)),     cashier: 'Nimal'),
    ];
  }

  // ─── Auth helpers ──────────────────────────────────────────────────────────
  // TODO (backend): validate via JWT / session token
  static UserModel? authenticate(String username, String role) {
    // Demo: any non-empty username passes; role must match
    if (username.trim().isEmpty) return null;
    final existing = users.where(
      (u) => u.username.toLowerCase() == username.toLowerCase() && u.role == role,
    );
    if (existing.isNotEmpty) return existing.first;
    // Accept any username for demo
    return UserModel(
      id: 'u_demo',
      name: username.trim(),
      username: username.trim().toLowerCase(),
      role: role,
    );
  }
}
