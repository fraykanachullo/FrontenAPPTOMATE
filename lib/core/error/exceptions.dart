class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, [this.statusCode]);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  AuthException(this.message, [this.statusCode]);
}

class TfliteException implements Exception {
  final String message;
  TfliteException(this.message);
}
