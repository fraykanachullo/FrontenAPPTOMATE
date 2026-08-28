import 'package:dartz/dartz.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/core/usecases/usecase.dart';
import 'package:tomate_detection_app/features/authentication/domain/entities/user_entity.dart';
import 'package:tomate_detection_app/features/authentication/domain/repositories/i_auth_repository.dart';

class LoginParams {
  final String email, password;
  LoginParams(this.email, this.password);
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final IAuthRepository repo;
  LoginUseCase(this.repo);
  @override
  Future<Either<Failure, UserEntity>> call(LoginParams p) => repo.login(p.email, p.password);
}
