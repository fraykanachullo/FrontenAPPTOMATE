import 'package:equatable/equatable.dart';
import 'detection_entity.dart';

class DiagnosticEntity extends Equatable {
  final String diagnosticId;
  final String status;
  final String createdAt;
  final int? processingTimeMs;
  final String? imageUrl;
  final Map<String, dynamic>? imageDimensions;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> modelInfo;
  final List<DetectionEntity> detections;
  const DiagnosticEntity({required this.diagnosticId, required this.status, required this.createdAt, this.processingTimeMs, this.imageUrl, this.imageDimensions, required this.summary, required this.modelInfo, required this.detections});
  @override
  List<Object?> get props => [diagnosticId, detections.length];
}
