# COMPONENT_LIBRARY.md

Everything actually reusable lives flat under `lib/components/` (10 files). Screen-level widgets
under `lib/screens/` are not included here even though some (e.g. `organization_setup_dialog.dart`)
are dialog-shaped, since they aren't imported outside their own screen.

## Navigation shell

### `CustomAppBar` — `components/CustomAppBar.dart`
`StatefulWidget implements PreferredSizeWidget`.

| Param | Type | Required | Notes |
|---|---|---|---|
| `scaffoldKey` | `GlobalKey<ScaffoldState>` | yes | opens the drawer |
| `userId` | `String` | yes | |
| `onBackPressed` | `VoidCallback?` | no | |
| `onTitleTapped` | `VoidCallback?` | no | |
| `showLeading` | `bool` | no (default `true`) | |
| `isOnProfilePage` | `bool` | no (default `false`) | |

Pulls `OrganizationController` via `sl<OrganizationController>()`, loads the active organization
from secure storage on `initState`, and offers an "switch organization" bottom sheet (lazily
fetches the full org list only the first time it's opened).

### `CustomBottomNavBar` — `components/CustomBottomNavBar.dart`
`StatefulWidget`. Param: `selectedIndex` (`int`, required). Four fixed tabs — Home / My Task /
Notification / More. Owns a `NotificationController` (`sl<NotificationController>()`), listens
to it for the unread badge, and triggers `handleGetNotifications()` on init.

### `CustomDrawer` — `components/CustomDrawer.dart`
`StatefulWidget`. Params: `activeTile` (`String`, required, highlights the current section),
`onTileTap` (`Function(String)`, required). Loads profile/org info via `LoginController`
(`sl<LoginController>()`) + secure storage, and links to Departments / Locations / Organizations
/ Employees / Profile / Sign-out.

## Form-section widgets (employee profile tabs)

All six implement `SectionValidatable` (`components/SectionValidatable.dart` — a one-method
interface, `bool validate()`) so a parent screen can validate every visible tab uniformly before
submit. Each is a self-contained `StatefulWidget` with its own `TextEditingController`s,
`FocusNode`s, and inline validation error strings — there's no shared base class beyond the
interface, so field-level logic is duplicated per section rather than factored out.

| Widget | Covers |
|---|---|
| `AssetSystemSection` | hardware inventory, serials (monitor/phone), software permissions, security clearance |
| `CmpFinanceSection` | pay (base/hourly/commission), bank account, tax IDs (PAN/SSN), health insurance, pension |
| `DcmntComplianceSection` | NDAs, employment agreements, offer letters, ID verification + uploaded file lists |
| `SkillPerformSection` | programming skills, certifications, OKRs, feedback, training courses |
| `TimeAttendSection` | leave balances, check-in/out, automated activity, holidays, office location |
| `EmpJobDetailsSection` | job title, department, shift, hours, reporting lines, tenure — takes `employeeData` (`Map<String, dynamic>?`, required) to prefill |

None currently reference a shared `AppTheme` (see [THEME_GUIDE.md](THEME_GUIDE.md)) — each pulls
in `GoogleFonts`/`flutter_screenutil` directly and hardcodes its own colors.

## Recommendation (not yet implemented)

The six form sections are the most obvious near-term consolidation target: they share the same
shape (`TextEditingController` + `FocusNode` + inline error + edit-toggle per field) and could
plausibly be generated from a declarative field-list instead of hand-written per section — but
that's a larger refactor, not a naming/doc fix, so it's flagged here rather than done.
