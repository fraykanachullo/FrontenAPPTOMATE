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

  // Si Android restauro una copia de seguridad, los datos cifrados no se pueden leer con la clave
  // nueva y read() lanza una excepcion. Antes eso cortaba todas las peticiones (incluido el login).
  // Ahora se borra lo ilegible y se sigue como si no hubiera sesion.
  Future<String?> _leer(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() => _leer(_kAccess);

  @override
  Future<String?> getRefreshToken() => _leer(_kRefresh);

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }

  @override
  Future<void> saveUserJson(String jsonStr) => _storage.write(key: _kUser, value: jsonStr);

  @override
  Future<String?> getUserJson() => _leer(_kUser);
}
