import 'package:equatable/equatable.dart';

class BoundingBox extends Equatable {
  final double xMin, yMin, xMax, yMax;
  const BoundingBox({required this.xMin, required this.yMin, required this.xMax, required this.yMax});
  @override
  List<Object?> get props => [xMin, yMin, xMax, yMax];
  factory BoundingBox.fromJson(Map<String, dynamic> j) => BoundingBox(xMin: (j["x_min"] as num).toDouble(), yMin: (j["y_min"] as num).toDouble(), xMax: (j["x_max"] as num).toDouble(), yMax: (j["y_max"] as num).toDouble());
}

class DetectionEntity extends Equatable {
  final String diseaseLabel;
  final String? scientific, spanish;
  final double confidence;
  final String severity;
  final BoundingBox bbox;
  const DetectionEntity({required this.diseaseLabel, this.scientific, this.spanish, required this.confidence, required this.severity, required this.bbox});
  @override
  List<Object?> get props => [diseaseLabel, confidence, bbox];
}
