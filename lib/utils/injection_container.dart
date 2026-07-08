import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskalert_app/core/features/auth/controllers/signup_controller.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taskalert_app/core/features/departments/controllers/department_controller.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository_impl.dart';
import 'package:taskalert_app/core/features/employees/controllers/employee_controller.dart';
import 'package:taskalert_app/core/features/employees/data/repositories/employee_repository.dart';
import 'package:taskalert_app/core/features/employees/data/repositories/employee_respository_impl.dart';
import 'package:taskalert_app/core/features/location/controllers/location_controller.dart';
import 'package:taskalert_app/core/features/location/data/repositories/location_repository.dart';
import 'package:taskalert_app/core/features/location/data/repositories/location_repository_impl.dart';
import 'package:taskalert_app/core/features/organization/controllers/organization_controller.dart';
import 'package:taskalert_app/core/features/organization/data/repositories/organization_repository.dart';
import 'package:taskalert_app/core/features/organization/data/repositories/organization_repository_impl.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/core/features/taskInstance/data/repositories/task_instance_repository.dart';
import 'package:taskalert_app/core/features/taskInstance/data/repositories/task_instance_repository_impl.dart';
import 'package:taskalert_app/core/features/tasks/controllers/task_controller.dart';
import 'package:taskalert_app/core/features/tasks/data/repositories/task_repository.dart';
import 'package:taskalert_app/core/features/tasks/data/repositories/task_repository_impl.dart';
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

  sl.registerLazySingleton(() => LoginController(sl<AuthRepository>()));

  sl.registerLazySingleton(() => SignUpController(sl<AuthRepository>()));

  // 🏢 Departments Feature Layers
  sl.registerLazySingleton<DepartmentRepository>(
    () => DepartmentRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => DepartmentController(sl<DepartmentRepository>()));

  sl.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => EmployeeController(sl<EmployeeRepository>()));

  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => TaskController(sl<TaskRepository>()));

  sl.registerLazySingleton<TaskInstanceRepository>(
    () => TaskInstanceRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(
    () => TaskInstanceController(sl<TaskInstanceRepository>()),
  );

  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => LocationController(sl<LocationRepository>()));

  sl.registerLazySingleton<OrganizationRepository>(
    () => OrganizationRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(
    () => OrganizationController(sl<OrganizationRepository>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<HttpService>(), sl<FlutterSecureStorage>()),
  ); // Inject HttpService into AuthRepositoryImpl
}
