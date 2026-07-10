class ProductModel {
  final String id;
  final String name;
  final String barcode;
  final String unit;
  final double buy;
  final double sell;
  final int stock;
  final String brand;
  final int alertQty;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.unit,
    required this.buy,
    required this.sell,
    required this.stock,
    this.brand = '',
    this.alertQty = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] as String,
        name: map['name'] as String,
        barcode: map['barcode'] as String,
        unit: map['unit'] as String,
        buy: (map['buy'] as num).toDouble(),
        sell: (map['sell'] as num).toDouble(),
        stock: map['stock'] as int,
        brand: map['brand'] as String? ?? '',
        alertQty: map['alertQty'] as int? ?? 0,
      );

  ProductModel copyWith({
    String? id,
    String? name,
    String? barcode,
    String? unit,
    double? buy,
    double? sell,
    int? stock,
    String? brand,
    int? alertQty,
  }) =>
      ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        unit: unit ?? this.unit,
        buy: buy ?? this.buy,
        sell: sell ?? this.sell,
        stock: stock ?? this.stock,
        brand: brand ?? this.brand,
        alertQty: alertQty ?? this.alertQty,
      );
}
