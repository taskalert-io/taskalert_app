# STATE_MANAGEMENT.md

**This app does not use Riverpod.** [PROJECT_RULES.md](PROJECT_RULES.md) states "Use Riverpod
only," but every one of the 10 controllers in the codebase extends `ChangeNotifier`, wired
through `get_it`, not `flutter_riverpod`/`hooks_riverpod` (neither package is in `pubspec.yaml`).
This doc describes what's actually implemented today; treat it as the migration starting point,
not the target.

## The actual pattern: GetIt + ChangeNotifier + Repository

```
Screen  ──sl<XController>()──>  XController (ChangeNotifier)
                                     │  calls
                                     ▼
                                XRepository (abstract)
                                     │  implemented by
                                     ▼
                                XRepositoryImpl ──> HttpService (Dio) ──> REST API
```

### 1. Service locator — `lib/utils/injection_container.dart`

`GetIt.instance` (aliased `sl`), populated once in `main()` via `di.init()`:

- `registerLazySingleton` for singletons shared app-wide: `FlutterSecureStorage`, `HttpService`
  (→ `DioHttpService`), and every `XRepository`.
- `registerFactory` for every `XController` — **a fresh controller instance per
  `sl<XController>()` call**, so each screen gets its own loading/error/data state rather than
  sharing one global instance. (Contrast with Riverpod, where a `Provider`'s scope/lifetime is
  explicit in the provider declaration itself — here it's implicit in which GetIt registration
  method was used.)

### 2. Repositories — `core/features/<name>/data/repositories/`

Abstract interface (e.g. `DepartmentRepository`) + concrete impl (e.g.
`DepartmentRepositoryImpl`) that calls `HttpService` and returns
`Future<ApiResult<BaseApiResponse<T>>>`. `ApiResult<T>` is a manual sealed-ish union
(`Success<T>` / `Failure<T>`, see `core/network/api_result.dart`) — every repository method
wraps its Dio call in try/catch and converts `NetworkException` into `ApiResult.failure(...)`.

### 3. Controllers — `core/features/<name>/controllers/`

Every controller (`DepartmentController`, `EmployeeController`, `TaskController`,
`TaskInstanceController`, `LocationController`, `JobRoleController`, `OrganizationController`,
`NotificationController`, `LoginController`, `SignupController`) follows the same shape:

```dart
class XController extends ChangeNotifier {
  final XRepository _repository;
  XController(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<XModel> _items = [];
  // + getters for all of the above

  Future<void> handleGetX() async {
    _isLoading = true; notifyListeners();
    final result = await _repository.getX();
    _isLoading = false;
    if (result is Success) { _items = result.data.data ?? []; }
    else if (result is Failure) { _errorMessage = result.exception.userMessage; }
    notifyListeners();
  }
  // handleCreateX / handleUpdateX / handleDeleteX follow the same isLoading→await→notifyListeners shape,
  // and optimistically patch the in-memory list (insert/update/removeWhere) rather than re-fetching.
}
```

`NotificationController` additionally derives `unreadCount` as a getter over `_notifications`
rather than storing it separately — worth following as the pattern for any other derived value.

### 4. Screens consume controllers imperatively, not via a widget-tree provider

Two ways this shows up, both present in the codebase (no single house style yet):

- **`ListenableBuilder`** (e.g. `EmployeesScreen`): `ListenableBuilder(listenable:
  employeeController, builder: (context, _) { ... })` — rebuilds only the subtree that reads
  controller state.
- **Manual `addListener` + `setState`** (e.g. `CustomBottomNavBar`, `CustomDrawer`):
  `controller.addListener(_onChanged)` in `initState`, `removeListener` in `dispose`, and a bare
  `setState(() {})` in the callback.

There is **no `ChangeNotifierProvider`/`InheritedWidget` at the app root** — every screen/widget
that needs a controller calls `sl<XController>()` directly in `initState`, which is what makes
this *not* Provider in the traditional sense either (no widget-tree scoping, no `context.watch`).

## Where this diverges from the Riverpod target

| Concern | Current (ChangeNotifier + GetIt) | Riverpod target |
|---|---|---|
| Declaring state | `class XController extends ChangeNotifier` | `class XController extends Notifier<XState>` (or `AsyncNotifier`) |
| Registering/locating | `sl.registerFactory(() => XController(...))` in `injection_container.dart` | `final xControllerProvider = NotifierProvider(...)` |
| Obtaining in a widget | `sl<XController>()` in `initState`, stored as a field | `ref.watch(xControllerProvider)` in `build` |
| Rebuilding on change | `ListenableBuilder`/manual `addListener` | automatic via `ref.watch` |
| Loading/error state | ad hoc `bool _isLoading` + `String? _errorMessage` fields per controller | `AsyncValue<T>` (`.when(data:, loading:, error:)`) |
| Testability | requires GetIt reset/re-registration between tests | providers can be overridden per `ProviderScope` |

## Migration notes if/when this moves to Riverpod

- The repository layer needs no changes — `XRepository`/`XRepositoryImpl` are already
  UI-framework-agnostic and can be handed to a Riverpod provider exactly as they're handed to a
  controller today.
- The `isLoading`/`errorMessage`/`data` triple that every controller hand-rolls is precisely what
  `AsyncValue` models — this is likely the highest-value single change.
- `registerFactory` (per-screen instance) vs `registerLazySingleton` (app-wide instance) choices
  made in `injection_container.dart` today map directly to `autoDispose` vs plain provider scoping
  decisions in Riverpod — worth auditing which controllers actually need per-screen isolation
  before picking a provider type for each.
