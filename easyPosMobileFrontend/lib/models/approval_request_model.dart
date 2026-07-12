class ApprovalRequestModel {
  final int id;
  final String type; // 'new_product' or 'stock_add'
  final String summary;
  final String requestedByName;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved' or 'rejected'
  final int? productId;
  // Product's buying price at the time this 'stock_add' request was fetched, shown
  // to the admin as a default so they can keep it or change it (prices sometimes
  // drift between restocks).
  final double? currentBuy;

  const ApprovalRequestModel({
    required this.id,
    required this.type,
    required this.summary,
    required this.requestedByName,
    required this.requestedAt,
    this.status = 'pending',
    this.productId,
    this.currentBuy,
  });

  factory ApprovalRequestModel.fromMap(Map<String, dynamic> map) => ApprovalRequestModel(
        id: map['id'] as int,
        type: map['type'] as String,
        summary: map['summary'] as String,
        requestedByName: map['requestedByName'] as String,
        requestedAt: DateTime.parse(map['requestedAt'] as String),
        status: map['status'] as String? ?? 'pending',
        productId: map['productId'] as int?,
        currentBuy: (map['currentBuy'] as num?)?.toDouble(),
      );
}
