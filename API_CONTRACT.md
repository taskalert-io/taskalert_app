# API_CONTRACT.md

Derived from the actual `*_repository_impl.dart` files under `lib/core/features/**`. Every call
goes through `DioHttpService` (`lib/core/network/dio_http_service.dart`):

- **Base URL:** `https://task-alert-backend.onrender.com/api/v1`
- **Auth:** Bearer token attached by `AuthInterceptor` from secure storage key `auth_token` on
  every request; `POST /auth/access-token` exchanges `refreshToken` for a new one.
- **Timeouts:** 15s connect / 15s receive.
- **Content-Type:** `application/json`, except endpoints noted "multipart" below (file uploads use
  `dio.FormData`).

## Response envelope

Every response is expected to deserialize into `BaseApiResponse<T>`:

```jsonc
{
  "success": true,
  "message": "string",
  "data": { /* T, shape depends on endpoint */ },
  "validationErrors": { "field": "message" },   // optional, only on validation failures
  "pagination": { "total": 0, "page": 1, "limit": 10, "totalPages": 1, "hasNext": false, "hasPrev": false } // optional
}
```

`success: false` (or a thrown `DioException`) is surfaced to the UI as `ApiResult.failure(...)`;
`NetworkException.fromDioError` maps status codes to `NetworkErrorType` (`timeout`,
`unauthorized` for 401/403, `resourceNotFound` for 404, `serverError` for 5xx, `noInternet` for
connection errors, `unknown` otherwise) and prefers the backend's own `message` field when present.

---

## Auth (`core/features/auth`)

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/auth/signup` | `{ phoneNumber, email? }` | raw `data` |
| POST | `/auth/verify-signup-otp` | `{ firstName, lastName, phoneNumber, password, agreeTerms, otpCode, accountType, email?, gender?, dateOfBirth? }` | `UserModel` (+ writes tokens/profile fields to secure storage) |
| POST | `/auth/resend-signup-otp` | `{ phoneNumber }` | raw `data` |
| POST | `/auth/signin` | `{ phoneNumber }` | raw `data` |
| POST | `/auth/verify-signin-otp` | `{ phoneNumber, otpCode }` | `UserModel` (+ persists session to secure storage) |
| POST | `/auth/resend-signin-otp` | `{ phoneNumber }` | raw `data` |
| POST | `/auth/access-token` | `{ refreshToken }` | `{ accessToken }` → persisted as `auth_token` |
| GET | `/auth/profile` | — | `ProfileModel` (+ persists profile fields to secure storage) |
| PUT | `/auth/update-profile` | multipart: `firstName, lastName, phoneNumber?, email?, jobRole?, language?, languageCode?, image?` | `UserModel` |
| PUT | `/auth/update-password` | `{ oldPassword, newPassword }` | raw `data` |
| POST | `/auth/delete-account/request` | — | raw `data` |
| POST | `/auth/create-organization` | plain JSON or multipart if a logo file is attached: `{ name, email, phoneNumber, address?, image? }` | `OrganizationModel` |
| POST | `/auth/switch-organization` | `{ organizationId }` | `UserModel` (+ persists org-scoped token/id if present) |

## Organizations (`core/features/organization`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/organizations` | — | `OrganizationModel[]` |
| GET | `/organizations/:id` | — | `OrganizationModel` |
| GET | `/organizations/me` | — | `OrganizationModel` (session-scoped org) |
| PUT | `/organizations/:id` | multipart: `name, email, phoneNumber, address? (as JSON string), image?` | `OrganizationModel` |
| DELETE | `/organizations/:id` | — | raw |

(`create-organization` and `switch-organization` live under `/auth/*` — see above — not `/organizations/*`.)

## Departments (`core/features/departments`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/departments` | `?search=&limit=100` | `DepartmentModel[]` |
| GET | `/departments/:id` | — | `DepartmentModel` |
| GET | `/departments/search` | `?search=` | `DepartmentModel[]` (autocomplete) |
| POST | `/departments` | `{ name, location? }` | `DepartmentModel` |
| PUT | `/departments/:id` | `{ name, location? }` | `DepartmentModel` |
| DELETE | `/departments/:id` | — | raw |

## Locations (`core/features/location`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/locations` | `?department=&page=&limit=` | `LocationModel[]` |
| GET | `/locations/:id` | — | `LocationModel` |
| POST | `/locations` | `{ name, phoneNumber, address: {street,city,state,pinCode,country}, department? }` | `LocationModel` |
| PUT | `/locations/:id` | same body as POST | `LocationModel` |
| DELETE | `/locations/:id` | — | raw |

## Job roles (`core/features/jobRoles`)

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/job-roles` | — | `JobRoleModel[]` |
| POST | `/job-roles` | `{ title }` | `JobRoleModel` |

## Employees (`core/features/employees`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/employees` | `?organization=&jobRole=&search=&page=&department=` | `EmployeeModel[]` |
| GET | `/employees/:id` | — | `EmployeeModel` |
| GET | `/employees/search` | `?search=&jobRole=&page=` | `EmployeeModel[]` (recommendations) |
| POST | `/employees` | multipart: `firstName, lastName, email?, phoneNumber, gender?, jobRole?, department?, organization?, location?, dateOfBirth?, taskPermission?, taskType?, image?` | `EmployeeModel` |
| PUT | `/employees/:id` | multipart, same fields (all required except image) | `EmployeeModel` |
| DELETE | `/employees/:id` | — | raw |
| POST | `/employees/find-by-email-or-phone` | `{ email?, phoneNumber? }` | `EmployeeModel` |

## Tasks (`core/features/tasks`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/tasks` | `?taskType=&status=&department=&assigned=` | `TaskModel[]` |
| GET | `/tasks/:taskId` | — | `TaskModel` |
| POST | `/tasks` | multipart (`attachments` as files) | `TaskModel` |
| PUT | `/tasks/:taskId` | multipart (`attachments` as files) | `TaskModel` |
| PUT | `/tasks/update/:taskId` | `{ status }` | raw |

## Task instances (`core/features/taskInstance`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/tasks/instances` | `?date=&startDate=&endDate=&expand=&assigned=&status=&sortBy=&order=&overdue=` | `TaskInstancesResponse` (`{ instances: TaskInstanceModel[] }` + sibling root `counts`) |
| GET | `/tasks/instances/:instanceId` | — | `TaskInstanceModel` |
| PUT | `/tasks/:taskId/instances/:instanceId` | `{ status?, priority?, assignees?, scheduledTime?, scope? }` | `TaskInstanceModel` (full config update, e.g. edits an entire recurrence series) |
| PUT | `/tasks/instance/update/:instanceId` | `{ status?, priority?, assignees? }` | `TaskInstanceModel` (single-instance patch) |
| PUT | `/tasks/:taskId/instances/:instanceId/proof` | multipart `proofFiles[]` | `TaskInstanceModel` |
| DELETE | `/tasks/:taskId/instances/:instanceId/proof` | `{ publicId: string[] }` | `TaskInstanceModel` |

## Notifications (`core/features/notifications`)

| Method | Path | Body/Query | Returns |
|---|---|---|---|
| GET | `/notifications` | `?page=` | `NotificationModel[]` (+ `pagination`) |
| PUT | `/notifications/mark-all-read` | — | raw |
| PUT | `/notifications/:id/mark-read` | — | `NotificationModel` |

---

## Known rough edges (worth confirming against the live backend, not assumed)

- Several `_impl.dart` files swallow non-`NetworkException` errors silently (no generic `catch`),
  e.g. `EmployeeRepositoryImpl`, `TaskRepositoryImpl`, `OrganizationRepositoryImpl` — a shape
  mismatch there throws instead of surfacing as a normal `ApiResult.failure`, unlike the
  `department`/`location`/`jobRole`/`taskInstance`/`notification` repositories which do guard
  against it.
- `filterFromApi` (notifications) documents that it originally guessed `due_now`/`task_assigned`
  as the `type` values and later corrected them against real API data to `reporting_time` /
  `task_created` — a sign this contract is being reverse-engineered live rather than from a
  shared spec, so treat exact string enums (`type`, `severity`, `status`, `priority`,
  `completionStatus`, `accountType`, `signupSource`) as provisional until confirmed.
