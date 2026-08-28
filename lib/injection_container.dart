import 'package:get_it/get_it.dart';
import 'package:tomate_detection_app/core/network/network_info.dart';
import 'package:tomate_detection_app/core/network/dio_client.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:tomate_detection_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:tomate_detection_app/features/authentication/domain/repositories/i_auth_repository.dart';
import 'package:tomate_detection_app/features/authentication/domain/usecases/login_usecase.dart';
import 'package:tomate_detection_app/features/authentication/domain/usecases/register_usecase.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_bloc.dart';
import 'package:tomate_detection_app/features/diagnosis/data/datasources/diagnostic_remote_datasource.dart';
import 'package:tomate_detection_app/features/diagnosis/data/repositories/diagnostic_repository_impl.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/repositories/i_diagnostic_repository.dart';
import 'package:tomate_detection_app/features/diagnosis/domain/usecases/send_diagnostic_usecase.dart';
import 'package:tomate_detection_app/features/diagnosis/bloc/diagnostic_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(remote: sl(), local: sl(), networkInfo: sl()));
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RegisterUseCase(sl()));
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registerUseCase: sl(), repo: sl()));

  // Diagnostic
  sl.registerLazySingleton<DiagnosticRemoteDataSource>(() => DiagnosticRemoteDataSource(sl()));
  sl.registerLazySingleton<IDiagnosticRepository>(() => DiagnosticRepositoryImpl(sl()));
  sl.registerFactory(() => SendDiagnosticUseCase(sl()));
  sl.registerFactory(() => DiagnosticBloc(sl()));
}
