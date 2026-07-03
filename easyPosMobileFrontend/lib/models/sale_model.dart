import 'cart_item_model.dart';

class SaleModel {
  final String id;
  final List<CartItemModel>? items; // null for summary-only records
  final int itemCount;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime timestamp;
  final String cashier;

  const SaleModel({
    required this.id,
    this.items,
    required this.itemCount,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.timestamp,
    required this.cashier,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) => SaleModel(
        id: map['id'] as String,
        itemCount: map['itemCount'] as int,
        subtotal: (map['subtotal'] as num).toDouble(),
        tax: (map['tax'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        timestamp: map['timestamp'] as DateTime,
        cashier: map['cashier'] as String,
      );
}
