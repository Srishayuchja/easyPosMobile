import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int qty;
  final double price;

  const CartItemModel({
    required this.product,
    required this.qty,
    required this.price,
  });

  CartItemModel copyWith({ProductModel? product, int? qty, double? price}) =>
      CartItemModel(
        product: product ?? this.product,
        qty: qty ?? this.qty,
        price: price ?? this.price,
      );

  double get lineTotal => qty * price;
}
