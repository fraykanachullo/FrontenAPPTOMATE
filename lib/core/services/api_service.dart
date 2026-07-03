import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tomate_detection_app/core/constants/api_config.dart';

class ApiService {
  Future<Map<String, dynamic>> detectDisease(XFile imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.detectEndpoint), // ✅ Usa la configuración centralizada
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        return data;
      } else {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conectando al servidor: $e');
    }
  }
}