# FOLDER_STRUCTURE.md

Derived from the actual `lib/` tree as of this writing. See [PROJECT_RULES.md](PROJECT_RULES.md)
for the target structure (`/features /core /shared`) — the current layout does **not** match
that target yet; gaps are called out inline below.

```
lib/
├── main.dart                     # App entrypoint: di.init(), ScreenUtilInit, MaterialApp,
│                                  # session bootstrap (reads 'auth_token' from secure storage)
│
├── components/                   # Reusable widgets — flat, not domain-grouped
│   ├── CustomAppBar.dart
│   ├── CustomBottomNavBar.dart
│   ├── CustomDrawer.dart
│   ├── SectionValidatable.dart    # abstract `bool validate()` interface
│   ├── AssetSystemSection.dart    # employee-profile form sections (implement SectionValidatable)
│   ├── CmpFinanceSection.dart
│   ├── DcmntComplianceSection.dart
│   ├── SkillPerformSection.dart
│   ├── TimeAttendSection.dart
│   └── EmpJobDetailsSection.dart
│
├── core/
│   ├── errors/
│   │   └── network_exceptions.dart   # NetworkException + NetworkErrorType, maps DioException
│   ├── network/
│   │   ├── http_service.dart          # abstract HttpService (get/post/put/patch/delete)
│   │   ├── dio_http_service.dart      # Dio-backed impl, baseUrl = task-alert-backend.onrender.com/api/v1
│   │   ├── auth_interceptor.dart      # attaches bearer token from secure storage
│   │   ├── api_result.dart            # ApiResult<T> = Success<T> | Failure<T>
│   │   └── base_api_response.dart     # { success, message, data, validationErrors?, pagination? }
│   │
│   └── features/                      # ✅ this part already matches the target Clean-Architecture shape
│       ├── auth/
│       │   ├── controllers/            # login_controller.dart, signup_controller.dart
│       │   └── data/
│       │       ├── models/             # user_model.dart, profile_model.dart
│       │       └── repositories/       # auth_repository.dart (abstract) + _impl.dart
│       ├── departments/{controllers,data/{models,repositories}}
│       ├── employees/{controllers,data/{models,repositories}}
│       ├── jobRoles/{controllers,data/{models,repositories}}
│       ├── location/{controllers,data/{models,repositories}}
│       ├── notifications/{controllers,data/{models,repositories}}
│       ├── organization/{controllers,data/{models,repositories}}
│       ├── tasks/{controllers,data/{models,repositories}}
│       ├── taskInstance/{controllers,data/{models,repositories}}
│       └── pagination/
│           └── models/pagination_model.dart   # shared, no controller/repository (it's a value type)
│
├── extras/                        # ⚠️ appears to hold superseded/duplicate screens
│   ├── MoreScreen.dart            #    (a MoreScreen.dart and NotificationScreen.dart also
│   └── NotificationScreen.dart    #     live directly under screens/ — see below)
│
├── screens/                       # ⚠️ ~30 page-level widgets, all flat — not grouped by feature
│   ├── HomeScreen.dart, SplashScreen.dart, WelcomePage.dart
│   ├── SignInScreen.dart, SignUpScreen.dart, OtpVerificationScreen.dart, LoginConfirmationScreen.dart
│   ├── DepartmentListScreen.dart, LocationListScreen.dart, OrganizationListScreen.dart
│   ├── EmployeesScreen.dart, ProfileSetting.dart, organization_setup_dialog.dart
│   ├── MyTaskScreen.dart, MyTaskDetails.dart, CreateOneTimeScreen.dart, CreateRepetitiveScreen.dart
│   ├── NotificationStart.dart, NotificationScreen.dart, Notifications.dart  # 3 notification screens
│   ├── DashboardPage.dart, MoreScreen.dart
│   └── activity_bottom_sheet.dart, panel_right_close_icon.dart
│
└── utils/
    └── injection_container.dart   # GetIt (`sl`) registration for every repository + controller
```

## Gaps vs. the target structure

- **No top-level `/shared`.** Cross-cutting UI (`components/`) and cross-cutting logic
  (`core/network`, `core/errors`) exist but aren't under a unified `/shared`.
- **`screens/` isn't split into `/features`.** Every feature's UI lives in one flat `screens/`
  folder instead of alongside that feature's `controllers/`/`data/` under `core/features/<name>/`.
- **Naming is inconsistent.** Screens use `PascalCase.dart` filenames (e.g. `NotificationStart.dart`);
  everything under `core/features/**` uses `snake_case.dart`. Dart's own convention (and the
  `file_names` lint already firing on several screens) wants `snake_case.dart` everywhere.
- **Duplicate screens.** `MoreScreen.dart` and `NotificationScreen.dart` exist both in `screens/`
  and in `extras/` — worth confirming which is live before deleting either.
- **`notifications` has three screens** (`NotificationStart.dart`, `NotificationScreen.dart`,
  `Notifications.dart`) — only `NotificationStart.dart` is currently wired to
  `core/features/notifications` (controller + repository); the other two should be checked for
  whether they're dead code.
