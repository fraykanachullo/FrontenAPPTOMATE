import 'package:equatable/equatable.dart';

abstract class DiagnosticEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiagnosticRequested extends DiagnosticEvent {
  final String imagePath;
  final Map<String, dynamic> metadata;
  DiagnosticRequested(this.imagePath, this.metadata);
  @override
  List<Object?> get props => [imagePath];
}
