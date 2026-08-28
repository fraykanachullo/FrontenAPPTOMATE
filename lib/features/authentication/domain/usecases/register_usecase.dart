import 'package:dartz/dartz.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/core/usecases/usecase.dart';
import 'package:tomate_detection_app/features/authentication/domain/entities/user_entity.dart';
import 'package:tomate_detection_app/features/authentication/domain/repositories/i_auth_repository.dart';

class RegisterParams {
  final String name, email, password, role;
  RegisterParams(this.name, this.email, this.password, this.role);
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final IAuthRepository repo;
  RegisterUseCase(this.repo);
  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams p) => repo.register(p.name, p.email, p.password, p.role);
}
