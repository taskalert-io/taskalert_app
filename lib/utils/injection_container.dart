import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
}
