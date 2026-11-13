import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tomate_detection_app/core/constants/api_constants.dart';
import 'package:tomate_detection_app/core/network/dio_client.dart';

class DiagnosticRemoteDataSource {
  final DioClient dioClient;
  DiagnosticRemoteDataSource(this.dioClient);

  Future<Map<String, dynamic>> sendDiagnostic(String imagePath, Map<String, dynamic> metadata) async {
    final form = FormData.fromMap({
      "file": await MultipartFile.fromFile(imagePath, filename: "image.jpg"),
      "metadata": jsonEncode(metadata),
    });
    final r = await dioClient.dio.post(ApiConstants.diagnosticDetect, data: form, options: Options(contentType: "multipart/form-data"));
    if (r.statusCode == 200) return r.data as Map<String, dynamic>;
    throw DioException(requestOptions: r.requestOptions, response: r);
  }

  Future<List<dynamic>> getDiagnostics({int limit = 20, int offset = 0, bool mine = true}) async {
    final r = await dioClient.dio.get(ApiConstants.diagnostics, queryParameters: {"limit": limit, "offset": offset, "mine": mine});
    return r.data as List<dynamic>;
  }

  /// Descarga la imagen de un diagnostico (URL relativa /uploads/... o absoluta).
  Future<void> downloadImage(String url, String savePath) async {
    final full = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
    await dioClient.dio.download(full, savePath);
  }
}
