class ApiConstants {
  static const String baseUrl = "http://192.168.1.53:8000"; // PC WiFi 192.168.1.53 - cel 192.168.1.42 (misma red)
  // static const String baseUrl = "http://10.0.2.2:8000"; // emulador
  static const String login = "/api/v1/auth/login";
  static const String register = "/api/v1/auth/register";
  static const String refresh = "/api/v1/auth/refresh";
  static const String logout = "/api/v1/auth/logout";
  static const String me = "/api/v1/users/me";
  static const String users = "/api/v1/users";
  static const String diagnosticDetect = "/api/v1/diagnostic/detect";
  static const String diagnostics = "/api/v1/diagnostic";
  static const String plots = "/api/v1/plots";
  static const String health = "/api/v1/health";
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
