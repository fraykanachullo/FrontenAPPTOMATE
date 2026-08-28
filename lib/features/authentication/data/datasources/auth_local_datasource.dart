import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUserJson(String jsonStr);
  Future<String?> getUserJson();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _kAccess = "access_token";
  static const _kRefresh = "refresh_token";
  static const _kUser = "user_json";

  @override
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  @override
  Future<String?> getAccessToken() => _storage.read(key: _kAccess);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }

  @override
  Future<void> saveUserJson(String jsonStr) => _storage.write(key: _kUser, value: jsonStr);

  @override
  Future<String?> getUserJson() => _storage.read(key: _kUser);
}
