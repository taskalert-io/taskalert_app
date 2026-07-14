// ignore_for_file: deprecated_member_use, file_names
//
// ── ASSUMPTIONS (adjust to match your real files) ──────────────────────────
// import '../core/features/employees/controllers/employee_controller.dart';
// import '../core/features/employees/data/models/employee_model.dart';
//
// EmployeeModel is assumed to have (all nullable, matching your other models):
//   String? id, firstName, lastName, jobRole, department, organization,
//            email, phoneNumber;
//
// NOTE: The new "User Details" form below also captures dateOfBirth, gender,
// location, imagePath and taskPermission. Your current EmployeeModel /
// EmployeeController (per the assumptions above) don't have these fields yet.
// The values are collected in local form state so the UI matches the design,
// and are passed through to handleCreateEmployee / handleUpdateEmployee via
// optional named params — extend your controller/model to persist them, or
// remove the params if you don't need them yet. Everything else compiles and
// works standalone even if you leave those extra params unused.
//
// EmployeeController (ChangeNotifier, same shape as LocationController) is
// assumed to expose:
//   List<EmployeeModel> allEmployees;
//   bool isLoading;
//   String? successMessage;
//   String? errorMessage;
//   Future<void> handleGetEmployees();
//   Future<bool> handleDeleteEmployee({required String id});
//   Future<bool> handleCreateEmployee({required String firstName, ...});
//   Future<bool> handleUpdateEmployee({required String id, ...});
//
// ── TABLE → CARD LIST CHANGE ────────────────────────────────────────────
// The old fixed-width horizontally-scrolling table (_headerRow / _dataRow /
// _wCheckbox.._wActions / _tableWidth) has been replaced with an
// auto-sizing card list (_employeeCard / _cardDetail). Fixed pixel widths
// forced into a SizedBox were causing "RenderFlex overflowed" errors any
// time padding/fonts/content didn't match the hardcoded math exactly. Cards
// use Wrap/Expanded/ConstrainedBox instead, so they can't overflow.
//
// ── OVERLAY VIEWPORT-CLAMPING FIX ───────────────────────────────────────
// All suggestion-dropdown overlays (search suggestions, Organization /
// Location / Job Role searchable fields, Department searchable field, and
// the Location field inside the "Add Department" dialog) previously used a
// hardcoded `offset` + `maxHeight` when following their anchor field via
// CompositedTransformFollower. That works fine when the field sits near the
// top of the screen, but once the field is lower down (e.g. "Department" in
// a tall bottom sheet), the fixed 260.h/220.h/240.h dropdown box can extend
// past the bottom of the visible viewport and get clipped by the on-screen
// nav bar / system gesture bar, as seen in the "Add Department" / "hghjhc" /
// "Backend" screenshot.
//
// Fix: `_overlayPlacement()` below measures the anchor field's global
// position and the real usable screen height (accounting for the keyboard
// via viewInsets.bottom and the system nav/gesture bar via
// viewPadding.bottom), then:
//   - shrinks maxHeight to whatever room is actually left below the field,
//   - and if there isn't enough room below (less than a sensible minimum)
//     but there IS more room above, flips the dropdown to open upward
//     instead, anchored just above the field.
// Every overlay-showing call site below now asks `_overlayPlacement()` for
// its offset/maxHeight/direction instead of hardcoding them.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/departments/controllers/department_controller.dart';
import '../core/features/departments/data/models/department_model.dart';
import '../core/features/employees/controllers/employee_controller.dart';
import '../core/features/employees/data/models/employee_model.dart';
import '../core/features/jobRoles/controllers/job_role_controller.dart';
import '../core/features/jobRoles/data/models/job_role_model.dart';
import '../core/features/location/controllers/location_controller.dart';
import '../core/features/location/data/models/location_model.dart';
import '../utils/injection_container.dart';
import 'DepartmentListScreen.dart' show openDepartmentFormDialog;
import 'LocationListScreen.dart' show openLocationFormDialog;
import 'NotificationStart.dart';

// ── Shared overlay-placement helper ─────────────────────────────────────
//
// Computes where a CompositedTransformFollower-based suggestion overlay
// should sit relative to its anchor field, clamped to the real usable
// screen space. Used by every dropdown/autocomplete overlay in this file
// so none of them can ever render past the bottom of the visible screen.
class _OverlayPlacement {
  const _OverlayPlacement({
    required this.dy,
    required this.maxHeight,
    required this.showAbove,
  });

  /// Vertical offset (in logical px) to pass to
  /// `CompositedTransformFollower(offset: Offset(0, dy))`.
  /// Positive = below the field, negative = above the field.
  final double dy;

  /// Height the overlay's ConstrainedBox should be capped at.
  final double maxHeight;

  /// Whether the dropdown had to flip upward due to lack of room below.
  final bool showAbove;
}

_OverlayPlacement _overlayPlacement({
  required BuildContext context,
  required GlobalKey fieldKey,
  double preferredMaxHeight = 260,
  double minUsableHeight = 120,
  double gap = 6,
  double bottomMargin = 12,
}) {
  final preferred = preferredMaxHeight.h;
  final minUsable = minUsableHeight.h;
  final gapPx = gap.h;
  final marginPx = bottomMargin.h;

  final box = fieldKey.currentContext?.findRenderObject() as RenderBox?;
  final mq = MediaQuery.of(context);

  if (box == null || !box.attached) {
    // Can't measure yet — fall back to the old fixed behaviour.
    return _OverlayPlacement(dy: gapPx, maxHeight: preferred, showAbove: false);
  }

  final fieldHeight = box.size.height;
  final fieldTopGlobal = box.localToGlobal(Offset.zero).dy;
  final fieldBottomGlobal = fieldTopGlobal + fieldHeight;

  // Real bottom edge of usable space: screen height minus the keyboard
  // (viewInsets) and minus the system nav/gesture bar (viewPadding), which
  // is what was clipping the dropdown in the screenshot.
  final usableBottom =
      mq.size.height - mq.viewInsets.bottom - mq.viewPadding.bottom - marginPx;
  final usableTop = mq.viewPadding.top + marginPx;

  final spaceBelow = usableBottom - fieldBottomGlobal - gapPx;
  final spaceAbove = fieldTopGlobal - usableTop - gapPx;

  final belowFits = spaceBelow >= minUsable;
  final aboveIsBigger = spaceAbove > spaceBelow;

  if (belowFits || !aboveIsBigger) {
    final maxH = spaceBelow.clamp(minUsable, preferred);
    return _OverlayPlacement(
      dy: fieldHeight + gapPx,
      maxHeight: maxH,
      showAbove: false,
    );
  } else {
    final maxH = spaceAbove.clamp(minUsable, preferred);
    return _OverlayPlacement(
      dy: -(maxH + gapPx),
      maxHeight: maxH,
      showAbove: true,
    );
  }
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.userId});
  final String userId;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);

  late final EmployeeController employeeController;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ── Autocomplete plumbing ────────────────────────────────────────────────
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  final GlobalKey _searchFieldKey = GlobalKey();
  OverlayEntry? _suggestionsOverlay;
  List<EmployeeModel> _suggestions = [];

  final Set<String> _selectedIds = {};
  final ImagePicker _imagePicker = ImagePicker();

  // TODO: replace these placeholder option lists with real data — either
  // pulled from EmployeeController (e.g. controller.organizations) or from
  // a dedicated lookup/config service.
  static const List<String> _genderOptions = ["Male", "Female", "Other"];
  static const List<String> _taskTypeOptions = [
    "One Time",
    "Repetitive",
    "Both",
  ];

  /// UI label -> API value (matches EmployeeModel.taskType: 'one_time' |
  /// 'repetitive' | 'both').
  static String _taskTypeApiValue(String label) {
    switch (label) {
      case "One Time":
        return "one_time";
      case "Repetitive":
        return "repetitive";
      default:
        return "both";
    }
  }

  /// API value -> UI label, for prefilling on edit.
  static String _taskTypeLabel(String? apiValue) {
    switch (apiValue) {
      case "one_time":
        return "One Time";
      case "repetitive":
        return "Repetitive";
      default:
        return "Both";
    }
  }
  @override
  void initState() {
    super.initState();
    employeeController = sl<EmployeeController>();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      employeeController.handleGetEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _removeSuggestionsOverlay();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _updateSuggestions(_searchController.text);
    } else {
      // Small delay so a tap on a suggestion registers before we tear
      // the overlay down (otherwise the overlay disappears first and
      // the tap never lands).
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _removeSuggestionsOverlay();
        }
      });
    }
  }

  void _onSearchChanged() {
    setState(() {});
    _updateSuggestions(_searchController.text);
  }

  // ── Autocomplete: build match list + show/hide overlay ──────────────────
  void _updateSuggestions(String query) {
    final q = query.trim().toLowerCase();

    // Empty query (e.g. just tapped the field) still shows a dropdown —
    // it lists the first few employees instead of hiding until typing.
    _suggestions = q.isEmpty
        ? employeeController.allEmployees.take(6).toList()
        : employeeController.allEmployees
              .where((e) => _matchesQuery(e, q))
              .take(6)
              .toList();

    if (!_searchFocusNode.hasFocus) {
      _removeSuggestionsOverlay();
      return;
    }

    _showSuggestionsOverlay();
  }

  void _showSuggestionsOverlay() {
    _removeSuggestionsOverlay();

    final overlay = Overlay.of(context);
    final box =
        _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 240.w;

    final placement = _overlayPlacement(
      context: context,
      fieldKey: _searchFieldKey,
      preferredMaxHeight: 260,
    );

    _suggestionsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full-screen barrier so a tap anywhere outside the dropdown's own
          // content dismisses it immediately, instead of the tap being
          // silently absorbed by this entry until the focus-loss delay
          // below fires on its own.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _removeSuggestionsOverlay();
                _searchFocusNode.unfocus();
              },
            ),
          ),
          Positioned(
            width: width,
            child: CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              offset: Offset(0, placement.dy),
              child: Align(
                alignment: placement.showAbove
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10.r),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: placement.maxHeight,
                    ),
                    child: _suggestions.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 14.h,
                            ),
                            child: Text(
                              "No data found",
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFE4E7EC),
                            ),
                            itemBuilder: (context, index) {
                              final s = _suggestions[index];
                              final name =
                                  "${s.firstName ?? ''} ${s.lastName ?? ''}"
                                      .trim();
                              return InkWell(
                                onTap: () => _selectSuggestion(s),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.person_fill,
                                        size: 14.r,
                                        color: const Color(0xFF4338CA),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty
                                                  ? "(No name)"
                                                  : name,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(
                                                  0xFF1D2939,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "${s.jobRole ?? '-'} • ${s.email ?? ''}",
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                color: const Color(
                                                  0xFF667085,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_suggestionsOverlay!);
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  void _selectSuggestion(EmployeeModel employee) {
    final name = "${employee.firstName ?? ''} ${employee.lastName ?? ''}"
        .trim();

    _searchController.removeListener(_onSearchChanged);
    _searchController.text = name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchController.addListener(_onSearchChanged);

    setState(() {});

    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
  }

  bool _matchesQuery(EmployeeModel e, String q) =>
      (e.firstName ?? '').toLowerCase().contains(q) ||
      (e.lastName ?? '').toLowerCase().contains(q) ||
      (e.email ?? '').toLowerCase().contains(q);

  List<EmployeeModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    var list = employeeController.allEmployees;

    if (q.isNotEmpty) {
      list = list.where((e) => _matchesQuery(e, q)).toList();
    }
    return list;
  }

  bool get _allSelected =>
      _filtered.isNotEmpty && _selectedIds.length == _filtered.length;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds
          ..clear()
          ..addAll(_filtered.map((e) => e.id).whereType<String>());
      } else {
        _selectedIds.clear();
      }
    });
  }

  // ── CREATE / EDIT ─────────────────────────────────────────────────────────
  void _openEmployeeForm({EmployeeModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController(
      text: existing?.firstName ?? "",
    );
    final lastNameCtrl = TextEditingController(text: existing?.lastName ?? "");
    final emailCtrl = TextEditingController(text: existing?.email ?? "");
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? "");

    final dobDayCtrl = TextEditingController(
      text: existing?.dateOfBirth?.day.toString().padLeft(2, '0') ?? "",
    );
    final dobMonthCtrl = TextEditingController(
      text: existing?.dateOfBirth?.month.toString().padLeft(2, '0') ?? "",
    );
    final dobYearCtrl = TextEditingController(
      text: existing?.dateOfBirth?.year.toString() ?? "",
    );

    final genderMatches = _genderOptions.where(
      (g) => g.toLowerCase() == (existing?.gender ?? '').toLowerCase(),
    );
    String? selectedGender = genderMatches.isNotEmpty
        ? genderMatches.first
        : null;
    LocationModel? selectedLocation;
    DepartmentModel? selectedDepartment;
    JobRoleModel? selectedJobRole;
    File? selectedImageFile;
    bool taskPermission = existing?.taskPermission ?? false;
    String selectedTaskType = _taskTypeLabel(existing?.taskType);

    bool autoValidate = false;
    bool isSubmitting = false;
    String? formErrorMessage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        // Tapping anywhere inside the popup (outside whichever field/
        // dropdown is currently focused) should close that dropdown —
        // not the page-level search field, which lives outside this sheet.
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: StatefulBuilder(
          builder: (ctx, ss) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.92,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10.r,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
                  child: Form(
                    key: formKey,
                    autovalidateMode: autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "User Details",
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Icon(
                                Icons.close,
                                size: 17.r,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Divider(color: const Color(0xFFE4E7EC), height: 1.h),
                        SizedBox(height: 10.h),

                        if (formErrorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFF5B5B5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 15.r,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    formErrorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],

                        // First Name / Last Name
                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                label: "First Name",
                                required: true,
                                controller: firstNameCtrl,
                                hint: "First Name",
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Enter first name"
                                    : null,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: _formField(
                                label: "Last Name",
                                required: true,
                                controller: lastNameCtrl,
                                hint: "Last Name",
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? "Enter last name"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),

                        // Date of birth / Gender
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _dobField(
                                context: ctx,
                                setState: ss,
                                dayCtrl: dobDayCtrl,
                                monthCtrl: dobMonthCtrl,
                                yearCtrl: dobYearCtrl,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: _dropdownFormField(
                                label: "Gender",
                                hint: "Select",
                                value: selectedGender,
                                items: _genderOptions,
                                onChanged: (v) => ss(() => selectedGender = v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),

                        // Phone / Image
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _formField(
                                label: "Phone",
                                required: true,
                                controller: phoneCtrl,
                                hint: "Phone Number",
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (v) {
                                  final digits = (v ?? "").trim();
                                  if (digits.isEmpty)
                                    return "Enter phone number";
                                  if (digits.length != 10) {
                                    return "Enter a valid 10-digit number";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: _imageUploadField(
                                imageFile: selectedImageFile,
                                onTap: () => _pickImage(
                                  onPicked: (file) =>
                                      ss(() => selectedImageFile = file),
                                ),
                                onRemove: selectedImageFile == null
                                    ? null
                                    : () => ss(() => selectedImageFile = null),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),

                        // Email / Location
                        _formField(
                          label: "Email",
                          controller: emailCtrl,
                          hint: "Email",
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final val = (v ?? "").trim();
                            if (val.isEmpty) return null;
                            if (!val.contains("@") || !val.contains(".")) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 7.w),
                        _LocationSearchableField(
                          initialValue: existing?.location,
                          // Department (below) is locked until a Location
                          // is chosen and scoped to whichever one is
                          // picked, so this needs to trigger a rebuild —
                          // not just update local state silently.
                          onChanged: (loc) => ss(() {
                            // The very first call on an edit form can be the
                            // field auto-resolving `existing.location` into
                            // its real model (see _LocationSearchableField's
                            // _tryResolveInitial) rather than the user
                            // actually switching locations — don't wipe out
                            // the department that's already correct for it.
                            final isInitialAutoMatch =
                                selectedLocation == null &&
                                existing != null &&
                                loc?.name == existing.location;
                            selectedLocation = loc;
                            if (!isInitialAutoMatch) {
                              selectedDepartment = null;
                            }
                          }),
                          // Checks the resolved model, not just the text —
                          // typing something that doesn't match a real
                          // location leaves `selectedLocation` null, which
                          // would otherwise send no location at all.
                          validator: (v) => selectedLocation == null
                              ? "Select a location"
                              : null,
                        ),

                        SizedBox(height: 7.h),

                        // Job Role — Organization is no longer user-picked
                        // here; it's taken automatically from the logged-in
                        // user's active organization at submit time.
                        _JobRoleSearchableField(
                          initialValue: existing?.jobRole,
                          onChanged: (v) => ss(() => selectedJobRole = v),
                          // Optional field — no validator. If the user types
                          // free text that doesn't match a real job role,
                          // `selectedJobRole` just stays null and nothing is
                          // sent for it (see the submit handler below).
                        ),

                        SizedBox(height: 7.h),

                        // Department — locked until a Location is chosen
                        // above, same gating as the "New Department" field
                        // on CreateOneTimeScreen. Real, controller-backed
                        // search (not a static list) with an inline
                        // "+ Add Department" action that opens the same
                        // create-department popup as DepartmentListScreen.
                        // Full row width (not split into two columns) so its
                        // dropdown isn't squeezed into a half-width field.
                        _DepartmentSearchableField(
                          enabled: selectedLocation != null,
                          locationId: selectedLocation?.id,
                          initialValue: existing?.department,
                          onChanged: (v) => ss(() => selectedDepartment = v),
                          // Optional field — no validator. If the user types
                          // free text that doesn't match a real department,
                          // `selectedDepartment` just stays null and nothing
                          // is sent for it (see the submit handler below).
                        ),
                        SizedBox(height: 7.h),

                        // Task Permission toggle
                        Row(
                          children: [
                            Text(
                              "Task Permission",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3F3F3F),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            ToggleSwitch(
                              value: taskPermission,
                              colors: ThemeConst.of(ctx),
                              activeColor: Colors.green,
                              onTap: () =>
                                  ss(() => taskPermission = !taskPermission),
                            ),
                          ],
                        ),
                        // Task type radios — only shown once Task Permission is ON
                        if (taskPermission) ...[
                          SizedBox(height: 6.h),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _taskTypeOptions.map((level) {
                                final isSelected = selectedTaskType == level;
                                return InkWell(
                                  onTap: () =>
                                      ss(() => selectedTaskType = level),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: level,
                                        groupValue: selectedTaskType,
                                        activeColor: const Color(0xFF0A0258),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (v) => ss(
                                          () =>
                                              selectedTaskType = v ?? level,
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        level,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5.sp,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: const Color(0xFF344054),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        SizedBox(height: 7.h),

                        // Submit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2FD5C8),
                                    Color(0xFFB16CFF),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        ss(() {
                                          autoValidate = true;
                                          formErrorMessage = null;
                                        });
                                        if (!(formKey.currentState
                                                ?.validate() ??
                                            false)) {
                                          return;
                                        }

                                        ss(() => isSubmitting = true);

                                        final dobText =
                                            dobDayCtrl.text.trim().isNotEmpty &&
                                                dobMonthCtrl.text
                                                    .trim()
                                                    .isNotEmpty &&
                                                dobYearCtrl.text
                                                    .trim()
                                                    .isNotEmpty
                                            ? "${dobYearCtrl.text.trim()}-${dobMonthCtrl.text.trim().padLeft(2, '0')}-${dobDayCtrl.text.trim().padLeft(2, '0')}"
                                            : existing?.dateOfBirth
                                                  ?.toIso8601String();
                                        final genderValue =
                                            (selectedGender ?? existing?.gender)
                                                ?.toLowerCase();
                                        // Organization is no longer a form
                                        // field — every employee is created
                                        // under the logged-in user's own
                                        // active organization.
                                        final organizationId =
                                            await _secureStorage.read(
                                              key:
                                                  'user_active_organization_id',
                                            );
                                        // Auto-resolved from the existing
                                        // display name/id once the real
                                        // list loads (see
                                        // _LocationSearchableField's
                                        // _tryResolveInitial) — so this is
                                        // populated on edit even without the
                                        // user touching the field.
                                        final locationId = selectedLocation?.id;
                                        // Same auto-resolve story as
                                        // organization/location — matched
                                        // against the loaded lists so these
                                        // are real ids, not display names
                                        // (the API rejects a plain name as
                                        // an invalid id format). Both are
                                        // optional now, so a null id just
                                        // means the field is omitted from
                                        // the request rather than sent as an
                                        // invalid empty string.
                                        final jobRoleId = selectedJobRole?.id;
                                        final departmentId =
                                            selectedDepartment?.id;

                                        final bool success;
                                        if (existing == null) {
                                          success = await employeeController
                                              .handleCreateEmployee(
                                                firstName: firstNameCtrl.text
                                                    .trim(),
                                                lastName: lastNameCtrl.text
                                                    .trim(),
                                                jobRole: jobRoleId,
                                                email: emailCtrl.text.trim(),
                                                phoneNumber: phoneCtrl.text
                                                    .trim(),
                                                department: departmentId,
                                                organization: organizationId,
                                                location: locationId,
                                                gender: genderValue,
                                                dateOfBirth: dobText,
                                                taskPermission: taskPermission,
                                                taskType: _taskTypeApiValue(
                                                  selectedTaskType,
                                                ),
                                                imageFilePath:
                                                    selectedImageFile?.path,
                                              );
                                        } else {
                                          success = await employeeController
                                              .handleUpdateEmployee(
                                                id: existing.id ?? '',
                                                firstName: firstNameCtrl.text
                                                    .trim(),
                                                lastName: lastNameCtrl.text
                                                    .trim(),
                                                jobRole: jobRoleId,
                                                email: emailCtrl.text.trim(),
                                                phoneNumber: phoneCtrl.text
                                                    .trim(),
                                                department: departmentId,
                                                organization: organizationId,
                                                location: locationId,
                                                gender: genderValue,
                                                dateOfBirth: dobText,
                                                taskPermission: taskPermission,
                                                taskType: _taskTypeApiValue(
                                                  selectedTaskType,
                                                ),
                                                imageFilePath:
                                                    selectedImageFile?.path,
                                              );
                                        }

                                        if (!mounted) return;
                                        ss(() => isSubmitting = false);

                                        if (success) {
                                          Navigator.pop(ctx);
                                          employeeController
                                              .handleGetEmployees();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                employeeController
                                                        .successMessage ??
                                                    (existing == null
                                                        ? "User created successfully!"
                                                        : "User updated successfully!"),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFF0DA99E,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                            ),
                                          );
                                        } else {
                                          ss(
                                            () => formErrorMessage =
                                                employeeController
                                                    .errorMessage ??
                                                "Something went wrong",
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 22.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        width: 16.r,
                                        height: 16.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        existing == null
                                            ? "Create User"
                                            : "Save Changes",
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3F3F3F),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6C7278),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFFB8BEC5),
            ),
            errorStyle: TextStyle(fontSize: 10.sp),
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF0A0258)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  /// A labeled dropdown styled to match `_formField`, used for Gender,
  /// Location, Organization, Department and Job Role in the "User Details"
  /// form.
  Widget _dropdownFormField({
    required String label,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? value,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3F3F3F),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            CupertinoIcons.chevron_down,
            size: 14.r,
            color: const Color(0xFF9AA0AB),
          ),
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF344054),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFFB8BEC5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 10.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF0A0258)),
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Day / Month / Year date-of-birth field grouped inside one bordered
  /// container, matching the design.
  Widget _dobField({
    required BuildContext context,
    required void Function(void Function()) setState,
    required TextEditingController dayCtrl,
    required TextEditingController monthCtrl,
    required TextEditingController yearCtrl,
  }) {
    InputDecoration cellDecoration(String hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        color: const Color(0xFFB8BEC5),
      ),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of birth",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFD9DEE5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: dayCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: cellDecoration("Day"),
                ),
              ),
              Container(width: 1, height: 20.h, color: const Color(0xFFD9DEE5)),
              Expanded(
                child: TextFormField(
                  controller: monthCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: cellDecoration("Month"),
                ),
              ),
              Container(width: 1, height: 20.h, color: const Color(0xFFD9DEE5)),
              Expanded(
                child: TextFormField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: cellDecoration("Year"),
                ),
              ),
              // Opens a native calendar picker as an alternative to typing
              // the day/month/year in manually — selecting a date fills
              // all three fields at once.
              InkWell(
                borderRadius: BorderRadius.circular(6.r),
                onTap: () => _pickDobDate(
                  context: context,
                  setState: setState,
                  dayCtrl: dayCtrl,
                  monthCtrl: monthCtrl,
                  yearCtrl: yearCtrl,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    CupertinoIcons.calendar,
                    size: 16.r,
                    color: const Color(0xFF9AA0AB),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens Flutter's built-in Material date picker and, on a selection,
  /// fills the day/month/year controllers together.
  Future<void> _pickDobDate({
    required BuildContext context,
    required void Function(void Function()) setState,
    required TextEditingController dayCtrl,
    required TextEditingController monthCtrl,
    required TextEditingController yearCtrl,
  }) async {
    final now = DateTime.now();
    final day = int.tryParse(dayCtrl.text.trim());
    final month = int.tryParse(monthCtrl.text.trim());
    final year = int.tryParse(yearCtrl.text.trim());

    DateTime initialDate = DateTime(now.year - 18, now.month, now.day);
    if (day != null && month != null && year != null) {
      try {
        initialDate = DateTime(year, month, day);
      } catch (_) {
        // Keep the fallback above if the typed values don't form a valid date.
      }
    }
    if (initialDate.isAfter(now)) initialDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: "Select date of birth",
    );

    if (picked != null) {
      setState(() {
        dayCtrl.text = picked.day.toString().padLeft(2, '0');
        monthCtrl.text = picked.month.toString().padLeft(2, '0');
        yearCtrl.text = picked.year.toString();
      });
    }
  }

  /// Upload box + helper hint text, matching the "Image" field in the
  /// design. Wire up `image_picker` inside `onTap` to make it functional.
  Widget _imageUploadField({
    required File? imageFile,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Image",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFD9DEE5)),
                    ),
                    child: imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 16.r,
                                color: const Color(0xFF6C7278),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Upload",
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: const Color(0xFF6C7278),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Image.file(imageFile, fit: BoxFit.cover),
                  ),
                  if (imageFile != null && onRemove != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 11.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "The image format is .jpg .jpeg .png and a minimum size of 300 X 300px",
                style: GoogleFonts.inter(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF9AA0AB),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(EmployeeModel employee) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Delete User",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"${employee.firstName} ${employee.lastName}\"?",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF324054),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await employeeController.handleDeleteEmployee(
        id: employee.id ?? '',
      );

      if (!mounted) return;

      setState(() {
        _selectedIds.remove(employee.id);
      });

      if (success) {
        employeeController.handleGetEmployees();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (employeeController.successMessage ?? "User deleted")
                : (employeeController.errorMessage ?? "Failed to delete user"),
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }

  Future<void> _pickImage({required ValueChanged<File> onPicked}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E7EC),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 12.h),
            ListTile(
              leading: const Icon(
                CupertinoIcons.camera_fill,
                color: Color(0xFF0A0258),
              ),
              title: Text(
                "Take Photo",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.photo_fill_on_rectangle_fill,
                color: Color(0xFF0A0258),
              ),
              title: Text(
                "Choose from Gallery",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked != null) {
        onPicked(File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't access camera/gallery: $e",
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Users", onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: employeeController,
        builder: (context, _) {
          final filtered = _filtered;
          final isInitialLoading =
              employeeController.isLoading &&
              employeeController.allEmployees.isEmpty;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _searchFocusNode.unfocus(),
            child: Container(
              color: const Color(0xFFF5F7FB),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20.r,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Users List",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search + Add User
                  Row(
                    children: [
                      Expanded(
                        child: CompositedTransformTarget(
                          link: _searchLayerLink,
                          child: TextField(
                            key: _searchFieldKey,
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onTap: () =>
                                _updateSuggestions(_searchController.text),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF344054),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Search Users",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFFB8BEC5),
                              ),
                              prefixIcon: Icon(
                                CupertinoIcons.search,
                                size: 14.r,
                                color: const Color(0xFF9AA0AB),
                              ),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _updateSuggestions('');
                                      },
                                      child: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 14.r,
                                        color: const Color(0xFF9AA0AB),
                                      ),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 8.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD9DEE5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD9DEE5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2FD5C8), Color(0xFFB16CFF)],
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _openEmployeeForm(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.add,
                            size: 16.r,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Add User",
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Select all row — replaces the old table header, only
                  // shown when there's something to select.
                  if (!isInitialLoading && filtered.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32.w,
                            child: Checkbox(
                              value: _allSelected,
                              activeColor: const Color(0xFF0A0258),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: _toggleSelectAll,
                            ),
                          ),
                          Text(
                            _selectedIds.isEmpty
                                ? "Select all"
                                : "${_selectedIds.length} selected",
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF344054),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Employee cards — auto-sizing, replaces the old
                  // fixed-width table so it can never overflow.
                  Expanded(
                    child: isInitialLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No users found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: employeeController.handleGetEmployees,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(bottom: 8.h),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) =>
                                  _employeeCard(filtered[index], index),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }

  /// Card representation of a single employee row. Replaces the old
  /// fixed-width `_dataRow` — uses Wrap/Expanded so it auto-sizes and
  /// can never overflow regardless of content length or font scaling.
  Widget _employeeCard(EmployeeModel employee, int index) {
    final isChecked = _selectedIds.contains(employee.id);
    final name = "${employee.firstName ?? ''} ${employee.lastName ?? ''}"
        .trim();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: checkbox + name + actions menu
          Row(
            children: [
              SizedBox(
                width: 32.w,
                child: Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF0A0258),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      if (employee.id != null) _selectedIds.add(employee.id!);
                    } else {
                      _selectedIds.remove(employee.id);
                    }
                  }),
                ),
              ),
              Expanded(
                child: Text(
                  name.isEmpty ? "(No name)" : name,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: Offset(0, 34.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD9DEE5)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 13.r,
                    color: const Color(0xFF344054),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEmployeeForm(existing: employee);
                  } else if (value == 'delete') {
                    _confirmDelete(employee);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.pencil,
                          size: 16.r,
                          color: const Color(0xFF17C3B2),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Edit",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          size: 16.r,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Delete",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(height: 1.h, color: const Color(0xFFF0F1F3)),
          SizedBox(height: 8.h),

          // Detail rows — wraps naturally, no fixed widths anywhere so
          // this can never trigger a RenderFlex overflow.
          Wrap(
            spacing: 16.w,
            runSpacing: 6.h,
            children: [
              _cardDetail(
                CupertinoIcons.briefcase_fill,
                employee.jobRole ?? "-",
              ),
              _cardDetail(
                CupertinoIcons.square_grid_2x2,
                employee.department?.isNotEmpty == true
                    ? employee.department!
                    : "N/A",
              ),
              _cardDetail(
                CupertinoIcons.building_2_fill,
                employee.organization ?? "-",
              ),
              _cardDetail(
                CupertinoIcons.location_solid,
                employee.location ?? "-",
              ),
              _cardDetail(
                CupertinoIcons.phone_fill,
                employee.phoneNumber ?? "-",
              ),
            ],
          ),
          if ((employee.email ?? '').isNotEmpty) ...[
            SizedBox(height: 6.h),
            _cardDetail(
              CupertinoIcons.mail_solid,
              employee.email!,
              color: const Color(0xFF3B82F6),
            ),
          ],
        ],
      ),
    );
  }

  /// A single icon + label chip used inside `_employeeCard`'s Wrap. Uses
  /// ConstrainedBox (max width) + ellipsis instead of a fixed SizedBox
  /// width, so long values truncate gracefully instead of overflowing.
  Widget _cardDetail(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.r, color: const Color(0xFF9AA0AB)),
        SizedBox(width: 4.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 160.w),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: color ?? const Color(0xFF344054),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Location searchable field (live data) ──────────────────────────────
//
// Backed by real `LocationController` data. Hands the full `LocationModel`
// back to the parent (not just its name) so the Department field below
// can be scoped to the chosen location's id.
class _LocationSearchableField extends StatefulWidget {
  const _LocationSearchableField({
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final String? initialValue;
  final ValueChanged<LocationModel?> onChanged;
  final String? Function(String?)? validator;

  @override
  State<_LocationSearchableField> createState() =>
      _LocationSearchableFieldState();
}

class _LocationSearchableFieldState extends State<_LocationSearchableField> {
  late final LocationController _locationController = sl<LocationController>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _resolvedInitial = false;

  @override
  void initState() {
    super.initState();
    _locationController.handleGetLocations();
    _focusNode.addListener(_onFocusChanged);
    _locationController.addListener(_onLocationsChanged);
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationsChanged);
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Editing an existing employee only has the location's display name (or
  // id) to start from, not the full model — once the real list loads, match
  // it up so the parent gets the id (needed to scope the Department field)
  // without the user having to reselect a Location that's already correct.
  void _tryResolveInitial() {
    if (_resolvedInitial) return;
    final initial = widget.initialValue;
    if (initial == null || initial.isEmpty) {
      _resolvedInitial = true;
      return;
    }
    if (_locationController.locations.isEmpty) return;
    final matches = _locationController.locations.where(
      (l) => l.name == initial || l.id == initial,
    );
    _resolvedInitial = true;
    if (matches.isNotEmpty) widget.onChanged(matches.first);
  }

  void _onLocationsChanged() {
    _tryResolveInitial();
    if (_focusNode.hasFocus) _showOverlay();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Small delay so a tap on a suggestion registers before the overlay
      // is torn down.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onTextChanged(String text) {
    setState(() {});
    // Manual typing invalidates whatever was previously selected — a valid
    // choice only exists once the user picks a suggestion below, since we
    // need the location's id, not just its name.
    widget.onChanged(null);
    _showOverlay();
  }

  void _clear() {
    setState(() => _controller.clear());
    widget.onChanged(null);
    _showOverlay();
  }

  void _select(LocationModel location) {
    setState(() {
      _controller.text = location.name;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: location.name.length),
      );
    });
    widget.onChanged(location);
    _removeOverlay();
    _focusNode.unfocus();
  }

  // Reuses the real Location create/edit form (see LocationListScreen.dart's
  // `openLocationFormDialog`) instead of a simplified quick-add — same as
  // CreateOneTimeScreen's Location field. Newly created locations are
  // auto-selected the same way picking a suggestion from the list works.
  void _openAddLocationDialog() {
    _removeOverlay();
    _focusNode.unfocus();
    openLocationFormDialog(
      context: context,
      locationController: _locationController,
      onCreated: _select,
    );
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 200.w;

    final placement = _overlayPlacement(
      context: context,
      fieldKey: _fieldKey,
      preferredMaxHeight: 240,
    );

    final q = _controller.text.trim().toLowerCase();
    final results = q.isEmpty
        ? _locationController.locations
        : _locationController.locations
              .where((l) => l.name.toLowerCase().contains(q))
              .toList();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, placement.dy),
          child: Align(
            alignment: placement.showAbove
                ? Alignment.bottomLeft
                : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: placement.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _openAddLocationDialog,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.add_circled_solid,
                              size: 14.r,
                              color: const Color(0xFF0A0258),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "Add Location",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                    if (_locationController.isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Center(
                          child: SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    else if (results.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        child: Text(
                          "No locations found",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (context, index) {
                            final loc = results[index];
                            return InkWell(
                              onTap: () => _select(loc),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      size: 14.r,
                                      color: const Color(0xFF4338CA),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        loc.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1D2939),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Location",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            key: _fieldKey,
            controller: _controller,
            focusNode: _focusNode,
            validator: widget.validator,
            onTap: _showOverlay,
            onChanged: _onTextChanged,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: "Search location",
              hintStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFFB8BEC5),
              ),
              errorStyle: TextStyle(fontSize: 10.sp),
              prefixIcon: Icon(
                CupertinoIcons.location_solid,
                size: 14.r,
                color: const Color(0xFF9AA0AB),
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: _clear,
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        size: 14.r,
                        color: const Color(0xFF9AA0AB),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFF0A0258)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Job Role searchable field (live data) ───────────────────────────────
//
// Same shape as `_DepartmentSearchableField` below — backed by real
// `JobRoleController` data instead of a static list, and hands the
// selected role's *title* back to the parent (matching how the employee
// APIs already accept `jobRole` as a plain string, not an id).
class _JobRoleSearchableField extends StatefulWidget {
  const _JobRoleSearchableField({
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final String? initialValue;
  final ValueChanged<JobRoleModel?> onChanged;
  final String? Function(String?)? validator;

  @override
  State<_JobRoleSearchableField> createState() =>
      _JobRoleSearchableFieldState();
}

class _JobRoleSearchableFieldState extends State<_JobRoleSearchableField> {
  late final JobRoleController _jobRoleController = sl<JobRoleController>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _resolvedInitial = false;

  @override
  void initState() {
    super.initState();
    _jobRoleController.handleGetJobRoles();
    _focusNode.addListener(_onFocusChanged);
    _jobRoleController.addListener(_onJobRolesChanged);
  }

  @override
  void dispose() {
    _jobRoleController.removeListener(_onJobRolesChanged);
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Editing an existing employee only has the job role's display title (or
  // id) to start from, not the full model — once the real list loads, match
  // it up so the parent gets the id the create/update API actually requires
  // (a plain title string is rejected as an invalid id format).
  void _tryResolveInitial() {
    if (_resolvedInitial) return;
    final initial = widget.initialValue;
    if (initial == null || initial.isEmpty) {
      _resolvedInitial = true;
      return;
    }
    if (_jobRoleController.jobRoles.isEmpty) return;
    final matches = _jobRoleController.jobRoles.where(
      (j) => j.title == initial || j.id == initial,
    );
    _resolvedInitial = true;
    if (matches.isNotEmpty) widget.onChanged(matches.first);
  }

  void _onJobRolesChanged() {
    _tryResolveInitial();
    if (_focusNode.hasFocus) _showOverlay();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Small delay so a tap on a suggestion registers before the overlay
      // is torn down.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onTextChanged(String text) {
    setState(() {});
    // Manual typing invalidates whatever was previously selected — a valid
    // choice only exists once the user picks a suggestion below, since we
    // need the job role's id, not just its title.
    widget.onChanged(null);
    _showOverlay();
  }

  void _clear() {
    setState(() => _controller.clear());
    widget.onChanged(null);
    _showOverlay();
  }

  void _select(JobRoleModel role) {
    setState(() {
      _controller.text = role.title;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: role.title.length),
      );
    });
    widget.onChanged(role);
    _removeOverlay();
    _focusNode.unfocus();
  }

  // Job roles only ever need a title, so unlike Location/Department this
  // is a plain one-field quick-add dialog rather than reusing a bigger
  // form — wired to the existing `JobRoleController.handleCreateJobRole`.
  void _openAddJobRoleDialog() {
    _removeOverlay();
    _focusNode.unfocus();

    final titleCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, dss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            "Add Job Role",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              color: const Color(0xFF0A0258),
            ),
          ),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Job title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Enter a job title"
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text("Cancel", style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(dialogFormKey.currentState?.validate() ??
                          false)) {
                        return;
                      }
                      dss(() => submitting = true);

                      final title = titleCtrl.text.trim();
                      final success = await _jobRoleController
                          .handleCreateJobRole(title: title);

                      dss(() => submitting = false);

                      if (success) {
                        final created = _jobRoleController.jobRoles
                            .where((j) => j.title == title)
                            .firstOrNull;
                        if (mounted && created != null) _select(created);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      }
                    },
              child: submitting
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("Add", style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 200.w;

    final placement = _overlayPlacement(
      context: context,
      fieldKey: _fieldKey,
      preferredMaxHeight: 240,
    );

    final q = _controller.text.trim().toLowerCase();
    final results = q.isEmpty
        ? _jobRoleController.jobRoles
        : _jobRoleController.jobRoles
              .where((j) => j.title.toLowerCase().contains(q))
              .toList();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, placement.dy),
          child: Align(
            alignment: placement.showAbove
                ? Alignment.bottomLeft
                : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: placement.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _openAddJobRoleDialog,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.add_circled_solid,
                              size: 14.r,
                              color: const Color(0xFF0A0258),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "Add Job Role",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                    if (_jobRoleController.isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Center(
                          child: SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    else if (results.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        child: Text(
                          "No job roles found",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (context, index) {
                            final role = results[index];
                            return InkWell(
                              onTap: () => _select(role),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.briefcase_fill,
                                      size: 14.r,
                                      color: const Color(0xFF4338CA),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        role.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1D2939),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Job Role",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            key: _fieldKey,
            controller: _controller,
            focusNode: _focusNode,
            validator: widget.validator,
            onTap: _showOverlay,
            onChanged: _onTextChanged,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: "Search job role",
              hintStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFFB8BEC5),
              ),
              errorStyle: TextStyle(fontSize: 10.sp),
              prefixIcon: Icon(
                CupertinoIcons.briefcase_fill,
                size: 14.r,
                color: const Color(0xFF9AA0AB),
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: _clear,
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        size: 14.r,
                        color: const Color(0xFF9AA0AB),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFF0A0258)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Department searchable field (live data + inline "Add Department") ─────
//
// Backed by real `DepartmentController` data, and with a pinned
// "+ Add Department" row at the top of its dropdown that opens the same
// create-department popup as DepartmentListScreen. Locked (disabled) until
// a Location has been chosen in the parent form, mirroring the "New
// Department" field pattern on CreateOneTimeScreen.
class _DepartmentSearchableField extends StatefulWidget {
  const _DepartmentSearchableField({
    required this.enabled,
    required this.locationId,
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final bool enabled;
  // Departments are scoped to whichever Location is selected in the parent
  // form — only departments whose `location.id` matches this are shown.
  final String? locationId;
  final String? initialValue;
  final ValueChanged<DepartmentModel?> onChanged;
  final String? Function(String?)? validator;

  @override
  State<_DepartmentSearchableField> createState() =>
      _DepartmentSearchableFieldState();
}

class _DepartmentSearchableFieldState
    extends State<_DepartmentSearchableField> {
  late final DepartmentController _departmentController =
      sl<DepartmentController>();
  late final LocationController _locationController = sl<LocationController>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _resolvedInitial = false;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _departmentController.handleGetDepartments(search: '');
    _focusNode.addListener(_onFocusChanged);
    _departmentController.addListener(_onDepartmentsChanged);
  }

  @override
  void didUpdateWidget(covariant _DepartmentSearchableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Location was cleared or switched out from under us — reset so a
    // stale department name can't be submitted for a location that's no
    // longer selected (or a different one). Exception: on an edit form the
    // very first `locationId` transition (null -> real id) is the Location
    // field auto-resolving `existing.location`, not the user switching
    // locations — don't wipe the department that's already correct for it.
    final locationChanged = widget.locationId != oldWidget.locationId;
    final isInitialLocationResolve =
        oldWidget.locationId == null &&
        widget.locationId != null &&
        !_userInteracted;
    if ((!widget.enabled && oldWidget.enabled) ||
        (locationChanged && !isInitialLocationResolve)) {
      // Just the local visual reset — the parent already cleared its own
      // `selectedDepartment` state when the location changed.
      _controller.clear();
      _removeOverlay();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _departmentController.removeListener(_onDepartmentsChanged);
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Editing an existing employee only has the department's display name (or
  // id) to start from, not the full model — once the real list loads, match
  // it up so the parent gets the id the create/update API actually requires
  // (a plain name string is rejected as an invalid id format).
  void _tryResolveInitial() {
    if (_resolvedInitial) return;
    final initial = widget.initialValue;
    if (initial == null || initial.isEmpty) {
      _resolvedInitial = true;
      return;
    }
    if (_departmentController.departments.isEmpty) return;
    final matches = _departmentController.departments.where(
      (d) => d.name == initial || d.id == initial,
    );
    _resolvedInitial = true;
    if (matches.isNotEmpty) widget.onChanged(matches.first);
  }

  void _onDepartmentsChanged() {
    _tryResolveInitial();
    if (_focusNode.hasFocus) _showOverlay();
  }

  void _onFocusChanged() {
    if (!widget.enabled) return;
    if (_focusNode.hasFocus) {
      _departmentController.handleGetDepartments(
        search: _controller.text.trim(),
      );
      _showOverlay();
    } else {
      // Small delay so a tap on a suggestion (or "Add Department") registers
      // before the overlay is torn down.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onTextChanged(String text) {
    setState(() {});
    _userInteracted = true;
    // Manual typing invalidates whatever was previously selected — a valid
    // choice only exists once the user picks a suggestion below, since we
    // need the department's id, not just its name.
    widget.onChanged(null);
    _departmentController.handleGetDepartments(search: text.trim());
  }

  void _clear() {
    setState(() => _controller.clear());
    _userInteracted = true;
    widget.onChanged(null);
    _departmentController.handleGetDepartments(search: '');
  }

  void _select(DepartmentModel dept) {
    final name = dept.name ?? '';
    setState(() {
      _controller.text = name;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: name.length),
      );
    });
    _userInteracted = true;
    widget.onChanged(dept);
    _removeOverlay();
    _focusNode.unfocus();
  }

  // Reuses the real Department create/edit form (see
  // DepartmentListScreen.dart's `openDepartmentFormDialog`) instead of a
  // simplified quick-add — same as the Location field above. Newly created
  // departments are auto-selected the same way picking a suggestion from
  // the list already works.
  void _openAddDepartmentDialog() {
    _removeOverlay();
    _focusNode.unfocus();
    // `openDepartmentFormDialog`'s Location field expects its
    // `locationController` to already be loaded (it doesn't fetch on its
    // own — see _LocationMultiSelectField) — this field's own
    // `_locationController` is otherwise idle until this dialog opens, so
    // nothing had ever triggered that fetch.
    _locationController.handleGetLocations();
    openDepartmentFormDialog(
      context: context,
      departmentController: _departmentController,
      locationController: _locationController,
      onCreated: _select,
    );
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 200.w;

    final placement = _overlayPlacement(
      context: context,
      fieldKey: _fieldKey,
      preferredMaxHeight: 260,
      // The "Add Department" row is pinned inside the box regardless of
      // scroll, so keep a slightly larger floor than other overlays to
      // make sure it (plus a couple of results) stays comfortably usable.
      minUsableHeight: 160,
    );

    final q = _controller.text.trim().toLowerCase();
    final results = _departmentController.departments
        .where((d) => d.location.any((l) => l.id == widget.locationId))
        .where((d) => q.isEmpty || (d.name ?? '').toLowerCase().contains(q))
        .toList();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, placement.dy),
          child: Align(
            alignment: placement.showAbove
                ? Alignment.bottomLeft
                : Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: placement.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _openAddDepartmentDialog,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CupertinoIcons.add_circled_solid,
                              size: 14.r,
                              color: const Color(0xFF0A0258),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "Add Department",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                    if (_departmentController.isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (results.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        child: Text(
                          "No departments found",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (context, index) {
                            final dept = results[index];
                            return InkWell(
                              onTap: () => _select(dept),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.square_grid_2x2,
                                      size: 14.r,
                                      color: const Color(0xFF4338CA),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        dept.name ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1D2939),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Department",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        CompositedTransformTarget(
          link: _layerLink,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: TextFormField(
              key: _fieldKey,
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              validator: widget.validator,
              onTap: () => _showOverlay(),
              onChanged: _onTextChanged,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF344054),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.enabled
                    ? "Search department"
                    : "Select a location first",
                hintStyle: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8BEC5),
                ),
                errorStyle: TextStyle(fontSize: 10.sp),
                prefixIcon: Icon(
                  CupertinoIcons.square_grid_2x2,
                  size: 14.r,
                  color: const Color(0xFF9AA0AB),
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: _clear,
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 14.r,
                          color: const Color(0xFF9AA0AB),
                        ),
                      ),
                filled: true,
                fillColor: const Color(0xFFF9FAFC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF0A0258)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
