# Flutter App ↔ Backend API Parity Report

Comparison of `taskalert_app` (Flutter) against `task-alert-backend-dev` (Express),
generated 2026-07-14. Base URLs align: Flutter defaults to `.../api/v1`
(`lib/core/network/dio_http_service.dart`), backend mounts the router at
`/api/v1` (`load/index.js`).

## Verdict

Most of the API surface lines up correctly on method, path, and body shape
across employees, departments, locations, organizations, job roles,
invitations, notifications, activity logs, and core task/task-instance CRUD.
Three concrete, currently-live bugs were found, one endpoint is genuinely
missing server-side, and a chunk of backend functionality isn't used by the
app yet (notably push notifications).

---

## 🔴 Live bugs to fix

### 1. Refresh token is never re-persisted after rotation
- Backend `refreshToken` (`controllers/auth.controller.js:690-716`) **rotates
  both tokens** on every call and requires the *new* `refreshToken` to match
  `user.refreshToken` on the next call — otherwise 401 "Invalid refresh
  token".
- Flutter's two refresh call sites — `lib/core/network/auth_interceptor.dart`
  (`_doRefresh`, used for automatic 401 recovery) and
  `lib/core/features/auth/data/repositories/auth_repository_impl.dart`
  (`refreshToken` method) — both read `data.accessToken` and write only
  `auth_token` to secure storage. Neither reads/writes `data.refreshToken`
  back into storage.
- **Effect**: the first silent refresh succeeds, but the stored
  `refresh_token` is now stale (server already rotated it out). The
  **second** time the access token expires, the refresh call fails
  401/403, `AuthInterceptor` treats that as unrecoverable, wipes the
  session, and forces the user back to Sign-In. This produces unexpected
  forced logouts roughly every other access-token cycle — directly
  undermines the auto-refresh/redirect-on-expiry feature.

### 2. Proof upload/delete responses can't be parsed correctly
- Backend `uploadInstanceProof` (`controllers/task.controller.js:3557-3561`)
  and `deleteInstanceProofFile` (`controllers/task.controller.js:3663-3667`)
  both respond with `data: instance.proofSubmission` — i.e. `data` **is**
  the bare `{submittedAt, files, note, proofTypes, aiValidationResult}`
  sub-document.
- Flutter (`lib/core/features/taskInstance/data/repositories/
  task_instance_repository_impl.dart`, upload ~line 246 and delete
  ~line 289) parses that same `data` through `TaskInstanceModel.fromJson`,
  which looks for a **nested** `json['proofSubmission']` key
  (`task_instance_model.dart` ~line 267).
- **Effect**: after every proof upload or delete, the parsed model comes
  back with `id: ''`, `status: ''`, and `proofSubmission: null` — the
  response is one nesting level too shallow. This is exactly why the app
  has needed manual full re-fetches (`_reloadInstanceAfterProofUpload`,
  `_loadInstance`) to patch over this all session instead of trusting the
  mutation response directly.

### 3. Task quick-status-update sends the wrong field name
- Flutter: `lib/core/features/tasks/data/repositories/
  task_repository_impl.dart` (~line 58-61) — `PUT /tasks/update/$taskId`
  with body `{'status': status}`.
- Backend: `controllers/task.controller.js:1336-1339`
  (`updateTaskStatusAssigneePriority`, mounted at
  `routes/task.routes.js:583-594`) destructures
  `const { completionStatus, assignees, priority } = req.body;` — never
  reads `status`.
- **Effect**: request returns 200/success but the task's status is never
  actually changed. Currently latent — `TaskController.handleUpdateTaskStatus`
  isn't called from any screen yet — but it will silently no-op the moment
  it's wired to a UI action.

---

## 🟡 Missing endpoint

- **`POST /auth/logout`** — Flutter calls it
  (`auth_repository_impl.dart:724`), no matching route exists anywhere in
  `routes/auth.routes.js` or elsewhere in the backend. Wrapped in
  try/catch so it fails silently and local session clearing still
  happens, but the server never invalidates the refresh token — a
  low-visibility security gap, not user-visible breakage.

---

## ✅ Confirmed correct (past pain points, now verified fine)

- **`notificationPreference`** — fully wired end-to-end: Joi validator
  (`Validators/task.validator.js:88-93`), Mongoose schema on both
  `models/task.model.js:198` and `models/taskInstance.model.js:115`,
  persisted in `controllers/task.controller.js:694-697`, propagated into
  generated instances (`helpers/generateTaskInstance.helper.js:251-320`).
- **`scheduledDate` alongside `scheduledTime`** — already fixed
  server-side. `updateInstance` (`controllers/task.controller.js:2226-2238`)
  has an explicit comment `scheduledTime, // ← scheduledDate removed`, and
  `updateInstanceValidator` has no `scheduledDate` field at all. The
  commented-out `scheduledDate` code in Flutter's
  `updateInstanceConfiguration` is correctly disabled, not a lingering bug.
- **Account-deletion OTP request + verify** — clean match
  (`auth.controller.js:1137`, `:1197-1199` vs
  `routes/auth.routes.js:102-103`).
- **`PUT /auth/update-profile`** (multipart) — clean match; controller
  reads exactly `firstName, lastName, phoneNumber, email, jobRole,
  language, languageCode` + `req.files.image`.
- **`POST /auth/access-token`** — request/response shape itself is
  correct (`{refreshToken}` in, `data.accessToken`/`data.refreshToken`
  out); the only problem is bug #1 above (client not saving the rotated
  refresh token).
- **Ref-field population** (assignee/organization/createdBy/completedBy/
  reviewedBy/department/jobRole/location) — consistently `.populate()`'d
  across task/task-instance list/detail/quick-update paths. One
  inconsistency found (Employees list returns display-name strings,
  detail returns populated objects) but the Flutter model
  (`EmployeeModel._extractRefDisplay`) already defensively handles both
  shapes.
- All other CRUD: Employees, Departments, Locations, Organizations
  (+ `/me`, create-org, switch-org), Job Roles (list/create), Invitations
  (create/list/revoke/validate), Notifications (list/mark-read/
  mark-all-read), Activity Logs (per-instance), Sidebar config, Task
  create/update/list/get (multipart + attachments), Task Instance
  list/get/full-update/quick-update.

---

## Unused backend functionality (not bugs — just not built into the app yet)

- **Push notifications** — `POST/DELETE /notifications/fcm-token` exist
  server-side; the Flutter app has no `firebase_messaging` dependency at
  all, so push is entirely unimplemented client-side.
- **SubTasks** — entire subtask template/instance CRUD section of
  `routes/task.routes.js` (~10 routes), zero client-side usage.
- `GET /notifications/unread-count`, `DELETE /notifications/:id` — unused.
- `GET /activity-logs/` (all), `GET /activity-logs/task/:id`,
  `DELETE /activity-logs/:id` — only the per-instance variant is used.
- `GET /organizations/search`, `POST /organizations/find-by-email-or-phone`
  — unused.
- `POST /departments/:departmentId/bulk-users` — unused.
- `GET/PUT/DELETE /job-roles/:id` — only list+create are used.
- Entire **Alacarte**, **Plan**, **Workflow**, **Contact Us** route files —
  no references anywhere in `lib/`.
- **Invite-token deep-link signup flow** —
  `InvitationController.handleValidateToken` exists but is never called
  from any screen; `GET /invitations/validate` is reachable but dead code
  client-side, and `inviteToken` is never forwarded into `POST
  /auth/signup` even though the validator accepts it
  (`Validators/auth.validators.js:43`).
