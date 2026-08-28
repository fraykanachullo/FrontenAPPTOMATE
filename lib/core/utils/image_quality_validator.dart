import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageQualityResult {
  final double meanLuminance;
  final double overexposedRatio;
  final double underexposedRatio;
  final bool isAcceptable;
  final String? warning;
  ImageQualityResult({
    required this.meanLuminance,
    required this.overexposedRatio,
    required this.underexposedRatio,
    required this.isAcceptable,
    this.warning,
  });
}

class ImageQualityValidator {
  /// Analiza en Isolate para no bloquear UI (500ms max)
  static Future<ImageQualityResult> analyze(Uint8List bytes) async {
    return await Isolate.run(() => _analyzeSync(bytes));
  }

  static ImageQualityResult _analyzeSync(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ImageQualityResult(meanLuminance: 0, overexposedRatio: 0, underexposedRatio: 100, isAcceptable: false, warning: "No se pudo decodificar imagen");
    }
    int total = decoded.width * decoded.height;
    double sumLum = 0;
    int over = 0, under = 0;
    for (int y = 0; y < decoded.height; y++) {
      for (int x = 0; x < decoded.width; x++) {
        final p = decoded.getPixel(x, y);
        // Y = 0.299R + 0.587G + 0.114B
        final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        sumLum += lum;
        if (lum > 240) over++;
        if (lum < 30) under++;
      }
    }
    final mean = sumLum / total;
    final overRatio = over / total * 100;
    final underRatio = under / total * 100;
    final acceptable = mean >= 60 && mean <= 200 && overRatio < 15 && underRatio < 10;
    String? warning;
    if (overRatio >= 15) warning = "Imagen con exceso de luz solar — Busque sombra parcial";
    else if (underRatio >= 10) warning = "Imagen demasiado oscura — Mejore la iluminación";
    else if (mean < 60) warning = "Imagen demasiado oscura";
    else if (mean > 200) warning = "Imagen sobreexpuesta";
    return ImageQualityResult(
      meanLuminance: mean,
      overexposedRatio: overRatio,
      underexposedRatio: underRatio,
      isAcceptable: acceptable,
      warning: warning,
    );
  }
}
