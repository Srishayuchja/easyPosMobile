class UserModel {
  final String id;
  final String name;
  final String username;
  final String role; // 'cashier' or 'admin'
  final String branch;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.branch = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        username: map['username'] as String,
        role: map['role'] as String,
        branch: map['branch'] as String? ?? '',
      );
}
