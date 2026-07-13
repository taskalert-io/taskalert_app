# CLAUDE.md — taskalert_app patterns reference

Living reference of patterns already established in this codebase. Check here
before building something that "sounds similar" to existing screens/features —
reuse the pattern instead of inventing a new one.

## Architecture

- Layered: abstract `Repository` → `RepositoryImpl` (Dio via `HttpService`) →
  `Controller` (ChangeNotifier) → UI (screens read the controller directly via
  a State field, no Provider/Riverpod).
- DI via GetIt (`sl`, `lib/utils/injection_container.dart`):
  `registerLazySingleton` for repositories, `registerFactory` for controllers
  (a fresh controller instance per `sl<XController>()` call — screens typically
  hold `late final XController xController = sl<XController>();` as their own
  instance).
- `ApiResult<T>` (`Success`/`Failure`), `BaseApiResponse<T>`
  (`success`/`message`/`data`/`pagination`/`validationErrors`).

## Reusable dialog functions (create/edit forms shared across screens)

`openLocationFormDialog` (`LocationListScreen.dart`) and
`openDepartmentFormDialog` (`DepartmentListScreen.dart`) and
`openOrganizationFormDialog` (`OrganizationListScreen.dart`) are top-level
functions (not private State methods) so any screen can open the exact same
create/edit UI, e.g. from a "+ Add X" row pinned inside another form's
dropdown. Pattern to follow when adding a new one:
- `void openXFormDialog({required BuildContext context, required XController
  xController, XModel? existing, ValueChanged<XModel>? onCreated, bool
  canAddY = true})`.
- The `canAddY` flag dims/disables a *nested* "+ Add Y" option when this
  dialog was itself opened from Y's own "+ Add X" flow — prevents an
  infinite dialog-within-dialog stack. `LocationListScreen.dart` and
  `DepartmentListScreen.dart` cross-import each other with `show` to wire
  this both ways.

## Searchable dropdown-with-overlay pattern

Used for single-field autocomplete search boxes (Location, Department, Job
Role fields in `EmployeesScreen.dart`, `CreateOneTimeScreen.dart`,
`CreateRepetitiveScreen.dart`): `TextEditingController` + `FocusNode` +
`LayerLink` + `OverlayEntry` + `GlobalKey`, with a shared placement helper
that flips the overlay above/below the field depending on available space.
A "+ Add X" row is often pinned above the results list, calling the reusable
dialog function above.

## Multi-select employee picker (bottom sheet with search)

Used in `CreateOneTimeScreen.dart`/`CreateRepetitiveScreen.dart`
(`_showAssignToBottomSheet`) and `MyTaskDetails.dart`'s "Assign To" field.
Inline `StatefulBuilder` inside `showModalBottomSheet` (not a separate
widget class) — that's this codebase's convention even for fairly complex
sheets. Shape: local `tempSelected`/`filtered` lists seeded from the real
selection, a search `TextField` filtering by name/role, checkbox rows, and
"Clear All" + "Confirm (N)" buttons that only commit back to the real state
on Confirm (search/toggling mid-session doesn't mutate state until then).

## Inline form-level error banner (not SnackBar) inside bottom-sheet forms

A `SnackBar` triggered via `ScaffoldMessenger.of(context)` from *inside* a
`showModalBottomSheet` renders on the Scaffold *behind* the sheet — easy to
miss or fully hidden. Pattern used across `EmployeesScreen.dart`,
`OrganizationListScreen.dart`: a local `String? formErrorMessage` state var,
cleared at the start of each submit attempt, rendered as a red
bordered/backgrounded `Container` banner near the top of the form, set
instead of showing a SnackBar on failure.

## Dio multipart/FormData gotchas

- `FormData.fromMap` does **not** recurse into nested `Map`/`List` values
  cleanly for this backend — `jsonEncode()` the nested object/array first and
  send it as a single string field (established in Organization's `address`
  field, Location/Department's array-of-ids fields).
- `HttpService.delete`/`put`/`patch`/`post` all accept an optional `body:`
  now — don't assume `delete` is path-only.
- If a repository method builds a `MultipartFile` conditionally (only when a
  file is present), the request body must *conditionally* become
  `FormData.fromMap(map)` too — passing a `Map` containing a `MultipartFile`
  straight through as a plain JSON body silently fails to serialize it (this
  was a real, shipped bug in `createOrganization`).

## Backend ref-field conventions

- ObjectId ref fields reject an empty string ("invalid ID format") — only
  include them in a request map when `!= null && isNotEmpty`.
- Ref fields (assignee, organization, createdBy, etc.) sometimes come back as
  a populated `{"_id": ..., "name"/"firstName"+"lastName": ...}` object and
  sometimes as a plain ID string — parse defensively for both shapes
  (`UserOrganizationRef.fromDynamic`, `NotificationOrganization._parseOrganization`,
  `CreatedByModel` reused for `TaskInstanceModel.assigneeRefs`). Prefer using
  a populated ref's name directly over a second lookup against a separately
  fetched, possibly-incomplete directory list.

## Notification `type` field — real values (confirmed against live API data)

The screen-side `NotifFilter` categories map from `NotificationModel.type` as follows (`NotificationStart.dart`'s `filterFromApi`):
- Overdue → `task_overdue`
- Due Now → `reporting_time`
- Assigned → `task_created`
- Anything else (e.g. `task_updated`) → falls into "All" only, no dedicated tab.

Don't guess new `type` values for other categories — ask for a real sample
JSON response first; guessed values silently fail (that's exactly what
happened here before it was fixed).

## Task-creation → destination-screen navigation

On a create-flow's success (task creation, org switch), navigate to a
**fresh instance** of the destination screen via
`Navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) =>
DestinationScreen(...)), (route) => false)` rather than `Navigator.pop`. This
codebase has no global cache/store to invalidate — a fresh screen instance's
own `initState` re-fetch is the reliable way to show up-to-date data and clear
stale create-flow screens off the back stack.

## Verification bar for every change

Before calling any task done: `dart analyze <changed file>` (zero new
errors — pre-existing warnings/info in unrelated code are fine), then
`dart analyze lib/ 2>&1 | grep -i "error -"` project-wide to confirm nothing
else broke.
