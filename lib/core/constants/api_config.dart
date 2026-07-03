class ApiConfig {
  // ⚠️ CAMBIA ESTA IP ANTES DE CADA PRESENTACIÓN
  // Usa el comando 'ipconfig' en CMD para obtener tu IP actual
  static const String baseUrl = 'http://10.148.127.84:8000';
  
  // 🔄 Para desarrollo local (emulador Android)
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // 🔄 Para dispositivo físico USB (sin Wi-Fi)
  // static const String baseUrl = 'http://localhost:8000';
  
  // 🔄 Para usar con ngrok (túneles públicos)
  // static const String baseUrl = 'https://tu-subdominio.ngrok.io';
  
  static const String detectEndpoint = '$baseUrl/detect';
  static const String healthEndpoint = '$baseUrl/health';
  static const String classesEndpoint = '$baseUrl/classes';
}