import 'dart:ui';

class CoordinateTransformer {
  /// Convierte bbox normalizado [0,1] a coordenadas de pantalla
  static Rect normalizedToScreen(List<double> bboxNorm, Size imageSize, Size widgetSize) {
    // bboxNorm = [x_min, y_min, x_max, y_max] normalizado respecto a imagen original
    // Escalar al widget que muestra la imagen (BoxFit.contain maneja letterbox, aquí simplificado)
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    final offsetY = (widgetSize.height - imageSize.height * scale) / 2;
    return Rect.fromLTRB(
      bboxNorm[0] * imageSize.width * scale + offsetX,
      bboxNorm[1] * imageSize.height * scale + offsetY,
      bboxNorm[2] * imageSize.width * scale + offsetX,
      bboxNorm[3] * imageSize.height * scale + offsetY,
    );
  }

  /// Normaliza coordenadas absolutas 640x640 a [0,1]
  static List<double> absoluteToNormalized(List<double> xyxy, double size) {
    return xyxy.map((v) => (v / size).clamp(0.0, 1.0)).toList();
  }
}
