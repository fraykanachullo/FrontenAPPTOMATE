import 'package:dartz/dartz.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/entities/diagnostic_entity.dart';

abstract class IDiagnosticRepository {
  Future<Either<Failure, DiagnosticEntity>> sendDiagnostic(String imagePath, Map<String, dynamic> metadata);
  Future<Either<Failure, List<DiagnosticEntity>>> getHistory({int limit = 20, int offset = 0});
}
