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

  Future<List<dynamic>> getDiagnostics({int limit = 20, int offset = 0}) async {
    final r = await dioClient.dio.get(ApiConstants.diagnostics, queryParameters: {"limit": limit, "offset": offset});
    return r.data as List<dynamic>;
  }
}
