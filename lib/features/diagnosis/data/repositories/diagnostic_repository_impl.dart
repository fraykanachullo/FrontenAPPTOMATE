import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/features/diagnosis/data/datasources/diagnostic_remote_datasource.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/entities/detection_entity.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/entities/diagnostic_entity.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/repositories/i_diagnostic_repository.dart';

class DiagnosticRepositoryImpl implements IDiagnosticRepository {
  final DiagnosticRemoteDataSource remote;
  DiagnosticRepositoryImpl(this.remote);

  DiagnosticEntity _toEntity(Map<String, dynamic> j) {
    final dets = (j["detections"] as List? ?? []).map((d) {
      final bb = d["bounding_box"] as Map<String, dynamic>;
      return DetectionEntity(
        diseaseLabel: d["disease_label"],
        scientific: d["disease_name_scientific"],
        spanish: d["disease_name_spanish"],
        confidence: (d["confidence_score"] as num).toDouble(),
        severity: d["severity_level"] ?? "MILD",
        bbox: BoundingBox.fromJson(bb),
      );
    }).toList();
    return DiagnosticEntity(
      diagnosticId: j["diagnostic_id"] ?? j["id"] ?? "",
      status: j["status"] ?? "completed",
      createdAt: j["created_at"] ?? DateTime.now().toIso8601String(),
      processingTimeMs: j["processing_time_ms"],
      imageUrl: j["image_url"],
      imageDimensions: j["image_dimensions"],
      summary: Map<String,dynamic>.from(j["summary"] ?? {}),
      modelInfo: Map<String,dynamic>.from(j["model_info"] ?? {}),
      detections: dets,
    );
  }

  @override
  Future<Either<Failure, DiagnosticEntity>> sendDiagnostic(String imagePath, Map<String, dynamic> metadata) async {
    try {
      final data = await remote.sendDiagnostic(imagePath, metadata);
      return Right(_toEntity(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return Left(AuthFailure("No autenticado"));
      if (e.response?.statusCode == 413) return Left(ServerFailure("Imagen muy grande"));
      return Left(ServerFailure(e.response?.data?["detail"]?.toString() ?? e.message ?? "Error diagnóstico"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DiagnosticEntity>>> getHistory({int limit = 20, int offset = 0}) async {
    try {
      final list = await remote.getDiagnostics(limit: limit, offset: offset);
      return Right(list.map((e) => _toEntity(Map<String,dynamic>.from(e))).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
