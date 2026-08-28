import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_event.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_state.dart';
import 'package:tomate_detection_app/features/authentication/domain/usecases/login_usecase.dart';
import 'package:tomate_detection_app/features/authentication/domain/usecases/register_usecase.dart';
import 'package:tomate_detection_app/features/authentication/domain/repositories/i_auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final IAuthRepository repo;
  AuthBloc({required this.loginUseCase, required this.registerUseCase, required this.repo}) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      final res = await loginUseCase(LoginParams(event.email, event.password));
      res.fold((f) => emit(AuthError(f.message)), (u) => emit(AuthAuthenticated(u)));
    });
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      final res = await registerUseCase(RegisterParams(event.name, event.email, event.password, event.role));
      res.fold((f) => emit(AuthError(f.message)), (u) async {
        // auto-login tras registro
        final login = await loginUseCase(LoginParams(event.email, event.password));
        login.fold((f) => emit(AuthError("Registrado, pero login falló: ${f.message}")), (user) => emit(AuthAuthenticated(user)));
      });
    });
    on<LogoutRequested>((event, emit) async {
      await repo.logout();
      emit(AuthUnauthenticated());
    });
    on<CheckAuth>((event, emit) async {
      final logged = await repo.isLoggedIn();
      if (!logged) { emit(AuthUnauthenticated()); return; }
      final res = await repo.getMe();
      res.fold((_) => emit(AuthUnauthenticated()), (u) => emit(AuthAuthenticated(u)));
    });
  }
}
