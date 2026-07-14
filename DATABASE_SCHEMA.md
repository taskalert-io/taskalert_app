# DATABASE_SCHEMA.md

**Source of truth disclaimer:** this app has no direct visibility into the MongoDB backend
(`https://task-alert-backend.onrender.com/api/v1`). Everything below is *inferred* from the
Dart `fromJson`/`toJson` model definitions under `lib/core/features/**/data/models/` — i.e. it
documents the shape the client sends/expects, not a verified export of the actual collections.
Treat field types as best-effort; anything the client only ever reads as `dynamic` or a bare
`String` ref is marked as such.

Every document uses Mongo's implicit `_id` (ObjectId, serialized as a string) and most carry
`createdAt`/`updatedAt`. Reference fields (`organization`, `department`, `location`, `jobRole`,
etc.) are **polymorphic on the wire**: list/GET endpoints often return them populated
(`{"_id": ..., "name": ...}`), while POST/PUT bodies send a plain id string — every model's
parser (`_extractRefId` / `_extractRefDisplay`) tolerates both shapes.

---

## `users` (inferred — auth/profile endpoints)
From `UserModel` (`auth/data/models/user_model.dart`) and `ProfileModel` (`profile_model.dart`):

| Field | Type | Notes |
|---|---|---|
| `_id` / `userId` | ObjectId | `verifySignUpOtp`/`verifySignInOtp` responses nest this under a `user` object |
| `email` | string | |
| `firstName`, `lastName` | string | |
| `phoneNumber` | string | primary passwordless-login identifier |
| `gender` | string | |
| `dateOfBirth` | ISO date | |
| `image` | `{ originalUrl, thumbnailUrl, publicId }` | Cloudinary-style asset |
| `video` | `{ videoUrl, publicId }` | |
| `accountType` | string | |
| `taskPermission` | bool | |
| `taskType` | string | |
| `requiresOrganization` | bool | drives onboarding redirect to org-creation |
| `role` | string | |
| `organization` | ref → `organizations` | populated as `{_id, name}` on auth responses |
| `activeOrganization` | ref → `organizations` | the org the current session is scoped to |
| `jobRole` | ref → `jobroles` | seen on `ProfileModel` |
| `department` | ref → `departments` | seen on `ProfileModel` |
| `languageSettings` | `{ language, languageCode }` | |
| (root, not nested) `accessToken` / `token` | JWT | never persisted server-side per-doc, returned at auth time |
| (root) `refreshToken` | JWT | |

## `organizations`
From `OrganizationModel`:

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `name`, `email`, `phoneNumber` | string | |
| `address` | `{ street, city, state, country, pinCode }` | |
| `image` | `{ originalUrl, thumbnailUrl, publicId }` | logo |
| `createdAt` | date | |

## `departments`
From `DepartmentModel`:

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `name` | string | |
| `organization` | ref → `organizations` | |
| `location` | ref[] → `locations` | array of populated `{_id, name}` |
| `user` | array | shape not yet defined server-side (client keeps as `dynamic`, currently always empty) |
| `isDeleted` | bool | soft-delete flag |
| `createdAt`, `updatedAt` | date | |

## `locations`
From `LocationModel`:

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `organization` | ref → `organizations` | |
| `name`, `phoneNumber` | string | |
| `address` | `{ street, city, state, pinCode, country }` | |
| `department` | ref[] → `departments` | |
| `isDeleted` | bool | |
| `createdAt`, `updatedAt` | date | |

## `jobroles`
From `JobRoleModel`:

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `title` | string | |
| `organization` | ref → `organizations` | |
| `isDeleted` | bool | |
| `createdAt`, `updatedAt` | date | |

## `employees`
From `EmployeeModel` — a distinct collection from `users` (its own `_id`, own field set;
`GET /employees` and `POST /employees` are separate endpoints from `/auth/*`):

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `firstName`, `lastName`, `email`, `phoneNumber`, `gender` | string | |
| `dateOfBirth` | date | |
| `image` | `{ originalUrl, thumbnailUrl, publicId }` | |
| `video` | `{ videoUrl, publicId }` | |
| `ownedOrganizations` | ref[] → `organizations` | display string or populated object |
| `activeOrganization` | ref → `organizations` | |
| `organization`, `department`, `location`, `jobRole` | ref | single active values |
| `memberships` | array of `{ organization, role, location, department, jobRole }` | multi-org membership records |
| `signupSource`, `accountType`, `taskType` | string | |
| `taskPermission`, `agreeTerms`, `isDeleted` | bool | |
| `languageSettings` | `{ language, languageCode }` | |
| `createdAt` | date | |

## `tasks`
From `TaskModel` (`tasks/data/models/task_model.dart`):

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `taskType`, `taskId`, `title`, `priority`, `description` | string | |
| `isSubTask` | bool | |
| `parentTask` | ref → `tasks` | self-ref |
| `department` | embedded `{ _id, name }` | (its own tiny `DepartmentModel` inside this file, not the full one) |
| `assignees` | ref[] → `users`/`employees` | `{ _id, firstName, lastName, email }` |
| `reportingTo` | ref[] → same shape | |
| `reportingDate` | date | |
| `reportingTime` | `{ time, period, _id }` | e.g. `"09:00"`, `"AM"` |
| `attachments` | array of `{ _id, fileName, fileType, file: { originalUrl, thumbnailUrl, publicId }, uploadProgress, createdAt, updatedAt }` | |
| `organization` | ObjectId string (not populated here) | |
| `createdBy` | `{ _id, firstName, lastName }` | |
| `completionStatus` | string | |
| `recurrence` | `{ timePeriod, everyN, daysOfWeek[], monthlyType, dayOfMonth, weekOfMonth, dayOfWeekMonthly, rangeStart, endType, endByDate, endAfterCount, _id }` | drives repetitive-task generation |
| `proofConfig` | `{ proofTypes[], aiValidationEnabled, _id }` | |
| `createdAt`, `updatedAt` | date | |

## `taskinstances`
From `TaskInstanceModel` (`taskInstance/data/models/task_instance_model.dart`) — one document
per scheduled occurrence of a (possibly recurring) task:

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `taskDocId` | ref → `tasks` | falls back to `_id` if backend omits it |
| `instanceId` | string | falls back to `_id` |
| `scheduledDate` | date | |
| `scheduledTime` | `{ time, period, _id }` | |
| `taskType`, `title`, `description`, `priority`, `status`, `taskId` | string | |
| `department` | string[] | ids only, not populated |
| `assignees` | string[] | ids only (accepts populated `{_id}` objects too, extracts id) |
| `parentInstance` | ref → `taskinstances` | |
| `completedBy`, `reviewedBy`, `createdBy` | `{ _id, firstName, lastName }` | |
| `completedAt`, `reviewedAt` | date | |
| `reviewNote` | string | |
| `proofSubmission` | `{ submittedAt, files: [{ _id, fileType, file: {originalUrl, thumbnailUrl, publicId}, createdAt, updatedAt }], note, proofTypes[], aiValidationResult }` | dates may arrive as raw Mongo extended-JSON (`{"$date": ...}`) — the model handles both that and plain ISO strings |
| `isDeleted` | bool | |
| `createdAt`, `updatedAt` | date | |
| `timePeriod`, `everyN`, `daysOfWeek[]`, `monthlyType`, `dayOfMonth`, `weekOfMonth`, `dayOfWeekMonthly`, `rangeStart`, `endType`, `endByDate`, `endAfterCount` | — | recurrence metrics denormalized onto the instance |

`GET /tasks/instances` also returns a sibling `counts` object (not per-document, a query-level
aggregate): `{ today, tomorrow, thisWeek, nextWeek }` (see `TaskInstanceCountsModel`).

## `notifications`
From `NotificationModel` (`notifications/data/models/notification_model.dart`):

| Field | Type | Notes |
|---|---|---|
| `_id` | ObjectId | |
| `user` | ref → `users` | recipient |
| `organization` | ref → `organizations` | `{_id, name}` |
| `title`, `description` | string | |
| `type` | string | drives the app's filter tab; observed values: `task_overdue`/`overdue`, `reporting_time` ("due now"), `task_created` ("assigned") |
| `severity` | string | `success` \| `danger` \| `warning` \| `info` — drives UI color, see [THEME_GUIDE.md](THEME_GUIDE.md) |
| `notificationDate`, `sendAt`, `createdAt`, `updatedAt` | date | |
| `isRead` | bool | |
| `taskInstance` | `{ _id, scheduledDate, scheduledTime: {time, period}, status }` | |
| `task` | `{ _id, taskType, title, organization, createdBy: {_id, firstName, lastName} }` | |

## Shared value types (not their own collection)
- `PaginationModel` — `{ total, page, limit, totalPages, hasNext, hasPrev }`, returned inline on
  any paginated `BaseApiResponse`.
