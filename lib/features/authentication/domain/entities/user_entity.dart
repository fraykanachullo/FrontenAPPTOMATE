import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;
  UserEntity({required this.id, required this.name, required this.email, required this.role, required this.isActive, this.createdAt});
  @override
  List<Object?> get props => [id, email, role];
}
