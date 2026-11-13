import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tomate_detection_app/core/constants/api_constants.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_local_datasource.dart';

class DioClient {
  final Dio dio;
  final AuthLocalDataSource? _local;

  DioClient(this._local) : dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {"Content-Type": "application/json"},
  )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // La URL puede cambiarse en tiempo de ejecucion (login -> Servidor)
        options.baseUrl = ApiConstants.baseUrl;
        // Agregar JWT si existe
        if (_local != null) {
          final token = await _local.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
        }
        // Request ID
        options.headers["X-Request-ID"] = DateTime.now().millisecondsSinceEpoch.toString();
        return handler.next(options);
      },
      onError: (e, handler) async {
        // Access token vencido (dura 8 h): renovar con el refresh token (30 dias)
        // y reintentar la peticion una vez, sin pedir la contraseña.
        final path = e.requestOptions.path;
        final isAuthCall = path.contains('/auth/');
        if (e.response?.statusCode == 401 && !isAuthCall && _local != null && e.requestOptions.extra['retried'] != true) {
          final newToken = await _refreshAccessToken();
          if (newToken != null) {
            final opts = e.requestOptions..extra['retried'] = true;
            opts.headers['Authorization'] = 'Bearer $newToken';
            try {
              return handler.resolve(await dio.fetch(opts));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
        }
        return handler.next(e);
      },
    ));
    // Sin cabeceras en el log: incluirian el token JWT completo
    if (kDebugMode) dio.interceptors.add(LogInterceptor(requestHeader: false, requestBody: false, responseBody: false));
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await _local!.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final r = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: ApiConstants.connectTimeout))
          .post(ApiConstants.refresh, data: {'refresh_token': refresh});
      final access = r.data['access_token'] as String?;
      if (access == null) return null;
      await _local.saveTokens(access, refresh);
      return access;
    } on DioException catch (err) {
      // Refresh vencido o revocado: la sesion termino, hay que volver a iniciar sesion
      if (err.response?.statusCode == 401) await _local.clearTokens();
      return null;
    }
  }

  // Helper para multipart diagnostic
  Future<Response> postMultipart(String path, {required String filePath, Map<String, dynamic>? metadata}) async {
    final form = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: "image.jpg"),
      if (metadata != null) "metadata": metadata.toString(),
    });
    // metadata como JSON string en form field
    if (metadata != null) {
      form.fields.removeWhere((e) => e.key == "metadata");
      form.fields.add(MapEntry("metadata", metadata.toString()));
    }
    return dio.post(path, data: form);
  }
}
