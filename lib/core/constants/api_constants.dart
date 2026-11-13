import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // URL por defecto (primera instalación). Luego se cambia desde la app:
  // pantalla de login -> tocar "Servidor: ..." (se guarda en el celular).
  // Obtener la IP con 'ipconfig' -> Adaptador Wi-Fi -> IPv4. PC y celular en la misma red.
  static const String defaultBaseUrl = "http://localhost:8000";
  static const String _prefsKey = "backend_base_url";

  static String baseUrl = defaultBaseUrl;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_prefsKey) ?? defaultBaseUrl;
  }

  static Future<void> save(String url) async {
    var u = url.trim();
    if (!u.startsWith("http://") && !u.startsWith("https://")) u = "http://$u";
    if (u.endsWith("/")) u = u.substring(0, u.length - 1);
    baseUrl = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, u);
  }

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
