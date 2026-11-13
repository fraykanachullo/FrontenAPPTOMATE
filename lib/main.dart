import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/model_info.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: el contenido se extiende hasta el fondo de la pantalla y la
  // gesture bar del sistema (gestos) se dibuja encima, sin franja reservada.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ApiConstants.load();
  await ModelInfo.load();
  await InferenceSettings.load();
  await di.init();
  runApp(const TomatoDetectionApp());
}
