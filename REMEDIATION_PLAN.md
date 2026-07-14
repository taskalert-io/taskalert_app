# REMEDIATION_PLAN.md

Consolidates every gap found across [PROJECT_RULES.md](PROJECT_RULES.md),
[FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md), [THEME_GUIDE.md](THEME_GUIDE.md),
[STATE_MANAGEMENT.md](STATE_MANAGEMENT.md), and the security/architecture audit, plus a phased
plan to close them. `PROJECT_RULES.md` is treated here as the **target state**; everything below
measures the gap between that target and what's actually in the repo today.

---

## Part 1 — Consolidated report

### 🔴 Fix now (correctness/security bugs, not just style gaps)

| # | Issue | Where | Why it matters |
|---|---|---|---|
| 1 | `_saveTask()` is a stub — builds the real payload, `debugPrint`s it, then just `await Future.delayed(...)` and shows "Saved". No API call happens. | `screens/MyTaskDetails.dart:372-390` | **Silent data loss.** Anyone editing a task from this screen believes it saved; nothing persists. |
| 2 | Password field is decorative. `_accountPasswordController.text = "••••••••"` is set once and never read/submitted anywhere in the file — no call to `/auth/update-password`. | `screens/ProfileSetting.dart:141`, `:1356-1376` | False sense of security — users think they changed their password from Settings and didn't. |
| 3 | Sensitive edit payload logged via `debugPrint`, with the "remove in production" TODO left unaddressed. `debugPrint` is **not** stripped from release builds. | `screens/MyTaskDetails.dart:379` | Task content lands in device logs (`adb logcat`) in production. |
| 4 | Tenant scoping (`organizationId`) is read from client secure storage and sent as a plain param on every request. | `EmployeeRepositoryImpl.getEmployees`, `TaskRepositoryImpl.getAllTasks`, etc. — see [API_CONTRACT.md](API_CONTRACT.md) | Normal for a client, but only safe **if the backend independently verifies org membership from the JWT** rather than trusting the client-supplied id. Unverified from this side — needs a backend-side confirmation. |

### 🟠 Fix soon (hardening, not currently exploited but should close before scaling)

| # | Issue | Where |
|---|---|---|
| 5 | No certificate pinning — relies solely on system CA trust | `core/network/dio_http_service.dart` |
| 6 | No root/jailbreak or app-integrity check | app-wide |
| 7 | OTP resend cooldown is client-side only (60s `Timer`) — confirm server-side rate limiting exists too | `screens/OtpVerificationScreen.dart` |
| 8 | No explicit `network_security_config.xml` pinning the API host (currently relying on the Android default, which is fine but not defense-in-depth) | `android/app/src/main` |
| 9 | Duplicate/dead screens increase audit surface: `MoreScreen.dart` and `NotificationScreen.dart` exist in both `screens/` and `extras/`; 3 total notification screens (`NotificationStart.dart`, `NotificationScreen.dart`, `Notifications.dart`) with only 1 wired to a real controller | `lib/screens/`, `lib/extras/` |
| 10 | Commented-out `// print(...)` debris across several files — log hygiene isn't enforced, which is how #3 happened | `CreateRepetitiveScreen.dart`, `task_controller.dart`, `login_controller.dart` |
| 11 | `GoogleFonts.inter(...)` fetches fonts from Google's CDN at runtime instead of bundling — an outbound call to a third party outside your own API, relevant for compliance-sensitive B2B customers | app-wide |

### 🟡 SaaS-readiness gaps (process/infrastructure, not a single file)

| # | Gap | Evidence |
|---|---|---|
| 12 | Zero real test coverage | `test/widget_test.dart` is still the unmodified Flutter starter template — references a counter widget that doesn't exist in this app; `flutter test` fails immediately |
| 13 | No CI | `.github/` contains only `CODEOWNERS` |
| 14 | No environment separation | API base URL is a literal string in `dio_http_service.dart:13`; no flavors, no `--dart-define` |
| 15 | No crash/error observability | No Sentry/Crashlytics/equivalent in `pubspec.yaml` |
| 16 | No pagination UI despite backend support | `DepartmentRepositoryImpl` hardcodes `limit: 100`; `PaginationModel`/`?page=` exist but aren't used in any list screen |
| 17 | Controllers are `registerFactory`'d fresh per screen, no cross-screen cache | every screen re-fetches from scratch on each visit — see [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md) |

### 🔵 Architecture mismatches vs. `PROJECT_RULES.md` (structural, not urgent, but the biggest lift)

| Rule in PROJECT_RULES.md | Reality today |
|---|---|
| "Use Riverpod only" | All 10 controllers extend `ChangeNotifier`, wired via `get_it` (see [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md)) |
| "GoRouter" | Plain `Navigator.push`/`Navigator.pop` everywhere; session bootstrap is a manual `FutureBuilder` in `main.dart` |
| "Firebase Messaging" | Not present at all — notifications are pull-only (`GET /notifications`, polled from `CustomBottomNavBar`), no push |
| "Use AppTheme" / "No hardcoded colors" | No `AppTheme` exists; every screen declares its own private `_C` color class; two brand hexes (`#0A0258`, `#6C5CE7`) recur ~242 times without being centralized (see [THEME_GUIDE.md](THEME_GUIDE.md)) |
| `/lib/features /core /shared` | `core/features/**` already matches; `screens/` is flat and un-grouped, there's no `/shared`, and naming is inconsistent (`PascalCase.dart` screens vs `snake_case.dart` everywhere else) — see [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) |

---

## Part 2 — Phased plan

Ordered by risk-reduction-per-effort, not calendar time — treat the phase numbers as sequence,
not sprints. Each phase is safe to ship independently; none blocks the others except where noted.

### Phase 0 — Stop the bleeding (do first, small effort, no architecture change)
- [ ] Wire `MyTaskDetails._saveTask()` to the real `TaskController`/`TaskInstanceController` update call; remove the simulated delay (issue #1)
- [ ] Delete the `debugPrint('API payload...')` line, or gate all such logs behind `if (kDebugMode)` project-wide (issue #3, #10)
- [ ] Either wire the Password field to `/auth/update-password` with proper old/new-password confirmation, or remove it from the UI until it's implemented (issue #2)
- [ ] Confirm with the backend team that organization/tenant scoping is enforced server-side from the JWT, independent of any client-supplied `organizationId` (issue #4)
- [ ] Delete or consolidate the duplicate screens once you confirm which copy is live: `extras/MoreScreen.dart` vs `screens/MoreScreen.dart`, `extras/NotificationScreen.dart` vs `screens/NotificationScreen.dart`, and pick one of the three notification screens to keep (issue #9)

**Dependency:** none. **Risk of doing this:** near zero — these are bug fixes and deletions of dead code.

### Phase 1 — Testing & CI foundation
- [ ] Replace `test/widget_test.dart` with a real smoke test (app boots to `SplashScreen`/`SignInScreen`) plus unit tests for at least one controller (e.g. `NotificationController`, since it has the clearest state machine) and one repository (mock `HttpService`)
- [ ] Add a GitHub Actions workflow: `flutter analyze` + `flutter test` on every PR
- [ ] Add crash/error reporting (Firebase Crashlytics or Sentry) — cheap to wire, high value once anything below ships to real users

**Dependency:** none, but doing this before Phases 3-5 means every later refactor is caught by CI instead of manual QA.

### Phase 2 — Environment & network hardening
- [ ] Move the hardcoded base URL into flavor/`--dart-define` config (dev/staging/prod), so QA and prod stop sharing one backend
- [ ] Add certificate pinning to the Dio client (issue #5)
- [ ] Add `network_security_config.xml` pinning the API host explicitly (issue #8)
- [ ] Confirm/request server-side rate limiting on OTP endpoints (issue #7)
- [ ] Evaluate root/jailbreak detection given the tenant-trust concern (issue #6)

**Dependency:** none. Can run in parallel with Phase 1.

### Phase 3 — Theme consolidation (closes the "AppTheme" / "no hardcoded colors" rules)
- [ ] Create `lib/core/theme/app_colors.dart` + `app_theme.dart`, seeded from the two de facto brand
      hexes and the existing `kSeverityConfig` semantic map (already the one good example in the
      codebase — see [THEME_GUIDE.md](THEME_GUIDE.md))
- [ ] Migrate each screen's private `_C` class to reference `AppColors` instead of re-declaring
      hex values — mechanical, low-risk, one screen at a time (field names already line up)
- [ ] Only after migration is complete, start enforcing "no new hardcoded colors" in code review

**Dependency:** benefits from Phase 1's CI being in place first (catches regressions across ~28 files touched).

### Phase 4 — Folder restructuring (closes the `/features /core /shared` rule)
- [ ] Introduce a top-level `/shared` for `components/` + cross-cutting `core/network`, `core/errors`
- [ ] Move each screen under its matching `core/features/<name>/presentation/` (or a new top-level `/features/<name>/`) alongside that feature's existing `controllers/`/`data/`
- [ ] Normalize screen filenames to `snake_case.dart` to match the rest of the codebase and silence the existing `file_names` lint hits
- [ ] Do this feature-by-feature (start with `notifications` — smallest, already has 1 dead-code screen removed from Phase 0), not as one big-bang move

**Dependency:** do this *after* Phase 0 removes the dead notification screens — moving files that are about to be deleted is wasted motion.

### Phase 5 — State management & routing migration (largest, most disruptive — sequence last, decide deliberately)
This is the one item where "match PROJECT_RULES.md" and "lowest risk" are in tension. Two options:

**Option A — Migrate to Riverpod + GoRouter** (matches the written rules)
- [ ] Pick the lowest-traffic feature first (`jobRoles` — 1 endpoint, 1 controller) as a pilot
- [ ] Repository layer needs no changes — it's already framework-agnostic (see [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md))
- [ ] Convert each `XController extends ChangeNotifier` to an `XController extends AsyncNotifier<...>` one feature at a time; `isLoading`/`errorMessage`/data triple maps directly onto `AsyncValue`
- [ ] Introduce `GoRouter` alongside `Navigator` and migrate route-by-route, not all at once
- [ ] Estimate: largest single line item in this plan — budget it as its own multi-sprint initiative, not a task inside a sprint

**Option B — Formalize the current ChangeNotifier + GetIt pattern and update PROJECT_RULES.md instead**
- [ ] Standardize on `ListenableBuilder` (drop the manual `addListener`/`setState` variant used in `CustomBottomNavBar`/`CustomDrawer`) as the one house style
- [ ] Document the pattern in `STATE_MANAGEMENT.md` as the *actual* rule and adjust `PROJECT_RULES.md` to stop claiming Riverpod
- [ ] Far cheaper — no migration risk, but doesn't close the gap, it redefines it away

**Recommendation:** decide this one explicitly rather than defaulting into it — it changes the
answer to "is PROJECT_RULES.md aspirational or descriptive" for good. Everything in Phases 0-4 is
useful either way.

### Phase 6 — Scale-readiness (once the above is stable)
- [ ] Add pagination/infinite-scroll to the department/employee/location list screens (issue #16)
- [ ] Add a light caching layer (or promote hot controllers to `registerLazySingleton`) so navigating between screens doesn't re-fetch identical data every time (issue #17)
- [ ] Add Firebase Messaging for real push notifications, replacing the current poll-on-tab-visit pattern in `CustomBottomNavBar`

---

## Suggested sequencing

```
Phase 0 (bug fixes)  ──┐
Phase 1 (tests/CI)     ├──> run in parallel, both fast, both de-risk everything after
Phase 2 (env/network) ──┘
        │
        ▼
Phase 3 (theme)  ──> Phase 4 (folders)  ──> Phase 5 (state/routing — pick Option A or B)
        │
        ▼
Phase 6 (scale) — anytime after Phase 1, doesn't block on 3-5
```

Phase 0 and Phase 1 are the only two that should start immediately; everything else is safe to
schedule once those land.
