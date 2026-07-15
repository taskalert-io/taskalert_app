import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskalert_app/core/features/activityLogs/controllers/activity_log_controller.dart';
import 'package:taskalert_app/core/features/activityLogs/data/repositories/activity_log_repository.dart';
import 'package:taskalert_app/core/features/activityLogs/data/repositories/activity_log_repository_impl.dart';
import 'package:taskalert_app/core/features/auth/controllers/signup_controller.dart';
import 'package:taskalert_app/core/features/dashboard/controllers/dashboard_controller.dart';
import 'package:taskalert_app/core/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:taskalert_app/core/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository.dart';
import 'package:taskalert_app/core/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taskalert_app/core/features/departments/controllers/department_controller.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository_impl.dart';
import 'package:taskalert_app/core/features/employees/controllers/employee_controller.dart';
import 'package:taskalert_app/core/features/employees/data/repositories/employee_repository.dart';
import 'package:taskalert_app/core/features/employees/data/repositories/employee_respository_impl.dart';
import 'package:taskalert_app/core/features/invitation/controllers/invitation_controller.dart';
import 'package:taskalert_app/core/features/invitation/data/repositories/invitation_repository.dart';
import 'package:taskalert_app/core/features/invitation/data/repositories/invitation_repository_impl.dart';
import 'package:taskalert_app/core/features/jobRoles/controllers/job_role_controller.dart';
import 'package:taskalert_app/core/features/jobRoles/data/repositories/job_role_repository.dart';
import 'package:taskalert_app/core/features/jobRoles/data/repositories/job_role_repository_impl.dart';
import 'package:taskalert_app/core/features/location/controllers/location_controller.dart';
import 'package:taskalert_app/core/features/location/data/repositories/location_repository.dart';
import 'package:taskalert_app/core/features/location/data/repositories/location_repository_impl.dart';
import 'package:taskalert_app/core/features/notifications/controllers/notification_controller.dart';
import 'package:taskalert_app/core/features/notifications/data/repositories/notification_repository.dart';
import 'package:taskalert_app/core/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:taskalert_app/core/features/organization/controllers/organization_controller.dart';
import 'package:taskalert_app/core/features/organization/data/repositories/organization_repository.dart';
import 'package:taskalert_app/core/features/organization/data/repositories/organization_repository_impl.dart';
import 'package:taskalert_app/core/features/sidebar/controllers/sidebar_controller.dart';
import 'package:taskalert_app/core/features/sidebar/data/repositories/sidebar_repository.dart';
import 'package:taskalert_app/core/features/sidebar/data/repositories/sidebar_repository_impl.dart';
import 'package:taskalert_app/core/features/subTasks/controllers/sub_task_controller.dart';
import 'package:taskalert_app/core/features/subTasks/data/repositories/sub_task_repository.dart';
import 'package:taskalert_app/core/features/subTasks/data/repositories/sub_task_repository_impl.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/core/features/taskInstance/data/repositories/task_instance_repository.dart';
import 'package:taskalert_app/core/features/taskInstance/data/repositories/task_instance_repository_impl.dart';
import 'package:taskalert_app/core/features/tasks/controllers/task_controller.dart';
import 'package:taskalert_app/core/features/tasks/data/repositories/task_repository.dart';
import 'package:taskalert_app/core/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:taskalert_app/core/features/workflow/controllers/workflow_controller.dart';
import 'package:taskalert_app/core/features/workflow/data/repositories/workflow_repository.dart';
import 'package:taskalert_app/core/features/workflow/data/repositories/workflow_repository_impl.dart';
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

  sl.registerLazySingleton<JobRoleRepository>(
    () => JobRoleRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => JobRoleController(sl<JobRoleRepository>()));

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(
    () => NotificationController(sl<NotificationRepository>()),
  );

  sl.registerLazySingleton<ActivityLogRepository>(
    () => ActivityLogRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => ActivityLogController(sl<ActivityLogRepository>()));

  // ✉️ Invitations Feature Layers
  sl.registerLazySingleton<InvitationRepository>(
    () => InvitationRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => InvitationController(sl<InvitationRepository>()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<HttpService>(), sl<FlutterSecureStorage>()),
  ); // Inject HttpService into AuthRepositoryImpl

  // ✅ SubTasks Feature Layers
  sl.registerLazySingleton<SubTaskRepository>(
    () => SubTaskRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => SubTaskController(sl<SubTaskRepository>()));

  // 🔀 Workflow Feature Layers
  sl.registerLazySingleton<WorkflowRepository>(
    () => WorkflowRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => WorkflowController(sl<WorkflowRepository>()));

  // 📊 Dashboard Feature Layers
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl<HttpService>()),
  );
  sl.registerFactory(() => DashboardController(sl<DashboardRepository>()));

  // 🍔 Sidebar Feature Layers
  sl.registerLazySingleton<SidebarRepository>(
    () => SidebarRepositoryImpl(sl<HttpService>()),
  );
  // Singleton (not registerFactory like other controllers) — its cached
  // config needs to survive across every screen's own CustomDrawer
  // instance, not just live for one screen.
  sl.registerLazySingleton(() => SidebarController(sl<SidebarRepository>()));
}
