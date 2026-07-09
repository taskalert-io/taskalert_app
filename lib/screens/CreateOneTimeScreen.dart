// ignore_for_file: deprecated_member_use, file_names, unrelated_type_equality_checks, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:taskalert_app/core/features/departments/controllers/department_controller.dart';
import 'package:taskalert_app/core/features/departments/data/models/department_model.dart';
import 'package:taskalert_app/core/features/employees/data/models/employee_model.dart';
import 'package:taskalert_app/core/features/tasks/controllers/task_controller.dart';
import 'package:taskalert_app/utils/injection_container.dart';

import '../core/features/employees/controllers/employee_controller.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// MOCK MODEL — Location option used for the autocomplete search field.
/// Swap for your real LocationModel / LocationController.locations once
/// that repository is wired up (mirrors the DepartmentModel pattern).
/// ─────────────────────────────────────────────────────────────────────────
class LocationOptionModel {
  final String id;
  final String name;
  final String city;
  LocationOptionModel({
    required this.id,
    required this.name,
    required this.city,
  });
}

class CreateOneTimeScreen extends StatefulWidget {
  const CreateOneTimeScreen({super.key, required this.userId});
  final String userId;

  @override
  State<StatefulWidget> createState() => CreateOneTimeScreenState();
}

class CreateOneTimeScreenState extends State<CreateOneTimeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  // ── Section error strings ──────────────────────────────────────────────────
  String? _assignToError;
  String? _dueDateError;
  String? _reportingToError;

  // ── Location (autocomplete search, mirrors LocationListScreen) ────────────
  final TextEditingController locationSearchController =
      TextEditingController();
  final FocusNode locationFocusNode = FocusNode();
  final LayerLink locationLayerLink = LayerLink();
  OverlayEntry? _locationSuggestionsOverlay;
  List<LocationOptionModel> _locationSuggestions = [];
  LocationOptionModel? selectedLocation;
  String? _locationError;
  final GlobalKey _locationFieldKey = GlobalKey();

  // Mock — swap for LocationController.locations once wired up
  final List<LocationOptionModel> _mockLocations = [
    LocationOptionModel(id: "1", name: "Second Office", city: "Kolkata"),
    LocationOptionModel(id: "2", name: "Head Office", city: "Kolkata"),
  ];

  // ── New Department (searchable multi-select, scoped to selected Location) ─
  List<DepartmentModel> selectedNewDepartments = [];
  String? _newDepartmentError;

  // ── Reporting To (single-select) ──────────────────────────────────────────
  String selectedReporting = "Select User";
  List<String> selectedReportingList = [];

  void _showReportingToBottomSheet(BuildContext context) {
    // ── Grab real data from your controller ──
    final realEmployees = employeeController.allEmployees
        .where((e) => e.id != widget.userId)
        .toList(); // Exclude self from reporting list

    // Use list of IDs for selection tracking instead of static names
    List<String> tempSelected = List.from(selectedReportingList);

    // Initialize your filter list with the real employees list
    List<dynamic> filtered = List.from(realEmployees);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 10.h),
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEE5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Reporting To",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close,
                              size: 20.r,
                              color: const Color(0xFF6C7278),
                            ),
                          ),
                        ],
                      ),
                      if (tempSelected.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          "${tempSelected.length} selected",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF4338CA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),

                      // Search Input field
                      TextField(
                        autofocus: false,
                        onChanged: (val) => ss(() {
                          filtered = realEmployees
                              .where(
                                (u) =>
                                    u.fullName.toLowerCase().contains(
                                      val.toLowerCase().trim(),
                                    ) ||
                                    (u.fullName).toLowerCase().contains(
                                      val.toLowerCase().trim(),
                                    ),
                              )
                              .toList();
                        }),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF344054),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Search by name or role...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFB8BEC5),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 16.r,
                            color: const Color(0xFF4338CA),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A0258),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                // Dynamic User List
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No users found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (_, i) {
                            final user = filtered[i];
                            final id = user.id;
                            final name = user.fullName;
                            final role = user.jobRole ?? "Employee";
                            final isChecked = tempSelected.contains(id);

                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () => ss(
                                () => isChecked
                                    ? tempSelected.remove(id)
                                    : tempSelected.add(id),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18.r,
                                      backgroundColor: isChecked
                                          ? const Color(0xFF0A0258)
                                          : const Color(0xFFEEF0FF),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : "?",
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isChecked
                                              ? Colors.white
                                              : const Color(0xFF4338CA),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: isChecked
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: const Color(0xFF1D2939),
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            role,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF9AA0AB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 20.w,
                                      height: 20.h,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? const Color(0xFF0A0258)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          5.r,
                                        ),
                                        border: Border.all(
                                          color: isChecked
                                              ? const Color(0xFF0A0258)
                                              : const Color(0xFFD9DEE5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isChecked
                                          ? Icon(
                                              Icons.check,
                                              size: 13.r,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Action buttons
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ss(() => tempSelected.clear()),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD9DEE5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                            ),
                            child: Text(
                              "Clear All",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A0258), Color(0xFF4338CA)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedReportingList = List.from(
                                    tempSelected,
                                  );
                                  if (tempSelected.isNotEmpty) {
                                    _reportingToError = null;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                tempSelected.isEmpty
                                    ? "Confirm"
                                    : "Confirm (${tempSelected.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Department (searchable single-select) ─────────────────────────────────
  String? _departmentError;

  DepartmentModel? selectedDepartment;

  List<String> selectedAssignees = [];

  String selectedPriority = "High";

  // ── Assign Date & Time ─────────────────────────────────────────────────────
  final TextEditingController assignDateController = TextEditingController();
  final TextEditingController assignTimeController = TextEditingController();
  DateTime? assignSelectedDate;
  String assignSelectedAmPm = "AM";

  // ── Due Date & Time ────────────────────────────────────────────────────────
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController dueTimeController = TextEditingController();
  DateTime? dueSelectedDate;
  String dueSelectedAmPm = "AM";

  List<File> selectedFiles = [];
  String? fileError;

  final titleNameController = TextEditingController();
  final descriptionController = TextEditingController();

  // ── Misc controllers (kept for dispose safety) ─────────────────────────────
  TextEditingController dayController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FocusNode dayFocus = FocusNode();
  final FocusNode monthFocus = FocusNode();
  final FocusNode yearFocus = FocusNode();

  late final DepartmentController departmentController;
  late final EmployeeController employeeController;
  late final TaskController taskController;

  // ── INIT ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Assign date/time — blank on start, user must pick
    assignSelectedDate = null;
    assignTimeController.text = "";

    // Due date pre-filled with today; time blank
    final now = DateTime.now();
    dueSelectedDate = now;
    dueDateController.text =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";
    dueTimeController.text = "";

    // Location autocomplete listeners
    locationSearchController.addListener(_onLocationSearchChanged);
    locationFocusNode.addListener(_onLocationFocusChanged);

    // get departments for dropdown

    departmentController = sl<DepartmentController>();
    employeeController = sl<EmployeeController>();
    taskController = sl<TaskController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      departmentController.handleGetDepartments();
      employeeController.handleGetEmployees();
    });
  }

  // ── DISPOSE ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    assignDateController.dispose();
    assignTimeController.dispose();
    dueDateController.dispose();
    dueTimeController.dispose();
    titleNameController.dispose();
    descriptionController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    dayFocus.dispose();
    monthFocus.dispose();
    yearFocus.dispose();

    locationSearchController.removeListener(_onLocationSearchChanged);
    locationSearchController.dispose();
    locationFocusNode.removeListener(_onLocationFocusChanged);
    locationFocusNode.dispose();
    _removeLocationSuggestionsOverlay();

    super.dispose();
  }

  // ── VALIDATION ─────────────────────────────────────────────────────────────
  bool _validateSections() {
    bool valid = true;

    if (selectedLocation == null) {
      setState(() => _locationError = "Please select a location");
      valid = false;
    } else {
      setState(() => _locationError = null);
    }

    if (selectedDepartment == null) {
      setState(() => _departmentError = "Please select department");
      valid = false;
    } else {
      setState(() => _departmentError = null);
    }

    // Reporting To
    if (selectedReportingList.isEmpty) {
      setState(() => _reportingToError = "Please select a user");
      valid = false;
    } else {
      setState(() => _reportingToError = null);
    }

    // Assign To
    if (selectedAssignees.isEmpty) {
      setState(() => _assignToError = "Please select at least one assignee");
      valid = false;
    } else {
      setState(() => _assignToError = null);
    }

    // Cross-field: due date must not be before assign date
    if (dueSelectedDate != null && assignSelectedDate != null) {
      final dueDay = DateTime(
        dueSelectedDate!.year,
        dueSelectedDate!.month,
        dueSelectedDate!.day,
      );
      final assignDay = DateTime(
        assignSelectedDate!.year,
        assignSelectedDate!.month,
        assignSelectedDate!.day,
      );
      if (dueDay.isBefore(assignDay)) {
        setState(() => _dueDateError = "Due date cannot be before assign date");
        valid = false;
      } else {
        setState(() => _dueDateError = null);
      }
    } else {
      setState(() => _dueDateError = null);
    }

    return valid;
  }

  void _submitForm() async {
    setState(() => _autoValidate = true);
    final formValid = _formKey.currentState!.validate();
    final sectionsValid = _validateSections();

    if (!formValid || !sectionsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill all required fields and enable all sections.",
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    if (_validateSections() && _formKey.currentState!.validate()) {
      taskController.clearMessages();

      final String taskType = 'one_time';

      final bool success = await taskController.handleCreateTask(
        bodyFields: {
          "taskType": taskType,
          "title": titleNameController.text.trim(),
          "description": descriptionController.text.trim(),
          "location": selectedLocation?.id,
          "department": selectedDepartment?.id,
          "newDepartments": jsonEncode(
            selectedNewDepartments.map((d) => d.id).toList(),
          ),
          "priority": selectedPriority.toLowerCase(),
          "reportingDate": assignSelectedDate != null
              ? "${assignSelectedDate!.year}-"
                    "${assignSelectedDate!.month.toString().padLeft(2, '0')}-"
                    "${assignSelectedDate!.day.toString().padLeft(2, '0')} "
              : null,
          "reportingTime": {
            "time": assignTimeController.text.trim(),
            "period": assignSelectedAmPm,
          },

          "assignees": jsonEncode(
            selectedAssignees,
          ), // Convert list to string for API; repository should handle conversion back to list

          "reportingTo": jsonEncode(selectedReportingList),
          // "attachments":
          //     selectedFiles, // This would typically be handled as multipart form data in the repository layer
        },

        files:
            selectedFiles, // Pass the list of file paths to the repository for upload handling
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Task created successfully!",
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0DA99E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
        Navigator.pop(
          context,
        ); // Go back to previous screen after successful creation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              taskController.errorMessage ?? "Failed to create task",
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill all required fields and enable all sections.",
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

  // ── LOCATION AUTOCOMPLETE ────────────────────────────────────────────────
  double _measuredLocationFieldWidth() {
    final box =
        _locationFieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.width ?? (MediaQuery.of(context).size.width - 62.w);
  }

  void _onLocationFocusChanged() {
    if (locationFocusNode.hasFocus) {
      _updateLocationSuggestions(locationSearchController.text);
    } else {
      // Small delay so a tap on a suggestion registers before we tear the
      // overlay down (otherwise the overlay disappears first and the tap
      // never lands).
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !locationFocusNode.hasFocus) {
          _removeLocationSuggestionsOverlay();
        }
      });
    }
  }

  void _onLocationSearchChanged() {
    _updateLocationSuggestions(locationSearchController.text);
    if (locationSearchController.text.trim().isEmpty &&
        selectedLocation != null) {
      setState(() {
        selectedLocation = null;
        selectedNewDepartments = [];
      });
    }
  }

  void _updateLocationSuggestions(String query) {
    final q = query.trim().toLowerCase();
    _locationSuggestions = q.isEmpty
        ? List.from(_mockLocations)
        : _mockLocations
              .where(
                (l) =>
                    l.name.toLowerCase().contains(q) ||
                    l.city.toLowerCase().contains(q),
              )
              .toList();

    if (_locationSuggestions.isEmpty || !locationFocusNode.hasFocus) {
      _removeLocationSuggestionsOverlay();
      return;
    }
    _showLocationSuggestionsOverlay();
  }

  void _showLocationSuggestionsOverlay() {
    _removeLocationSuggestionsOverlay();
    final overlay = Overlay.of(context);
    final fieldWidth = _measuredLocationFieldWidth();
    _locationSuggestionsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: fieldWidth,
        child: CompositedTransformFollower(
          link: locationLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 46.h),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240.h),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                shrinkWrap: true,
                itemCount: _locationSuggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                itemBuilder: (context, index) {
                  final loc = _locationSuggestions[index];
                  return InkWell(
                    onTap: () => _selectLocationSuggestion(loc),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1D2939),
                                  ),
                                ),
                                Text(
                                  loc.city,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF667085),
                                  ),
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
    );
    overlay.insert(_locationSuggestionsOverlay!);
  }

  void _removeLocationSuggestionsOverlay() {
    _locationSuggestionsOverlay?.remove();
    _locationSuggestionsOverlay = null;
  }

  void _selectLocationSuggestion(LocationOptionModel location) {
    locationSearchController.removeListener(_onLocationSearchChanged);
    locationSearchController.text = location.name;
    locationSearchController.selection = TextSelection.fromPosition(
      TextPosition(offset: locationSearchController.text.length),
    );
    locationSearchController.addListener(_onLocationSearchChanged);

    setState(() {
      selectedLocation = location;
      _locationError = null;
      // Selecting a new location invalidates whatever "New Department(s)"
      // were already picked, since they're scoped to the location.
      selectedNewDepartments = [];
    });

    _removeLocationSuggestionsOverlay();
    locationFocusNode.unfocus();
  }

  // ── FILE PICKER ────────────────────────────────────────────────────────────
  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'gif',
        'mp4',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      final newFiles = result.files.map((f) => File(f.path!)).toList();
      if ((selectedFiles.length + newFiles.length) > 5) {
        setState(() => fileError = "Maximum 5 files are allowed");
        return;
      }
      setState(() {
        selectedFiles.addAll(newFiles);
        fileError = null;
      });
    }
  }

  // ── DATE PICKER ────────────────────────────────────────────────────────────
  void showCustomDatePicker({
    required BuildContext context,
    required TextEditingController controller,
    required DateTime? initialDate,
    required Function(DateTime) onDateSelected,
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    final today = DateTime.now();
    DateTime tempDate = initialDate ?? today;
    if (minDate != null) {
      final minDay = DateTime(minDate.year, minDate.month, minDate.day);
      final tempDay = DateTime(tempDate.year, tempDate.month, tempDate.day);
      if (tempDay.isBefore(minDay)) tempDate = minDate;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => SafeArea(
          child: Container(
            height: 420,
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10.r,
                  spreadRadius: 1.r,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: SfDateRangePicker(
                    initialSelectedDate: tempDate,
                    minDate: minDate,
                    maxDate: maxDate,
                    selectionMode: DateRangePickerSelectionMode.single,
                    view: DateRangePickerView.month,
                    allowViewNavigation: true,
                    showNavigationArrow: true,
                    backgroundColor: Colors.white,
                    selectionColor: const Color(0xFF0A0258),
                    todayHighlightColor: const Color(0xFF0A0258),
                    startRangeSelectionColor: Colors.white,
                    endRangeSelectionColor: Colors.white,
                    rangeSelectionColor: Colors.white,
                    headerStyle: DateRangePickerHeaderStyle(
                      backgroundColor: Colors.transparent,
                      textStyle: GoogleFonts.inter(
                        color: const Color(0xFF3F4B4B),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onSelectionChanged:
                        (DateRangePickerSelectionChangedArgs a) {
                          if (a.value is DateTime) ss(() => tempDate = a.value);
                        },
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.text =
                            "${tempDate.day.toString().padLeft(2, '0')}-"
                            "${tempDate.month.toString().padLeft(2, '0')}-"
                            "${tempDate.year}";
                        onDateSelected(tempDate);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "OK",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0DA99E),
                          fontSize: 14.sp,
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
    );
  }

  bool _isFormDirty() {
    // 1. Check basic input strings / text fields
    if (titleNameController.text.trim().isNotEmpty) return true;
    if (descriptionController.text.trim().isNotEmpty) return true;
    if (assignTimeController.text.trim().isNotEmpty) return true;
    if (locationSearchController.text.trim().isNotEmpty) return true;

    // 2. Check dropdown selections / object entities
    if (selectedLocation != null) return true;
    if (selectedDepartment != null) return true;
    if (selectedNewDepartments.isNotEmpty) return true;

    // Assuming "Low" or "Medium" is your default selectedPriority fallback,
    // check if it has been altered. If there is no default, check: selectedPriority.isNotEmpty
    if (selectedPriority.toLowerCase() != "low") return true;

    // 3. Check picked date conditions
    if (assignSelectedDate != null) return true;

    // 4. Check collections / array list parameters
    if (selectedAssignees.isNotEmpty) return true;
    if (selectedReportingList.isNotEmpty) return true;
    if (selectedFiles.isNotEmpty) return true;

    // If none of the conditions above matched, the form is pristine (clean)
    return false;
  }

  /// The Confirmation Dialog Box Function
  Future<bool> _showExitConfirmationDialog() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Confirm Action",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to close this form?",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF324054),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false), // Dismiss dialog, stay on page
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
              backgroundColor: const Color(0xFF4338CA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () =>
                Navigator.pop(context, true), // Dismiss dialog, confirm exit
            child: Text(
              "Confirm",
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

    return shouldExit ??
        false; // Fallback to false if tapped outside dialog dismiss boundary
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return; // If it already popped somehow, do nothing

        if (!_isFormDirty()) {
          // We use an internal navigator pop call to close the screen safely
          Navigator.of(context).pop();
          return;
        }

        // 2. If form is dirty, explicitly wait for the modal dialog value
        final bool shouldExit = await _showExitConfirmationDialog();

        if (shouldExit && context.mounted) {
          Navigator.of(context).pop(); // Actually exit the screen layout tree
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          scaffoldKey: _scaffoldKey,
          userId: widget.userId,
          onBackPressed: () => Navigator.pop(context),
        ),
        drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    color: const Color(0xFFF5F7FB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    width: double.infinity,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back + page title
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Icon(
                              Icons.arrow_back,
                              size: 17.r,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            "Core Identity & Media",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ── MAIN CARD ─────────────────────────────────────
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                _buildLabel("Title"),
                                SizedBox(height: 3.h),
                                buildTextField(
                                  hint: "Clean Production Floor",
                                  controller: titleNameController,
                                  suffixIcon: Icon(
                                    CupertinoIcons.pencil,
                                    size: 18.r,
                                    color: Colors.black54,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? "Enter title"
                                      : null,
                                ),

                                SizedBox(height: 8.h),

                                // Location — autocomplete search, same UX as
                                // LocationListScreen's search field.
                                _buildLabel("Location"),
                                SizedBox(height: 3.h),
                                CompositedTransformTarget(
                                  link: locationLayerLink,
                                  child: TextFormField(
                                    key: _locationFieldKey,
                                    controller: locationSearchController,
                                    focusNode: locationFocusNode,
                                    onTap: () => _updateLocationSuggestions(
                                      locationSearchController.text,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? "Select a location"
                                        : null,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6C7278),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: "Search location...",
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: const Color(0xFFB8BEC5),
                                      ),
                                      errorStyle: TextStyle(fontSize: 10.sp),
                                      prefixIcon: Icon(
                                        CupertinoIcons.location_solid,
                                        size: 16.r,
                                        color: const Color(0xFF4338CA),
                                      ),
                                      suffixIcon:
                                          locationSearchController.text.isEmpty
                                          ? null
                                          : GestureDetector(
                                              onTap: () {
                                                locationSearchController
                                                    .clear();
                                                setState(() {
                                                  selectedLocation = null;
                                                  selectedNewDepartments = [];
                                                });
                                                _removeLocationSuggestionsOverlay();
                                              },
                                              child: Icon(
                                                CupertinoIcons
                                                    .clear_circled_solid,
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
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD9DEE5),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD9DEE5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0A0258),
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_locationError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      _locationError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8.h),

                                // New Department — searchable multi-select,
                                // scoped to whichever Location is selected
                                // above. Locked until a Location is chosen.
                                _buildLabel("New Department"),
                                SizedBox(height: 3.h),
                                IgnorePointer(
                                  ignoring: selectedLocation == null,
                                  child: Opacity(
                                    opacity: selectedLocation == null ? 0.5 : 1,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _showNewDepartmentBottomSheet(
                                            context,
                                          ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFC),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: _newDepartmentError != null
                                                ? Colors.red
                                                : const Color(0xFFD9DEE5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  selectedNewDepartments.isEmpty
                                                  ? Text(
                                                      "Select department(s)...",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12.sp,
                                                        color: const Color(
                                                          0xFFB8BEC5,
                                                        ),
                                                      ),
                                                    )
                                                  : Wrap(
                                                      spacing: 6.w,
                                                      runSpacing: 6.h,
                                                      children:
                                                          selectedNewDepartments
                                                              .map((dept) {
                                                                return _newDepartmentChip(
                                                                  dept,
                                                                );
                                                              })
                                                              .toList(),
                                                    ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Icon(
                                              CupertinoIcons.chevron_down,
                                              size: 14.r,
                                              color: const Color(0xFF4338CA),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (selectedLocation == null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      "Select a location first",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF9AA0AB),
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                if (_newDepartmentError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      _newDepartmentError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8.h),

                                // Department — searchable single-select
                                _buildLabel("Department"),
                                SizedBox(height: 3.h),

                                _buildSearchableDropdownField(
                                  // If a department is selected, display its real name, otherwise display your placeholder hint
                                  value:
                                      selectedDepartment?.name ??
                                      "Select Department",
                                  hint: "Select Department",

                                  onTap: () => _showSearchableBottomSheet(
                                    context: context,
                                    title: "Select Department",
                                    selectedValue: selectedDepartment,
                                    onSelected:
                                        (DepartmentModel departmentModel) {
                                          setState(() {
                                            selectedDepartment =
                                                departmentModel;
                                            _departmentError = null;

                                            // print(selectedDepartment);

                                            // employeeController
                                            //     .handleGetEmployees(
                                            //       department:
                                            //           selectedDepartment?.id,
                                            //     );
                                          });
                                        },
                                  ),
                                  errorText: _departmentError,
                                ),

                                if (_departmentError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      _departmentError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                // Remove the code block that displays the error message on screen load
                                SizedBox(height: 8.h),

                                // Priority
                                _buildLabel("Priority"),
                                SizedBox(height: 3.h),
                                _buildDropdown(
                                  value: selectedPriority,
                                  items: ["High", "Medium", "Low"],
                                  onChanged: (v) =>
                                      setState(() => selectedPriority = v!),
                                ),

                                SizedBox(height: 8.h),

                                // Assign To — multi-select
                                _buildLabel("Assign To"),
                                SizedBox(height: 3.h),

                                GestureDetector(
                                  onTap: () {
                                    final activeEmployees = employeeController
                                        .employees
                                        .toList();

                                    _showAssignToBottomSheet(
                                      context,
                                      activeEmployees,
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFC),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: _assignToError != null
                                            ? Colors.red
                                            : const Color(0xFFD9DEE5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: selectedAssignees.isEmpty
                                              ? Text(
                                                  "Select assignees...",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: const Color(
                                                      0xFFB8BEC5,
                                                    ),
                                                  ),
                                                )
                                              : Wrap(
                                                  spacing: 6.w,
                                                  runSpacing: 6.h,
                                                  children: selectedAssignees.map((
                                                    id,
                                                  ) {
                                                    // Match selected IDs back to names for display chips
                                                    final emp = employeeController
                                                        .employees
                                                        .firstWhere(
                                                          (e) => e.id == id,
                                                          orElse: () =>
                                                              EmployeeModel(
                                                                firstName:
                                                                    "Unknown",
                                                              ),
                                                        );
                                                    return _assigneeChip(
                                                      id,
                                                      emp.fullName,
                                                    );
                                                  }).toList(),
                                                ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Icon(
                                          CupertinoIcons.person_add,
                                          size: 16.r,
                                          color: const Color(0xFF4338CA),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_assignToError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      _assignToError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8.h),

                                _buildLabel("Reporting To"),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: () =>
                                      _showReportingToBottomSheet(context),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFC),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: _reportingToError != null
                                            ? Colors.red
                                            : const Color(0xFFD9DEE5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: selectedReportingList.isEmpty
                                              ? Text(
                                                  "Select reporting user...",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: const Color(
                                                      0xFFB8BEC5,
                                                    ),
                                                  ),
                                                )
                                              : Wrap(
                                                  spacing: 6.w,
                                                  runSpacing: 6.h,
                                                  children: selectedReportingList.map((
                                                    id,
                                                  ) {
                                                    // Match selected IDs back to names for display chips
                                                    final emp = employeeController
                                                        .allEmployees
                                                        .firstWhere(
                                                          (e) => e.id == id,
                                                          orElse: () =>
                                                              EmployeeModel(
                                                                firstName:
                                                                    "Unknown",
                                                              ),
                                                        );
                                                    return _reportingChip(
                                                      id,
                                                      emp.fullName,
                                                    );
                                                  }).toList(),
                                                ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Icon(
                                          CupertinoIcons.person_add,
                                          size: 16.r,
                                          color: const Color(0xFF4338CA),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_reportingToError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      _reportingToError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                // Reporting To — searchable single-select
                                SizedBox(height: 8.h),

                                // Reporting Date & Time
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel("Reporting Date"),
                                          SizedBox(height: 4.h),
                                          _buildDateField(
                                            controller: assignDateController,
                                            onTap: () => showCustomDatePicker(
                                              context: context,
                                              controller: assignDateController,
                                              initialDate: assignSelectedDate,
                                              minDate: DateTime.now(),
                                              onDateSelected: (d) => setState(() {
                                                assignSelectedDate = d;
                                                // If due date is now before assign, clear due
                                                if (dueSelectedDate != null) {
                                                  final aDay = DateTime(
                                                    d.year,
                                                    d.month,
                                                    d.day,
                                                  );
                                                  final dDay = DateTime(
                                                    dueSelectedDate!.year,
                                                    dueSelectedDate!.month,
                                                    dueSelectedDate!.day,
                                                  );
                                                  if (dDay.isBefore(aDay)) {
                                                    dueSelectedDate = null;
                                                    dueDateController.clear();
                                                    _dueDateError =
                                                        "Due date cannot be before assign date";
                                                  }
                                                }
                                              }),
                                            ),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                ? "Select Reporting date"
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(width: 6.w),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel("Reporting Time"),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: _buildTimeField(
                                                  controller:
                                                      assignTimeController,
                                                  validator: (v) =>
                                                      (v == null ||
                                                          v.trim().isEmpty)
                                                      ? "Select time"
                                                      : null,
                                                  onTap: () async {
                                                    final t = await _pickTime(
                                                      context,
                                                    );
                                                    if (t != null) {
                                                      setState(() {
                                                        assignTimeController
                                                                .text =
                                                            "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                                                        assignSelectedAmPm =
                                                            t.period ==
                                                                DayPeriod.am
                                                            ? "AM"
                                                            : "PM";
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                              Expanded(
                                                flex: 2,
                                                child: _buildAmPmDropdown(
                                                  value: assignSelectedAmPm,
                                                  onChanged: (v) => setState(
                                                    () =>
                                                        assignSelectedAmPm = v!,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8.h),

                                // Description
                                _buildLabel("Description"),
                                SizedBox(height: 3.h),
                                TextFormField(
                                  controller: descriptionController,
                                  maxLines: 3,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? "Please enter a description"
                                      : null,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6C7278),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: "Write a description....",
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFB8BEC5),
                                    ),
                                    contentPadding: EdgeInsets.all(14.w),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFC),
                                    errorStyle: TextStyle(fontSize: 10.sp),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0A0258),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                // Attachments
                                Text(
                                  "Add Attachments",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: const Color(0xFF3F3F3F),
                                  ),
                                ),
                                Text(
                                  "File must be in pdf, doc, png, jpg, gif or mp4 format\nand upto 5 file(s) at a time.",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF797979),
                                    fontSize: 11.sp,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                GestureDetector(
                                  onTap: pickFiles,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 28,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFF),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: fileError != null
                                            ? Colors.red
                                            : const Color(0xFFB9C3FF),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Drag & drop your file(s) here or",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF797979),
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          "Browse",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF304DDB),
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (fileError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 6.h,
                                      left: 4.w,
                                    ),
                                    child: Text(
                                      fileError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (selectedFiles.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 14.h),
                                    child: Column(
                                      children: List.generate(selectedFiles.length, (
                                        i,
                                      ) {
                                        const progress = 1.0;
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 10.h),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE4E7EC),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .insert_drive_file_outlined,
                                                    size: 18.r,
                                                    color: const Color(
                                                      0xFF667085,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Expanded(
                                                    child: Text(
                                                      selectedFiles[i].path,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color(
                                                          0xFF475467,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  Text(
                                                    "${(progress * 100).toInt()}%",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                        0xFF667085,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                    onTap: () => setState(
                                                      () => selectedFiles
                                                          .removeAt(i),
                                                    ),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        8.r,
                                                      ),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 15.r,
                                                        color: const Color(
                                                          0xFF98A2B3,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 2.5.h,
                                                  backgroundColor: const Color(
                                                    0xFFE4E7EC,
                                                  ),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
                                                        Color(0xFF4F6EF7),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // ── Save Button ────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFD96CFF),
                                      Color(0xFF5CE1E6),
                                    ],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18.w,
                                      vertical: 8.h,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: taskController.isLoading
                                      ? SizedBox(
                                          width: 16.w,
                                          height: 16.w,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                        )
                                      : Text(
                                          "Save Changes",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24.r),
    ),
    child: child,
  );

  // 🌟 1. Pass both the employee ID and name into the helper function
  Widget _assigneeChip(String id, String name) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0FF),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: const Color(0xFF4338CA)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8.r,
          backgroundColor: const Color(0xFF0A0258),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          name.split(" ").first,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: const Color(0xFF0A0258),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => setState(() {
            // 🌟 2. Remove by ID, not by Name!
            selectedAssignees.remove(id);

            // 🌟 3. The error check will now correctly trigger when the list hits 0
            if (selectedAssignees.isEmpty) {
              _assignToError = "Please select at least one assignee";
            }
          }),
          child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
        ),
      ],
    ),
  );

  Future<TimeOfDay?> _pickTime(BuildContext context) async => showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: Color(0xFF0A0258)),
      ),
      child: child!,
    ),
  );

  Widget _buildDateField({
    required TextEditingController controller,
    required VoidCallback onTap,
    String? Function(String?)? validator,
    String? errorText,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6C7278),
            ),
            decoration: InputDecoration(
              hintText: "dd-mm-yyyy",
              hintStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFFB8BEC5),
              ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
              errorStyle: TextStyle(fontSize: 10.sp),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 10.h,
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Icon(
                  CupertinoIcons.calendar,
                  size: 18.r,
                  color: const Color(0xFF4338CA),
                ),
              ),
              suffixIconConstraints: BoxConstraints(minWidth: 30.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF0A0258)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
      if (errorText != null)
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 4.w),
          child: Text(
            errorText,
            style: GoogleFonts.inter(color: Colors.red, fontSize: 10.sp),
          ),
        ),
    ],
  );

  Widget _buildTimeField({
    required TextEditingController controller,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) => GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),
        decoration: InputDecoration(
          hintText: "00:00",
          hintStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            color: const Color(0xFFB8BEC5),
          ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 10.h,
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Icon(
              CupertinoIcons.clock,
              size: 15.r,
              color: const Color(0xFF4338CA),
            ),
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 20.w),
          errorStyle: TextStyle(fontSize: 10.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFF0A0258)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    ),
  );

  Widget _buildAmPmDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 65.w, minWidth: 45.w),
    child: Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.white),
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: 10.r,
          color: const Color(0xFF6C7278),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFF0A0258)),
          ),
        ),
        items: ["AM", "PM"]
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6C7278),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => Theme(
    data: Theme.of(context).copyWith(
      canvasColor: Colors.white,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    ),
    child: ButtonTheme(
      alignedDropdown: true,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        alignment: AlignmentDirectional.centerStart,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: 11.r,
          color: const Color(0xFF6C7278),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
              (e) => DropdownMenuItem(
                value: e,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Text(
                    e,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6C7278),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildLabel(String text) => RichText(
    text: TextSpan(
      text: text,
      style: GoogleFonts.inter(
        color: const Color(0xFF3F3F3F),
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
      children: const [
        TextSpan(
          text: " *",
          style: TextStyle(color: Colors.red),
        ),
      ],
    ),
  );

  Widget buildTextField({
    required String hint,
    Widget? prefix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required TextEditingController controller,
    required String? Function(String?) validator,
    Widget? suffixIcon,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFB8BEC5),
      ),
      errorStyle: TextStyle(fontSize: 10.sp),
      prefixIcon: prefix,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
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
  );

  // ── Searchable single-select field ─────────────────────────────────────────

  Widget _buildSearchableDropdownField({
    required String value,
    required String hint,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final isPlaceholder =
        value == hint ||
        value == "Select User" ||
        value == "Select Users" ||
        value == "Select Department";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: errorText != null ? Colors.red : const Color(0xFFD9DEE5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: isPlaceholder
                      ? const Color(0xFFB8BEC5)
                      : const Color(0xFF6C7278),
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 11.r,
              color: const Color(0xFF6C7278),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchableBottomSheet({
    required BuildContext context,
    required String title,
    required DepartmentModel? selectedValue,
    required Function(DepartmentModel) onSelected,
  }) {
    // Grab the factory instance straight out of your service locator container
    final departmentController = sl<DepartmentController>();
    departmentController.handleGetDepartments(search: "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      builder: (context) {
        // Use ListenableBuilder (built straight into Flutter) to re-render when the controller notifies
        return ListenableBuilder(
          listenable: departmentController,
          builder: (context, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    onChanged: (value) {
                      departmentController.handleGetDepartments(
                        search: value.trim(),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: departmentController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : departmentController.departments.isEmpty
                        ? const Center(child: Text("No departments found"))
                        : ListView.builder(
                            itemCount: departmentController.departments.length,
                            itemBuilder: (context, index) {
                              final department =
                                  departmentController.departments[index];
                              final isSelected =
                                  department.id == selectedValue?.id;

                              return ListTile(
                                title: Text(
                                  department.name ?? "",
                                  style: GoogleFonts.inter(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  onSelected(department);
                                  Navigator.pop(context);

                                  // print(department.name);
                                  employeeController.handleGetEmployees(
                                    department: department.name,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── New Department multi-select bottom sheet ───────────────────────────────

  void _showNewDepartmentBottomSheet(BuildContext context) {
    final departmentController = sl<DepartmentController>();
    departmentController.handleGetDepartments(search: "");

    List<DepartmentModel> tempSelected = List.from(selectedNewDepartments);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 10.h),
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEE5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Select Department(s)",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close,
                              size: 20.r,
                              color: const Color(0xFF6C7278),
                            ),
                          ),
                        ],
                      ),
                      if (tempSelected.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          "${tempSelected.length} selected",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF4338CA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),

                      // Search field — filters via the controller, same as
                      // the single-select Department sheet.
                      TextField(
                        autofocus: false,
                        onChanged: (val) {
                          departmentController.handleGetDepartments(
                            search: val.trim(),
                          );
                        },
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF344054),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Search department...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFB8BEC5),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 16.r,
                            color: const Color(0xFF4338CA),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A0258),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                // Dynamic department list, re-renders on controller notify
                Flexible(
                  child: ListenableBuilder(
                    listenable: departmentController,
                    builder: (context, child) {
                      if (departmentController.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final departments = departmentController.departments;
                      if (departments.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No departments found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: departments.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE4E7EC)),
                        itemBuilder: (_, i) {
                          final dept = departments[i];
                          final isChecked = tempSelected.any(
                            (d) => d.id == dept.id,
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(8.r),
                            onTap: () => ss(() {
                              if (isChecked) {
                                tempSelected.removeWhere(
                                  (d) => d.id == dept.id,
                                );
                              } else {
                                tempSelected.add(dept);
                              }
                            }),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              child: Row(
                                children: [

                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      dept.name ?? "",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: isChecked
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: const Color(0xFF1D2939),
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 20.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? const Color(0xFF0A0258)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5.r),
                                      border: Border.all(
                                        color: isChecked
                                            ? const Color(0xFF0A0258)
                                            : const Color(0xFFD9DEE5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isChecked
                                        ? Icon(
                                            Icons.check,
                                            size: 13.r,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Action buttons
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ss(() => tempSelected.clear()),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD9DEE5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                            ),
                            child: Text(
                              "Clear All",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A0258), Color(0xFF4338CA)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedNewDepartments = List.from(
                                    tempSelected,
                                  );
                                  if (selectedNewDepartments.isNotEmpty) {
                                    _newDepartmentError = null;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                tempSelected.isEmpty
                                    ? "Confirm"
                                    : "Confirm (${tempSelected.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newDepartmentChip(DepartmentModel dept) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0FF),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: const Color(0xFF4338CA)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.square_grid_2x2,
          size: 11.r,
          color: const Color(0xFF4338CA),
        ),
        SizedBox(width: 4.w),
        Text(
          dept.name ?? "",
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: const Color(0xFF0A0258),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => setState(() {
            selectedNewDepartments.removeWhere((d) => d.id == dept.id);
            if (selectedNewDepartments.isEmpty) {
              _newDepartmentError = "Please select at least one department";
            }
          }),
          child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
        ),
      ],
    ),
  );

  // ── Assign To multi-select bottom sheet ────────────────────────────────────

  void _showAssignToBottomSheet(
    BuildContext context,
    List<EmployeeModel> employees,
  ) {
    // Pass your active employee list into the sheet
    List<String> tempSelected = List.from(selectedAssignees); // Tracks IDs
    List<EmployeeModel> filtered = List.from(employees);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 10.h),
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEE5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Assign To",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close,
                              size: 20.r,
                              color: const Color(0xFF6C7278),
                            ),
                          ),
                        ],
                      ),
                      if (tempSelected.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          "${tempSelected.length} selected",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF4338CA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      TextField(
                        autofocus: false,
                        onChanged: (val) => ss(() {
                          final searchStr = val.toLowerCase().trim();
                          filtered = employees.where((emp) {
                            final matchName = emp.fullName
                                .toLowerCase()
                                .contains(searchStr);
                            final matchRole = (emp.jobRole ?? '')
                                .toLowerCase()
                                .contains(searchStr);
                            return matchName || matchRole;
                          }).toList();
                        }),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF344054),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Search by name or role...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFB8BEC5),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 16.r,
                            color: const Color(0xFF4338CA),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9DEE5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A0258),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No users found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (_, i) {
                            final employee = filtered[i];
                            final empId = employee.id ?? '';
                            final name = employee.fullName.isEmpty
                                ? "No Name"
                                : employee.fullName;
                            final role = employee.jobRole?.isEmpty ?? true
                                ? "No Role Assigned"
                                : employee.jobRole!;

                            // Track check marks using unique ID references
                            final isChecked = tempSelected.contains(empId);

                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () => ss(() {
                                if (isChecked) {
                                  tempSelected.remove(empId);
                                } else {
                                  tempSelected.add(empId);
                                }
                              }),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18.r,
                                      backgroundColor: isChecked
                                          ? const Color(0xFF0A0258)
                                          : const Color(0xFFEEF0FF),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isChecked
                                              ? Colors.white
                                              : const Color(0xFF4338CA),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: isChecked
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: const Color(0xFF1D2939),
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            role,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF9AA0AB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 20.w,
                                      height: 20.h,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? const Color(0xFF0A0258)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          5.r,
                                        ),
                                        border: Border.all(
                                          color: isChecked
                                              ? const Color(0xFF0A0258)
                                              : const Color(0xFFD9DEE5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isChecked
                                          ? Icon(
                                              Icons.check,
                                              size: 13.r,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Action buttons
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ss(() => tempSelected.clear()),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD9DEE5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                            ),
                            child: Text(
                              "Clear All",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A0258), Color(0xFF4338CA)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedAssignees = List.from(tempSelected);
                                  if (selectedAssignees.isNotEmpty) {
                                    _assignToError = null;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                tempSelected.isEmpty
                                    ? "Confirm"
                                    : "Confirm (${tempSelected.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportingChip(String id, String name) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0FF),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: const Color(0xFF4338CA)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8.r,
          backgroundColor: const Color(0xFF0A0258),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          name.split(" ").first,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: const Color(0xFF0A0258),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => setState(() {
            selectedReportingList.remove(id);
            if (selectedReportingList.isEmpty) {
              _reportingToError = "Please select at least one reporting user";
            }
          }),
          child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
        ),
      ],
    ),
  );
}
