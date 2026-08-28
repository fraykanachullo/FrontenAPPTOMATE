import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/core/network/network_info.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:tomate_detection_app/features/authentication/domain/entities/user_entity.dart';
import 'package:tomate_detection_app/features/authentication/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  final NetworkInfo networkInfo;
  AuthRepositoryImpl({required this.remote, required this.local, required this.networkInfo});

  UserEntity _toEntity(Map<String, dynamic> j) => UserEntity(
    id: j["id"].toString(),
    name: j["name"] ?? "",
    email: j["email"] ?? "",
    role: j["role"] ?? "FIELD_TECH",
    isActive: j["is_active"] ?? true,
    createdAt: j["created_at"]?.toString(),
  );

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure("Sin internet"));
    try {
      final data = await remote.login(email, password);
      final user = _toEntity(data["user"]);
      await local.saveTokens(data["access_token"], data["refresh_token"]);
      await local.saveUserJson(jsonEncode(data["user"]));
      return Right(user);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?["detail"]?.toString() ?? e.message ?? "Error login";
      if (code == 401) return Left(AuthFailure("Credenciales inválidas"));
      if (code == 423) return Left(AuthFailure("Cuenta bloqueada, intente luego"));
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(String name, String email, String password, String role) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure("Sin internet"));
    try {
      final data = await remote.register(name, email, password, role);
      // register retorna user directo, no tokens; hacer login después si se desea
      return Right(_toEntity(data));
    } on DioException catch (e) {
      final msg = e.response?.data?["detail"]?.toString() ?? e.message ?? "Error registro";
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getMe() async {
    try {
      final data = await remote.getMe();
      return Right(_toEntity(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remote.logout();
    } catch (_) {}
    await local.clearTokens();
    return Right(null);
  }

  @override
  Future<bool> isLoggedIn() async {
    final t = await local.getAccessToken();
    return t != null && t.isNotEmpty;
  }
}
