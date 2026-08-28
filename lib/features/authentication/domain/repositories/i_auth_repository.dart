import 'package:dartz/dartz.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/features/authentication/domain/entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(String name, String email, String password, String role);
  Future<Either<Failure, UserEntity>> getMe();
  Future<Either<Failure, void>> logout();
  Future<bool> isLoggedIn();
}
