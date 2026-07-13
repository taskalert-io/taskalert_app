# PROJECT_RULES.md — taskalert_app

Foundational reference: architecture, folder structure, and coding rules for
this Flutter app. For reusable UI/implementation *patterns* (dialogs,
pickers, form banners, etc.), see `CLAUDE.md` instead — that file is
auto-loaded every session; this one is the "how is this project organized
and how do we write code here" reference.

## Architecture

Layered, feature-first:

```
Screen (UI)  →  Controller (ChangeNotifier)  →  Repository (abstract)  →  RepositoryImpl (Dio)  →  HttpService
```

- **Screens** (`lib/screens/`) are `StatefulWidget`s. They hold their own
  controller instance(s) as State fields (`late final XController
  xController = sl<XController>();`) and read controller state directly in
  `build()` — there is **no** Provider/Riverpod/Bloc; state flows via plain
  `ChangeNotifier` + manual `setState()` after `await`ing a controller call,
  or occasionally `ListenableBuilder`/`AnimatedBuilder` when a widget needs
  to react to a controller's `notifyListeners()` without an explicit
  `setState` at the call site (e.g. `CustomAppBar`, `CustomBottomNavBar`).
- **Controllers** (`lib/core/features/<feature>/controllers/`) extend
  `ChangeNotifier`. Every public method is named `handleX` (e.g.
  `handleGetEmployees`, `handleCreateOrganization`) and follows the same
  shape: set `_isLoading`/clear messages → `notifyListeners()` → await the
  repository call → unpack `ApiResult` (`Success`/`Failure`) → update state
  → `notifyListeners()` → return a `bool`/`void` as appropriate. Standard
  getters: `isLoading`, `errorMessage`, `successMessage`.
- **Repositories** are an abstract interface
  (`lib/core/features/<feature>/data/repositories/<feature>_repository.dart`)
  plus a Dio-backed impl (`..._repository_impl.dart`). Every method returns
  `Future<ApiResult<BaseApiResponse<T>>>`, wraps the call in
  `try { ... } on NetworkException catch (e) { return ApiResult.failure(e); }`,
  and builds the request via `HttpService` (never `Dio` directly — that's
  encapsulated so the HTTP client can be swapped without touching
  repositories).
- **Models** (`lib/core/features/<feature>/data/models/`) are hand-written
  (no code generation). Every field-parsing line in `fromJson` uses `??`
  fallbacks — models should never throw on an unexpected/partial JSON shape;
  a parsing bug should surface as an empty/default field, not a crash.
  Ref fields that might come back as either a populated object or a plain ID
  string are parsed defensively for both (see `CLAUDE.md`).
- **DI** (`lib/utils/injection_container.dart`, GetIt as `sl`):
  `registerLazySingleton` for repositories and `HttpService` (one instance
  app-wide), `registerFactory` for controllers (a fresh instance every
  `sl<XController>()` call — screens are expected to hold onto their own
  instance rather than re-resolving repeatedly).
- **Networking**: `lib/core/network/http_service.dart` (abstract interface:
  `get`/`post`/`put`/`patch`/`delete`, all accepting an optional `body:`) →
  `dio_http_service.dart` (the only file that touches `Dio` directly) →
  `auth_interceptor.dart` (injects the bearer token on every request, and
  silently refreshes + retries once on a 401 using a separate
  interceptor-free `Dio` instance to avoid recursive refresh loops).
  `api_result.dart` defines the `Success`/`Failure` sealed result type;
  `base_api_response.dart` defines the `{success, message, data, pagination,
  validationErrors}` envelope every endpoint returns.
- **Errors**: `lib/core/errors/network_exceptions.dart` — Dio exceptions are
  translated into a `NetworkException` with a `userMessage` safe to show
  directly in a SnackBar/banner.

## Folder structure

```
lib/
  main.dart                     Entry point — calls sl init, runs the app
  components/                   Shared widgets reused across screens
                                 (CustomAppBar, CustomDrawer, CustomBottomNavBar,
                                 plus a handful of profile-form section widgets)
  screens/                      One file per screen (PascalCase filenames —
                                 an established, if non-idiomatic-Dart, convention
                                 here; don't "fix" it mid-task)
  core/
    errors/                     NetworkException + error mapping
    network/                    HttpService interface + DioHttpService impl +
                                 AuthInterceptor + ApiResult + BaseApiResponse
    features/<feature>/         One folder per domain feature:
      controllers/                 <feature>_controller.dart (ChangeNotifier)
      data/
        models/                    <feature>_model.dart (hand-written fromJson/toJson)
        repositories/               <feature>_repository.dart (abstract)
                                    <feature>_repository_impl.dart (Dio-backed)
  utils/
    injection_container.dart    GetIt registrations (the only place `sl<T>()`
                                 bindings are declared)
```

Current feature folders under `lib/core/features/`: `auth`, `departments`,
`employees`, `jobRoles`, `location`, `notifications`, `organization`,
`pagination`, `taskInstance`, `tasks`.

`lib/extras/` holds legacy/scratch files that aren't wired into the app —
don't treat anything there as a pattern to follow, and don't assume it's
dead-safe-to-delete without checking imports first.

## Coding rules

- **Verify before calling anything done**: `dart analyze <changed file(s)>`
  (zero new errors — pre-existing warnings/info in unrelated code are fine
  and not yours to fix unless asked), then project-wide
  `dart analyze lib/ 2>&1 | grep -i "error -"` to confirm nothing else broke.
- **Minimal, targeted changes.** Don't refactor, rename, or "clean up"
  surrounding code that wasn't part of the request. Exception: code that
  becomes fully dead *as a direct result* of your change (e.g. a helper only
  used by the thing you just removed) should be deleted, not left behind —
  this codebase already carries real scar tissue from prior half-removed
  features (see `lib/screens/MyTaskDetails.dart`'s dead `_saveTask`/
  `_applyModel`/mock `TaskDetail` path — don't add another one of these).
- **No new state-management library, no new HTTP client.** Everything routes
  through `HttpService`/the existing `ChangeNotifier` pattern. If a screen
  needs "reactive" updates from a controller it doesn't itself own (rare),
  use `ListenableBuilder`/`AnimatedBuilder`, not a new dependency.
- **Sizing/styling**: `flutter_screenutil` units everywhere (`.w`, `.h`,
  `.r`, `.sp`) — never raw pixel `double`s for spacing/sizing in UI code.
  Text styling goes through `GoogleFonts.inter(...)`. Screens typically
  define a small set of `static const Color` constants near the top of the
  State class (e.g. `_primaryColor`, `_labelColor`, `_dividerColor`) rather
  than scattering hex literals — reuse a screen's existing constants before
  inventing new ones with the same value.
- **Bottom sheets over full-screen dialogs** for create/edit forms and
  filters — `showModalBottomSheet` with `isScrollControlled: true`,
  `backgroundColor: Colors.transparent`, rounded top corners
  (`BorderRadius.vertical(top: Radius.circular(20.r))`), wrapped in
  `StatefulBuilder` for local sheet state. See `CLAUDE.md` for the specific
  reusable-dialog and multi-select-picker shapes built on top of this.
  **Never** show a `SnackBar` for a validation/API error from *inside* an
  open bottom sheet — it renders behind the sheet and is easy to miss; use
  an inline error banner instead (also in `CLAUDE.md`).
- **Optional vs. required backend fields**: only include a field in a
  request map when it's actually meant to change — many ObjectId ref fields
  reject an empty string outright. Build request bodies with `if (x != null
  && x.isNotEmpty) map['x'] = x;` rather than always including every field.
- **Don't invent backend endpoints or field values.** If an endpoint path,
  request shape, or enum-like string value (e.g. a notification `type`) isn't
  confirmed by existing code or a response sample you've been given, ask for
  a real sample rather than guessing — guessed values fail silently (wrong
  data just doesn't show up) rather than erroring loudly, which makes them
  expensive bugs to catch later.
- **Comments**: none by default. Only add one where the *why* isn't obvious
  from the code — a backend quirk, a prior incident, a non-obvious ordering
  requirement. Don't restate what the code already says.
- **Destructive/irreversible actions** (deleting a resource, discarding
  uncommitted changes, force-push) always get a confirmation dialog in the
  UI (see the `Delete X` `AlertDialog` pattern used across every list
  screen) and are never wired up without one.
