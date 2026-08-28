import 'package:dio/dio.dart';
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
        // 401/423/503 manejo básico, retry 1 vez con backoff
        if (e.response?.statusCode == 401) {
          // Podría intentar refresh aquí si hay refresh_token
        }
        return handler.next(e);
      },
    ));
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
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
