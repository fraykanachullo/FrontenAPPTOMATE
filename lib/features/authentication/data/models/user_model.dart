class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String? organization;
  final String? role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.organization,
    this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'organization': organization,
      'role': role ?? 'agricultor',
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      organization: map['organization'],
      role: map['role'] ?? 'agricultor',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}