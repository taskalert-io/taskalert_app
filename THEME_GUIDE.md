# THEME_GUIDE.md

**There is no `AppTheme` in this codebase today.** `lib/main.dart` sets exactly one thing on
`ThemeData`:

```dart
theme: ThemeData(textTheme: GoogleFonts.interTextTheme()),
```

Every color, spacing value, and per-widget text style is then hardcoded again at the point of
use. This doc records the *de facto* conventions that have emerged anyway, so a future
`AppTheme` can be extracted from real usage instead of invented from scratch. This is the
biggest gap against [PROJECT_RULES.md](PROJECT_RULES.md)'s "No hardcoded colors / Use AppTheme"
rule.

## Typography

- **Font:** `GoogleFonts.inter(...)` — used on essentially every `Text` widget across every
  screen and component. This is consistent app-wide.
- Sizes are ad hoc per screen (`11.sp`–`22.sp` observed), generally: `11–12.sp` for
  captions/labels, `13–15.sp` for body, `18.sp`+ for headers/titles.
- Weight conventions: `FontWeight.w400` body text, `w600` for interactive/emphasized labels,
  `w700` for titles and selected states.

## Spacing & sizing

- **`flutter_screenutil`** throughout: `.w`/`.h` for spacing and dimensions, `.r` for radii/icon
  sizes, `.sp` for font sizes.
- Design size fixed in `main.dart`: `ScreenUtilInit(designSize: Size(360, 690), minTextAdapt:
  true, splitScreenMode: true)`.
- Text scaling is deliberately locked: `MediaQuery(...).copyWith(textScaler:
  TextScaler.linear(1.0))` — the app opts out of the OS accessibility text-size setting in favor
  of its own `.sp` scaling.

## Colors

No shared palette file exists. Two brand colors recur constantly (242 occurrences across 28
files) even without being centralized:

| Hex | Seen as | Typical use |
|---|---|---|
| `0xFF0A0258` | deep navy/indigo | headers, date-picker `ColorScheme.light(primary: ...)`, adaptive icon background in `pubspec.yaml`/`flutter_launcher_icons` |
| `0xFF6C5CE7` | purple | primary interactive accent — buttons, selected chips/tabs, links (e.g. `NotificationStart`'s `_C.primary`) |

**The dominant pattern:** almost every screen defines its own private `_C` class of `static
const Color` fields (see `NotificationStart.dart`'s `_C`, `EmployeesScreen.dart`'s
`_primaryColor`, etc.) — same idea as a theme, but copy-pasted and re-declared per screen instead
of shared. Extracting these into one `AppColors`/`AppTheme` is mechanical (the fields are already
named semantically — `primary`, `subtitle`, `cardBorder`, `sectionLabel`, ...) but hasn't been
done yet.

### Semantic severity palette (the one place a shared system already exists)

`NotificationStart.dart`'s `kSeverityConfig` (`Map<NotifSeverity, SeverityStyle>`) is the
one genuinely reusable, non-screen-local color system in the app — it mirrors a web
`SEVERITY_STYLE` spec 1:1 so the backend can drive UI color with a plain string:

| Severity | dot / bar | icon-wrap bg | icon-wrap fg | card border |
|---|---|---|---|---|
| `success` | `#22C55E` | `#DCFCE7` (green-100) | `#22C55E` | `#BBF7D0` (green-200) |
| `danger` | `#EF4444` | `#FEE2E2` (red-100) | `#EF4444` | `#FECACA` (red-200) |
| `warning` | `#F59E0B` | `#FEF3C7` (amber-100) | `#F59E0B` | `#FDE68A` (amber-200) |
| `info` | `#3B82F6` | `#BFDBFE` (tertiary/blue-200) | `#1D4ED8` | `#BFDBFE` |

If/when a real `AppTheme` gets built, this table is the pattern to generalize app-wide (one
semantic map, colors derived from it, never re-typed as raw hex per screen).

## Recommendation (not yet implemented)

1. Introduce `lib/core/theme/app_colors.dart` and `app_theme.dart`, seeded from the two brand
   hexes above plus the semantic severity map.
2. Migrate each screen's private `_C` class to reference `AppColors` instead of re-declaring hex
   values — this is a low-risk, mechanical refactor since the field names already line up.
3. Only after that, start enforcing "no hardcoded colors" as a lint/review rule — enforcing it
   today would immediately fail on ~every existing screen.
