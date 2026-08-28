import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String name, email, password, role;
  RegisterRequested(this.name, this.email, this.password, this.role);
}

class LogoutRequested extends AuthEvent {}

class CheckAuth extends AuthEvent {}
