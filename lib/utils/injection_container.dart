import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taskalert_app/core/network/dio_http_service.dart';
import 'package:taskalert_app/core/network/http_service.dart';

//import login controller for injection
import 'package:taskalert_app/core/features/auth/controllers/login_controller.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> init() async {
  // 1. Secure Storage Instance
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(
        // Setting resetOnError to true prevents unrecoverable crashes
        // if the Android Keystore becomes corrupted or wiped by the OS.
        resetOnError: true,
      ), // Ensures highest security on Android
    ),
  );

  // Future API services and Repositories will be registered here below
  sl.registerLazySingleton<HttpService>(
    () => DioHttpService(sl<FlutterSecureStorage>()),
  ); // Inject secure storage into DioHttpService

  sl.registerFactory(() => LoginController(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<HttpService>(), sl<FlutterSecureStorage>()),
  ); // Inject HttpService into AuthRepositoryImpl
}
