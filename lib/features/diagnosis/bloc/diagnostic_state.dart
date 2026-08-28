import 'package:equatable/equatable.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/entities/diagnostic_entity.dart';

abstract class DiagnosticState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiagnosticInitial extends DiagnosticState {}
class DiagnosticLoading extends DiagnosticState {}
class DiagnosticSuccess extends DiagnosticState {
  final DiagnosticEntity diagnostic;
  DiagnosticSuccess(this.diagnostic);
  @override
  List<Object?> get props => [diagnostic];
}
class DiagnosticFailure extends DiagnosticState {
  final String message;
  DiagnosticFailure(this.message);
  @override
  List<Object?> get props => [message];
}
