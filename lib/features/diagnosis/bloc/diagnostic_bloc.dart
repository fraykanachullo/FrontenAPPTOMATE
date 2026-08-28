import 'package:flutter_bloc/flutter_bloc.dart';
import 'diagnostic_event.dart';
import 'diagnostic_state.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/usecases/send_diagnostic_usecase.dart';

class DiagnosticBloc extends Bloc<DiagnosticEvent, DiagnosticState> {
  final SendDiagnosticUseCase sendUseCase;
  DiagnosticBloc(this.sendUseCase) : super(DiagnosticInitial()) {
    on<DiagnosticRequested>((event, emit) async {
      emit(DiagnosticLoading());
      final res = await sendUseCase(SendDiagnosticParams(event.imagePath, event.metadata));
      res.fold((f) => emit(DiagnosticFailure(f.message)), (d) => emit(DiagnosticSuccess(d)));
    });
  }
}
