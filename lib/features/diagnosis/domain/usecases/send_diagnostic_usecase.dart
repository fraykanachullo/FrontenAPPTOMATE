import 'package:dartz/dartz.dart';
import 'package:tomate_detection_app/core/error/failures.dart';
import 'package:tomate_detection_app/core/usecases/usecase.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/entities/diagnostic_entity.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/repositories/i_diagnostic_repository.dart';

class SendDiagnosticParams {
  final String imagePath;
  final Map<String, dynamic> metadata;
  SendDiagnosticParams(this.imagePath, this.metadata);
}

class SendDiagnosticUseCase implements UseCase<DiagnosticEntity, SendDiagnosticParams> {
  final IDiagnosticRepository repo;
  SendDiagnosticUseCase(this.repo);
  @override
  Future<Either<Failure, DiagnosticEntity>> call(SendDiagnosticParams p) => repo.sendDiagnostic(p.imagePath, p.metadata);
}
