import 'package:dio/dio.dart';
import 'package:tomate_detection_app/core/constants/api_constants.dart';
import 'package:tomate_detection_app/core/network/dio_client.dart';

class AuthRemoteDataSource {
  final DioClient dioClient;
  AuthRemoteDataSource(this.dioClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await dioClient.dio.post(ApiConstants.login, data: {"email": email, "password": password});
    if (r.statusCode == 200) return r.data as Map<String, dynamic>;
    throw DioException(requestOptions: r.requestOptions, response: r);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final r = await dioClient.dio.post(ApiConstants.register, data: {"name": name, "email": email, "password": password, "role": role});
    if (r.statusCode == 201 || r.statusCode == 200) return r.data as Map<String, dynamic>;
    throw DioException(requestOptions: r.requestOptions, response: r);
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final r = await dioClient.dio.post(ApiConstants.refresh, data: {"refresh_token": refreshToken});
    return r.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await dioClient.dio.post(ApiConstants.logout);
  }

  Future<Map<String, dynamic>> getMe() async {
    final r = await dioClient.dio.get(ApiConstants.me);
    return r.data as Map<String, dynamic>;
  }
}

// Aliases para injection_container
typedef AuthRemoteDataSourceImpl = AuthRemoteDataSource;
