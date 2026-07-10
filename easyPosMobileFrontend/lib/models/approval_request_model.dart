class ApprovalRequestModel {
  final int id;
  final String type; // 'new_product' or 'stock_add'
  final String summary;
  final String requestedByName;
  final DateTime requestedAt;

  const ApprovalRequestModel({
    required this.id,
    required this.type,
    required this.summary,
    required this.requestedByName,
    required this.requestedAt,
  });

  factory ApprovalRequestModel.fromMap(Map<String, dynamic> map) => ApprovalRequestModel(
        id: map['id'] as int,
        type: map['type'] as String,
        summary: map['summary'] as String,
        requestedByName: map['requestedByName'] as String,
        requestedAt: DateTime.parse(map['requestedAt'] as String),
      );
}
