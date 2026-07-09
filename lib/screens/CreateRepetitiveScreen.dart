// ignore_for_file: curly_braces_in_flow_control_structures

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
import 'package:taskalert_app/core/features/employees/controllers/employee_controller.dart';
import 'package:taskalert_app/core/features/employees/data/models/employee_model.dart';
import 'package:taskalert_app/core/features/location/controllers/location_controller.dart';
import 'package:taskalert_app/core/features/location/data/models/location_model.dart';
import 'package:taskalert_app/core/features/tasks/controllers/task_controller.dart';
import 'package:taskalert_app/utils/injection_container.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

class CreateRepetitiveScreen extends StatefulWidget {
  const CreateRepetitiveScreen({super.key, required this.userId});
  final String userId;

  @override
  State<StatefulWidget> createState() => CreateRepetitiveScreenState();
}

class CreateRepetitiveScreenState extends State<CreateRepetitiveScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  // ── Section error strings ─────────────────────────────────────────────────
  String? _repeatTypeError;
  String? _proofTypeError;
  String? _proofRadioError;
  String? _reportingToError;
  String? _assignToError;
  String? _weekdayError;

  // ── Location (autocomplete search, mirrors LocationListScreen) ────────────
  final TextEditingController locationSearchController =
      TextEditingController();
  final FocusNode locationFocusNode = FocusNode();
  final LayerLink locationLayerLink = LayerLink();
  OverlayEntry? _locationSuggestionsOverlay;
  List<LocationModel> _locationSuggestions = [];
  LocationModel? selectedLocation;
  String? _locationError;
  final GlobalKey _locationFieldKey = GlobalKey();

  // ── New Department (searchable multi-select, scoped to selected Location) ─
  List<DepartmentModel> selectedNewDepartments = [];
  String? _newDepartmentError;

  // ── Cross-field date error ───────────────────────────────────────────────
  String? _dueDateError;

  // ── Toggle-level error messages ───────────────────────────────────────────
  String? _assignmentToggleError;
  String? _proofToggleError;

  // ── Assign To (multi-select) ──────────────────────────────────────────────
  final List<Map<String, String>> _allUsers = [
    {"name": "Alice Johnson", "role": "Manager"},
    {"name": "Bob Smith", "role": "Developer"},
    {"name": "Carol White", "role": "Designer"},
    {"name": "David Brown", "role": "QA Engineer"},
    {"name": "Eva Martinez", "role": "Sales Lead"},
    {"name": "Frank Lee", "role": "HR Executive"},
    {"name": "Grace Kim", "role": "Marketing"},
    {"name": "Henry Wilson", "role": "Operations"},
    {"name": "Irene Taylor", "role": "Finance"},
    {"name": "Jack Davis", "role": "Developer"},
  ];
  List<String> selectedAssignees = [];

  String selectedPriority = "High";

  // ── Reporting To (single-select) ──────────────────────────────────────────
  String selectedReporting = "Select User";
  List<String> selectedReportingList = [];

  // ── Weekly days selection ─────────────────────────────────────────────────
  List<String> selectedWeekdays = [];

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

  // void _showReportingToBottomSheet(BuildContext context) {
  //   final realEmployees = employeeController.employees
  //       .where((e) => e.id != widget.userId)
  //       .toList();

  //   // Use list of IDs for selection tracking instead of static names
  //   List<String> tempSelected = List.from(selectedReportingList);

  //   // Initialize your filter list with the real employees list
  //   List<dynamic> filtered = List.from(realEmployees);

  //   // List<String> tempSelected = selectedReporting == "Select User"
  //   //     ? []
  //   //     : [selectedReporting];

  //   // // final List<Map<String, String>> _reportingUsers = [
  //   // //   {"name": "Manager", "role": "Senior Management"},
  //   // //   {"name": "Team Lead", "role": "Team Leadership"},
  //   // //   {"name": "Director", "role": "Executive"},
  //   // //   {"name": "HR", "role": "Human Resources"},
  //   // // ];

  //   // List<Map<String, String>> filtered = List.from(rea);

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     useRootNavigator: true,
  //     builder: (_) => StatefulBuilder(
  //       builder: (ctx, ss) => Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(ctx).viewInsets.bottom,
  //         ),
  //         child: Container(
  //           constraints: BoxConstraints(
  //             maxHeight: MediaQuery.of(ctx).size.height * 0.75,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.12),
  //                 blurRadius: 10.r,
  //                 offset: const Offset(0, -2),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Handle bar
  //               Container(
  //                 margin: EdgeInsets.only(top: 10.h),
  //                 width: 36.w,
  //                 height: 4.h,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFD9DEE5),
  //                   borderRadius: BorderRadius.circular(4.r),
  //                 ),
  //               ),

  //               Padding(
  //                 padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     // Header
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           "Reporting To",
  //                           style: GoogleFonts.inter(
  //                             fontSize: 14.sp,
  //                             fontWeight: FontWeight.w700,
  //                             color: const Color(0xFF0A0258),
  //                           ),
  //                         ),
  //                         GestureDetector(
  //                           onTap: () => Navigator.pop(ctx),
  //                           child: Icon(
  //                             Icons.close,
  //                             size: 20.r,
  //                             color: const Color(0xFF6C7278),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     if (tempSelected.isNotEmpty) ...[
  //                       SizedBox(height: 4.h),
  //                       Text(
  //                         "${tempSelected.length} selected",
  //                         style: GoogleFonts.inter(
  //                           fontSize: 11.sp,
  //                           color: const Color(0xFF4338CA),
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                     SizedBox(height: 10.h),

  //                     // Search
  //                     TextField(
  //                       autofocus: false,
  //                       onChanged: (val) => ss(() {
  //                         filtered = _reportingUsers
  //                             .where(
  //                               (u) =>
  //                                   u["name"]!.toLowerCase().contains(
  //                                     val.toLowerCase().trim(),
  //                                   ) ||
  //                                   u["role"]!.toLowerCase().contains(
  //                                     val.toLowerCase().trim(),
  //                                   ),
  //                             )
  //                             .toList();
  //                       }),
  //                       style: GoogleFonts.inter(
  //                         fontSize: 12.sp,
  //                         color: const Color(0xFF344054),
  //                       ),
  //                       decoration: InputDecoration(
  //                         isDense: true,
  //                         hintText: "Search by name or role...",
  //                         hintStyle: GoogleFonts.inter(
  //                           fontSize: 12.sp,
  //                           color: const Color(0xFFB8BEC5),
  //                         ),
  //                         prefixIcon: Icon(
  //                           CupertinoIcons.search,
  //                           size: 16.r,
  //                           color: const Color(0xFF4338CA),
  //                         ),
  //                         filled: true,
  //                         fillColor: const Color(0xFFF9FAFC),
  //                         contentPadding: EdgeInsets.symmetric(
  //                           horizontal: 10.w,
  //                           vertical: 10.h,
  //                         ),
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFFD9DEE5),
  //                           ),
  //                         ),
  //                         enabledBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFFD9DEE5),
  //                           ),
  //                         ),
  //                         focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFF0A0258),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(height: 8.h),
  //                   ],
  //                 ),
  //               ),

  //               // User list
  //               Flexible(
  //                 child: filtered.isEmpty
  //                     ? Padding(
  //                         padding: EdgeInsets.symmetric(vertical: 24.h),
  //                         child: Center(
  //                           child: Text(
  //                             "No users found",
  //                             style: GoogleFonts.inter(
  //                               fontSize: 12.sp,
  //                               color: const Color(0xFF9AA0AB),
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     : ListView.separated(
  //                         shrinkWrap: true,
  //                         padding: EdgeInsets.symmetric(horizontal: 16.w),
  //                         itemCount: filtered.length,
  //                         separatorBuilder: (_, __) => const Divider(
  //                           height: 1,
  //                           color: Color(0xFFE4E7EC),
  //                         ),
  //                         itemBuilder: (_, i) {
  //                           final user = filtered[i];
  //                           final name = user["name"]!;
  //                           final role = user["role"]!;
  //                           final isChecked = tempSelected.contains(name);
  //                           return InkWell(
  //                             borderRadius: BorderRadius.circular(8.r),
  //                             onTap: () => ss(
  //                               () => isChecked
  //                                   ? tempSelected.remove(name)
  //                                   : tempSelected.add(name),
  //                             ),
  //                             child: Padding(
  //                               padding: EdgeInsets.symmetric(vertical: 10.h),
  //                               child: Row(
  //                                 children: [
  //                                   CircleAvatar(
  //                                     radius: 18.r,
  //                                     backgroundColor: isChecked
  //                                         ? const Color(0xFF0A0258)
  //                                         : const Color(0xFFEEF0FF),
  //                                     child: Text(
  //                                       name[0].toUpperCase(),
  //                                       style: GoogleFonts.inter(
  //                                         fontSize: 13.sp,
  //                                         fontWeight: FontWeight.w700,
  //                                         color: isChecked
  //                                             ? Colors.white
  //                                             : const Color(0xFF4338CA),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                   SizedBox(width: 10.w),
  //                                   Expanded(
  //                                     child: Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: [
  //                                         Text(
  //                                           name,
  //                                           style: GoogleFonts.inter(
  //                                             fontSize: 13.sp,
  //                                             fontWeight: isChecked
  //                                                 ? FontWeight.w600
  //                                                 : FontWeight.w400,
  //                                             color: const Color(0xFF1D2939),
  //                                           ),
  //                                         ),
  //                                         SizedBox(height: 2.h),
  //                                         Text(
  //                                           role,
  //                                           style: GoogleFonts.inter(
  //                                             fontSize: 11.sp,
  //                                             color: const Color(0xFF9AA0AB),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                   AnimatedContainer(
  //                                     duration: const Duration(
  //                                       milliseconds: 200,
  //                                     ),
  //                                     width: 20.w,
  //                                     height: 20.h,
  //                                     decoration: BoxDecoration(
  //                                       color: isChecked
  //                                           ? const Color(0xFF0A0258)
  //                                           : Colors.transparent,
  //                                       borderRadius: BorderRadius.circular(
  //                                         5.r,
  //                                       ),
  //                                       border: Border.all(
  //                                         color: isChecked
  //                                             ? const Color(0xFF0A0258)
  //                                             : const Color(0xFFD9DEE5),
  //                                         width: 1.5,
  //                                       ),
  //                                     ),
  //                                     child: isChecked
  //                                         ? Icon(
  //                                             Icons.check,
  //                                             size: 13.r,
  //                                             color: Colors.white,
  //                                           )
  //                                         : null,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //               ),

  //               // Action buttons
  //               SafeArea(
  //                 top: false,
  //                 child: Padding(
  //                   padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         child: OutlinedButton(
  //                           onPressed: () => ss(() => tempSelected.clear()),
  //                           style: OutlinedButton.styleFrom(
  //                             side: const BorderSide(color: Color(0xFFD9DEE5)),
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(8.r),
  //                             ),
  //                             padding: EdgeInsets.symmetric(vertical: 10.h),
  //                           ),
  //                           child: Text(
  //                             "Clear All",
  //                             style: GoogleFonts.inter(
  //                               fontSize: 12.sp,
  //                               fontWeight: FontWeight.w500,
  //                               color: const Color(0xFF667085),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(width: 10.w),
  //                       Expanded(
  //                         flex: 2,
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(8.r),
  //                             gradient: const LinearGradient(
  //                               colors: [Color(0xFF0A0258), Color(0xFF4338CA)],
  //                             ),
  //                           ),
  //                           child: ElevatedButton(
  //                             onPressed: () {
  //                               setState(() {
  //                                 selectedReportingList = List.from(
  //                                   tempSelected,
  //                                 );
  //                                 selectedReporting = tempSelected.isEmpty
  //                                     ? "Select User"
  //                                     : tempSelected.join(", ");
  //                                 if (tempSelected.isNotEmpty) {
  //                                   _reportingToError = null;
  //                                 }
  //                               });
  //                               Navigator.pop(ctx);
  //                             },
  //                             style: ElevatedButton.styleFrom(
  //                               elevation: 0,
  //                               backgroundColor: Colors.transparent,
  //                               shadowColor: Colors.transparent,
  //                               padding: EdgeInsets.symmetric(vertical: 10.h),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(8.r),
  //                               ),
  //                             ),
  //                             child: Text(
  //                               tempSelected.isEmpty
  //                                   ? "Confirm"
  //                                   : "Confirm (${tempSelected.length})",
  //                               style: GoogleFonts.inter(
  //                                 fontSize: 12.sp,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Colors.white,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  bool isAssignmentEnabled = false;
  bool isProofEnabled = false;

  final TextEditingController assignDateController = TextEditingController();
  final TextEditingController assignTimeController = TextEditingController();
  DateTime? assignSelectedDate;
  String assignSelectedAmPm = "AM";

  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController dueTimeController = TextEditingController();
  DateTime? dueSelectedDate;
  String dueSelectedAmPm = "AM";

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  DateTime? startSelectedDate;
  DateTime? endSelectedDate;

  TextEditingController dayController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FocusNode dayFocus = FocusNode();
  final FocusNode monthFocus = FocusNode();
  final FocusNode yearFocus = FocusNode();

  List<File> selectedFiles = [];
  String? fileError;

  final titleNameController = TextEditingController();
  String selectedRepeatType = "Daily";
  String selectedEndType = "end_by";
  // String selectedProofTypes = "";

  List<String> selectedProofTypes = [];
  String selectedProofRadioType = "";

  int occurrencesCount = 1;
  int timePeriodCount = 1;

  late final EmployeeController employeeController;
  late final TaskController taskController;
  late final LocationController locationController;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    assignSelectedDate = null;
    assignTimeController.text = "";
    dueSelectedDate = now;
    dueDateController.text =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";
    dueTimeController.text = "";

    // Location autocomplete listeners
    locationSearchController.addListener(_onLocationSearchChanged);
    locationFocusNode.addListener(_onLocationFocusChanged);

    employeeController = sl<EmployeeController>();
    taskController = sl<TaskController>();
    locationController = sl<LocationController>();
    locationController.addListener(_onLocationsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      employeeController.handleGetEmployees();
      locationController.handleGetLocations();
    });
  }

  @override
  void dispose() {
    assignDateController.dispose();
    assignTimeController.dispose();
    dueDateController.dispose();
    dueTimeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    titleNameController.dispose();
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
    locationController.removeListener(_onLocationsChanged);
    _removeLocationSuggestionsOverlay();

    super.dispose();
  }

  // ── VALIDATION ─────────────────────────────────────────────────────────────

  bool _validateSections() {
    bool valid = true;

    if (selectedRepeatType == "Weekly" && selectedWeekdays.isEmpty) {
      setState(() => _weekdayError = "Please select at least one day");
      valid = false;
    } else {
      setState(() => _weekdayError = null);
    }

    if (selectedNewDepartments.isEmpty) {
      setState(
        () => _newDepartmentError = "Please select at least one department",
      );
      valid = false;
    } else {
      setState(() => _newDepartmentError = null);
    }

    if (selectedReportingList.isEmpty) {
      //print('selectedReportingList: $selectedReportingList');
      setState(() => _reportingToError = "Please select a user");
      valid = false;
    } else {
      setState(() => _reportingToError = null);
    }

    if (selectedAssignees.isEmpty) {
      setState(() => _assignToError = "Please select at least one assignee");
      valid = false;
    } else {
      setState(() => _assignToError = null);
    }

    if (!isAssignmentEnabled) {
      setState(
        () => _assignmentToggleError =
            "Please enable Assignment & Recurrence and fill all fields",
      );
      valid = false;
    } else {
      setState(() => _assignmentToggleError = null);
    }

    // if (!isProofEnabled) {
    //   setState(
    //     () => _proofToggleError =
    //         "Please enable Proof & AI Validation and fill all fields",
    //   );
    //   valid = false;
    // } else {
    //   setState(() => _proofToggleError = null);
    // }

    if (isProofEnabled) {
      if (selectedProofTypes.isEmpty) {
        setState(
          () => _proofTypeError = "Please select at least one proof type",
        );
        valid = false;
      } else {
        setState(() => _proofTypeError = null);
      }
    } else {
      setState(() => _proofTypeError = null);
    }

    if (isAssignmentEnabled) {
      // if (selectedReporting == "Select User") {
      //   setState(() => _reportingToError = "Please select a user");
      //   valid = false;
      // } else {
      //   setState(() => _reportingToError = null);
      // }
      if (selectedRepeatType.isEmpty) {
        setState(() => _repeatTypeError = "Please select a time period");
        valid = false;
      } else {
        setState(() => _repeatTypeError = null);
      }
    }

    if (isAssignmentEnabled &&
        dueSelectedDate != null &&
        startSelectedDate != null) {
      final dueDay = DateTime(
        dueSelectedDate!.year,
        dueSelectedDate!.month,
        dueSelectedDate!.day,
      );
      final startDay = DateTime(
        startSelectedDate!.year,
        startSelectedDate!.month,
        startSelectedDate!.day,
      );
      if (dueDay.isBefore(startDay)) {
        setState(() => _dueDateError = "Due date cannot be before start date");
        valid = false;
      } else {
        setState(() => _dueDateError = null);
      }
    } else {
      setState(() => _dueDateError = null);
    }

    if (isProofEnabled) {
      // //print("Before Validation -> $selectedProofTypes");
      if (selectedProofTypes.isEmpty) {
        setState(() {
          _proofTypeError = "Please select at least one proof type";
        });
        valid = false;
      } else {
        setState(() {
          _proofTypeError = null;
        });
        //print("Proof Types Count: ${selectedProofTypes.length}");
        //print("Proof Types Values: $selectedProofTypes");
      }

      // AI Validation is optional
      // No validation required for selectedProofRadioType
    }

    // if (isProofEnabled) {
    //   if (selectedProofTypes.isEmpty) {
    //     setState(() => _proofTypeError = "Please select a proof type");
    //     valid = false;
    //   } else {
    //     setState(() => _proofTypeError = null);
    //   }
    //   if (selectedProofTypes.isNotEmpty && selectedProofRadioType.isEmpty) {
    //     setState(
    //       () => _proofRadioError = "Please select Yes or No for AI Validation",
    //     );
    //     valid = false;
    //   } else {
    //     setState(() => _proofRadioError = null);
    //   }
    // }

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

    if (selectedEndType == "end_by") {
      //print("End Date: ${endDateController.text}");
    } else {
      //print("Occurrences: $occurrencesCount");
    }

    //print("Ai enabled: $isProofEnabled");
    //print("Proof Type: $selectedProofTypes");
    if (selectedProofTypes.isNotEmpty) {
      //print("AI Validation: $selectedProofRadioType");
    }
    //print("Selected Files: $selectedFiles");

    if (_validateSections() && _formKey.currentState!.validate()) {
      taskController.clearMessages();

      final String taskType = 'repetitive';

      final Map<String, dynamic> formData = {
        "taskType": taskType,
        "title": titleNameController.text.trim(),
        "location": selectedLocation?.id,
        "department": selectedNewDepartments
            .map((d) => d.id)
            .whereType<String>()
            .toList(),
        "priority": selectedPriority.toLowerCase(),
        "assignees": jsonEncode(selectedAssignees),
        "reportingTo": jsonEncode(selectedReportingList),
        "reportingTime": {
          "time": dueTimeController.text.trim(),
          "period": dueSelectedAmPm,
        },
        "description": descriptionController.text.trim(),

        "timePeriod": selectedRepeatType.toLowerCase(),
        "everyN": timePeriodCount,
        "rangeStart": DateTime(
          int.parse(startDateController.text.split('-')[2]),
          int.parse(startDateController.text.split('-')[1]),
          int.parse(startDateController.text.split('-')[0]),
        ).toString().split(' ')[0],

        "endType": selectedEndType,
      };

      if (selectedRepeatType.toLowerCase() == 'weekly') {
        // formData['daysOfWeek'] = jsonEncode(selectedWeekdays);

        // insert into formdata
        formData['daysOfWeek'] = jsonEncode(
          selectedWeekdays.map((day) => day.toLowerCase()).toList(),
        );
      }

      if (selectedEndType == 'end_by') {
        //print('end by active');
        // formData['endByDate'] = endDateController.text;
        formData['endByDate'] = DateTime(
          int.parse(endDateController.text.split('-')[2]),
          int.parse(endDateController.text.split('-')[1]),
          int.parse(endDateController.text.split('-')[0]),
        ).toString().split(' ')[0];
      } else if (selectedEndType == 'end_after') {
        formData['endAfterCount'] = occurrencesCount;
      }

      //print('Form Data');
      //print(formData);

      if (isProofEnabled) {
        formData['proofTypes'] = selectedProofTypes;
        formData["aiValidationEnabled"] = selectedProofRadioType == "Yes"
            ? true
            : false;
      }

      final bool success = await taskController.handleCreateTask(
        bodyFields: formData,

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

    // //print("Selected AI Proof Type: $")

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       "Form submitted successfully!",
    //       style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
    //     ),
    //     backgroundColor: Colors.green,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    //   ),
    // );
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

  void _onLocationsChanged() {
    if (!mounted) return;
    _updateLocationSuggestions(locationSearchController.text);
  }

  void _updateLocationSuggestions(String query) {
    final q = query.trim().toLowerCase();
    final allLocations = locationController.locations;
    _locationSuggestions = q.isEmpty
        ? List.from(allLocations)
        : allLocations
              .where(
                (l) =>
                    l.name.toLowerCase().contains(q) ||
                    (l.address?.city.toLowerCase().contains(q) ?? false),
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
                                  loc.address?.city ?? '',
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

  void _selectLocationSuggestion(LocationModel location) {
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

  String get repeatLabel {
    switch (selectedRepeatType) {
      case "Daily":
        return "day(s) on";
      case "Weekly":
        return "week(s) on";
      case "Monthly":
        return "month(s) on";
      case "Yearly":
        return "year(s) on";
      default:
        return "day(s) on";
    }
  }

  // TextEditingController? get descriptionController => null;
  final descriptionController = TextEditingController();

  bool _isFormDirty() {
    // 1. Core Text Controllers
    if (titleNameController.text.trim().isNotEmpty) return true;
    if (descriptionController.text.trim().isNotEmpty) return true;
    if (dueTimeController.text.trim().isNotEmpty) return true;
    if (startDateController.text.trim().isNotEmpty) return true;

    // 2. Base Dropdown Entity Selection Objects
    if (selectedNewDepartments.isNotEmpty) return true;

    // Assuming "low" is your baseline priority default fallback
    if (selectedPriority.toLowerCase() != "low") return true;

    // 3. Simple Primitive Collections Array Lists
    if (selectedAssignees.isNotEmpty) return true;
    if (selectedReportingList.isNotEmpty) return true;
    if (selectedFiles.isNotEmpty) return true;

    // 4. Conditional Repeat Type Blocks (e.g., Weekly configurations)
    // Assuming "once" or "daily" might be your standard un-altered baseline default
    if (selectedRepeatType.toLowerCase() != "daily") return true;
    if (selectedRepeatType.toLowerCase() == 'weekly' &&
        selectedWeekdays.isNotEmpty) {
      return true;
    }

    // If timePeriodCount (everyN) has been incremented or changed from a baseline default of 1
    if (timePeriodCount > 1) return true;

    // 5. Conditional End Execution Type Form Blocks
    // Assuming "never" or similar string key is your baseline default selectedEndType state
    if (selectedEndType != "never") {
      if (selectedEndType == 'end_by' &&
          endDateController.text.trim().isNotEmpty) {
        return true;
      }
      if (selectedEndType == 'end_after' && occurrencesCount > 0) {
        return true;
      }
    }

    // 6. Conditional Submission Proof Verification Flags
    if (isProofEnabled) {
      if (selectedProofTypes.isNotEmpty) return true;
      // Assuming "No" is your default baseline setting for AI analysis validation
      if (selectedProofRadioType != "No") return true;
    }

    // If no check evaluated to true, the form matches baseline expectations perfectly
    return false;
  }

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

                          // ── MAIN CARD ───────────────────────────────────────
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

                                // Location — autocomplete search
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

                                // New Department — searchable multi-select, scoped to Location
                                _buildLabel("Department"),
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
                                                              .map(
                                                                (dept) =>
                                                                    _newDepartmentChip(
                                                                      dept,
                                                                    ),
                                                              )
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

                                // Assign Date & Time
                                // Row(
                                //   children: [
                                //     Expanded(
                                //       child: Column(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.start,
                                //         children: [
                                //           _buildLabel("Assign Date"),
                                //           SizedBox(height: 4.h),
                                //           _buildDateField(
                                //             controller: assignDateController,
                                //             onTap: () => showCustomDatePicker(
                                //               context: context,
                                //               controller: assignDateController,
                                //               initialDate: assignSelectedDate,
                                //               minDate: DateTime.now(),
                                //               onDateSelected: (d) => setState(
                                //                 () => assignSelectedDate = d,
                                //               ),
                                //             ),
                                //             validator: (v) {
                                //               if (v == null || v.trim().isEmpty)
                                //                 return "Select assign date";
                                //               return null;
                                //             },
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //     SizedBox(width: 6.w),
                                //     Expanded(
                                //       child: Column(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.start,
                                //         children: [
                                //           _buildLabel("Assign Time"),
                                //           SizedBox(height: 4.h),
                                //           Row(
                                //             children: [
                                //               Expanded(
                                //                 flex: 3,
                                //                 child: _buildTimeField(
                                //                   controller:
                                //                       assignTimeController,
                                //                   validator: (v) {
                                //                     if (v == null ||
                                //                         v.trim().isEmpty)
                                //                       return "Select time";
                                //                     return null;
                                //                   },
                                //                   onTap: () async {
                                //                     final t = await _pickTime(
                                //                       context,
                                //                     );
                                //                     if (t != null) {
                                //                       setState(() {
                                //                         assignTimeController
                                //                                 .text =
                                //                             "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                                //                         assignSelectedAmPm =
                                //                             t.period ==
                                //                                 DayPeriod.am
                                //                             ? "AM"
                                //                             : "PM";
                                //                       });
                                //                     }
                                //                   },
                                //                 ),
                                //               ),
                                //               SizedBox(width: 6.w),
                                //               Expanded(
                                //                 flex: 2,
                                //                 child: _buildAmPmDropdown(
                                //                   value: assignSelectedAmPm,
                                //                   onChanged: (v) => setState(
                                //                     () => assignSelectedAmPm = v!,
                                //                   ),
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                //
                                // SizedBox(height: 8.h),

                                // Assign To (multi-select)
                                _buildLabel("Assign To"),
                                SizedBox(height: 3.h),

                                GestureDetector(
                                  onTap: () {
                                    _showAssignToBottomSheet(
                                      context,
                                      _employeesForSelectedDepartments(),
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
                                                        .allEmployees
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

                                // GestureDetector(
                                //   onTap: () => _showAssignToBottomSheet(context),
                                //   child: Container(
                                //     width: double.infinity,
                                //     padding: EdgeInsets.symmetric(
                                //       horizontal: 10.w,
                                //       vertical: 10.h,
                                //     ),
                                //     decoration: BoxDecoration(
                                //       color: const Color(0xFFF9FAFC),
                                //       borderRadius: BorderRadius.circular(8.r),
                                //       border: Border.all(
                                //         color: _assignToError != null
                                //             ? Colors.red
                                //             : const Color(0xFFD9DEE5),
                                //       ),
                                //     ),
                                //     child: Row(
                                //       children: [
                                //         Expanded(
                                //           child: selectedAssignees.isEmpty
                                //               ? Text(
                                //                   "Select assignees...",
                                //                   style: GoogleFonts.inter(
                                //                     fontSize: 12.sp,
                                //                     color: const Color(
                                //                       0xFFB8BEC5,
                                //                     ),
                                //                   ),
                                //                 )
                                //               : Wrap(
                                //                   spacing: 6.w,
                                //                   runSpacing: 6.h,
                                //                   children: selectedAssignees
                                //                       .map(_assigneeChip)
                                //                       .toList(),
                                //                 ),
                                //         ),
                                //         SizedBox(width: 6.w),
                                //         Icon(
                                //           CupertinoIcons.person_add,
                                //           size: 16.r,
                                //           color: const Color(0xFF4338CA),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                // if (_assignToError != null)
                                //   Padding(
                                //     padding: EdgeInsets.only(top: 4.h, left: 4.w),
                                //     child: Text(
                                //       _assignToError!,
                                //       style: GoogleFonts.inter(
                                //         color: Colors.red,
                                //         fontSize: 10.sp,
                                //       ),
                                //     ),
                                //   ),
                                SizedBox(height: 8.h),

                                // Reporting To
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

                                // GestureDetector(
                                //   onTap: () =>
                                //       _showReportingToBottomSheet(context),
                                //   child: Container(
                                //     width: double.infinity,
                                //     padding: EdgeInsets.symmetric(
                                //       horizontal: 10.w,
                                //       vertical: 10.h,
                                //     ),
                                //     decoration: BoxDecoration(
                                //       color: const Color(0xFFF9FAFC),
                                //       borderRadius: BorderRadius.circular(8.r),
                                //       border: Border.all(
                                //         color: _reportingToError != null
                                //             ? Colors.red
                                //             : const Color(0xFFD9DEE5),
                                //       ),
                                //     ),
                                //     child: Row(
                                //       children: [
                                //         Expanded(
                                //           child: selectedReportingList.isEmpty
                                //               ? Text(
                                //                   "Select reporting user...",
                                //                   style: GoogleFonts.inter(
                                //                     fontSize: 12.sp,
                                //                     color: const Color(
                                //                       0xFFB8BEC5,
                                //                     ),
                                //                   ),
                                //                 )
                                //               : Wrap(
                                //                   spacing: 6.w,
                                //                   runSpacing: 6.h,
                                //                   children: selectedReportingList
                                //                       .map(_reportingChip)
                                //                       .toList(),
                                //                 ),
                                //         ),
                                //         SizedBox(width: 6.w),
                                //         Icon(
                                //           CupertinoIcons.person_add,
                                //           size: 16.r,
                                //           color: const Color(0xFF4338CA),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                // if (_reportingToError != null)
                                //   Padding(
                                //     padding: EdgeInsets.only(top: 4.h, left: 4.w),
                                //     child: Text(
                                //       _reportingToError!,
                                //       style: GoogleFonts.inter(
                                //         color: Colors.red,
                                //         fontSize: 10.sp,
                                //       ),
                                //     ),
                                //   ),
                                SizedBox(height: 8.h),

                                Row(
                                  children: [
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
                                                flex: 1,
                                                child: _buildTimeField(
                                                  controller: dueTimeController,
                                                  validator: (v) {
                                                    // Always required — not gated by isAssignmentEnabled
                                                    if (v == null ||
                                                        v.trim().isEmpty)
                                                      return "Select time";
                                                    return null;
                                                  },
                                                  onTap: () async {
                                                    final t = await _pickTime(
                                                      context,
                                                    );
                                                    if (t != null) {
                                                      setState(() {
                                                        dueTimeController.text =
                                                            "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                                                        dueSelectedAmPm =
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
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: 70.w,
                                                  maxWidth: 90.w,
                                                ),
                                                child: _buildAmPmDropdown(
                                                  value: dueSelectedAmPm,
                                                  onChanged: (v) => setState(
                                                    () => dueSelectedAmPm = v!,
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

                                // // Reporting Time
                                // Row(
                                //   children: [
                                //     SizedBox(width: 6.w),
                                //     Expanded(
                                //       child: Column(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.start,
                                //         children: [
                                //           _buildLabel("Reporting Time"),
                                //           SizedBox(height: 4.h),
                                //           Row(
                                //             children: [
                                //               Expanded(
                                //                 flex: 1,
                                //                 child: _buildTimeField(
                                //                   controller: dueTimeController,
                                //                   validator: (v) {
                                //                     if (!isAssignmentEnabled) {
                                //                       return null;
                                //                     }
                                //                     if (v == null ||
                                //                         v.trim().isEmpty) {
                                //                       return "Select time";
                                //                     }
                                //                     return null;
                                //                   },
                                //                   onTap: () async {
                                //                     final t = await _pickTime(
                                //                       context,
                                //                     );
                                //                     if (t != null) {
                                //                       setState(() {
                                //                         dueTimeController.text =
                                //                             "${t.hourOfPeriod.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                                //                         dueSelectedAmPm =
                                //                             t.period ==
                                //                                 DayPeriod.am
                                //                             ? "AM"
                                //                             : "PM";
                                //                       });
                                //                     }
                                //                   },
                                //                 ),
                                //               ),
                                //               SizedBox(width: 6.w),
                                //               ConstrainedBox(
                                //                 constraints: BoxConstraints(
                                //                   minWidth: 70.w,
                                //                   maxWidth: 90.w,
                                //                 ),
                                //                 child: _buildAmPmDropdown(
                                //                   value: dueSelectedAmPm,
                                //                   onChanged: (v) => setState(
                                //                     () => dueSelectedAmPm = v!,
                                //                   ),
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //   ],
                                // ),
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

                          // ── TOGGLE SECTIONS ──────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                // ── Assignment & Recurrence ─────────────────────
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Assignment & Recurrence",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0A0258),
                                      ),
                                    ),
                                    _buildToggle(
                                      value: isAssignmentEnabled,
                                      onTap: () => setState(() {
                                        isAssignmentEnabled =
                                            !isAssignmentEnabled;
                                        if (isAssignmentEnabled) {
                                          _assignmentToggleError = null;
                                        } else {
                                          _reportingToError = null;
                                          _repeatTypeError = null;
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                                if (_assignmentToggleError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 2.w,
                                    ),
                                    child: Text(
                                      _assignmentToggleError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8.h),

                                if (isAssignmentEnabled)
                                  _card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Select Time Period
                                        _buildLabel("Select Time Period"),
                                        SizedBox(height: 10.h),
                                        Wrap(
                                          spacing: 14.w,
                                          runSpacing: 10.h,
                                          children: [
                                            _buildRepeatOption(
                                              "Daily",
                                              "Daily",
                                            ),
                                            _buildRepeatOption(
                                              "Weekly",
                                              "Weekly",
                                            ),
                                            // _buildRepeatOption(
                                            //   "Monthly",
                                            //   "Monthly",
                                            // ),
                                            // _buildRepeatOption(
                                            //   "Yearly",
                                            //   "Yearly",
                                            // ),
                                          ],
                                        ),
                                        if (_repeatTypeError != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: 4.h,
                                              left: 2.w,
                                            ),
                                            child: Text(
                                              _repeatTypeError!,
                                              style: GoogleFonts.inter(
                                                color: Colors.red,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                          ),

                                        SizedBox(height: 8.h),

                                        // ── Repeat Every ──────────────────────
                                        _buildLabel("Repeat Every"),
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.35,
                                              height: 36.h,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFD9DEE5,
                                                  ),
                                                ),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      timePeriodCount
                                                          .toString(),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color(
                                                          0xFF344054,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () => setState(
                                                          () =>
                                                              timePeriodCount++,
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .keyboard_arrow_up,
                                                          size: 18.r,
                                                          color: const Color(
                                                            0xFF4338CA,
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () => setState(
                                                          () {
                                                            if (timePeriodCount >
                                                                1) {
                                                              timePeriodCount--;
                                                            }
                                                          },
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .keyboard_arrow_down,
                                                          size: 18.r,
                                                          color: const Color(
                                                            0xFF4338CA,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              repeatLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                color: const Color(0xFF667085),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ── Weekly Days Checkboxes ─────────────
                                        // Shown only when "Weekly" is selected
                                        if (selectedRepeatType == "Weekly") ...[
                                          SizedBox(height: 12.h),
                                          _buildLabel("Select Days"),
                                          SizedBox(height: 8.h),
                                          _buildWeekdayCheckboxes(),
                                          if (_weekdayError != null)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 4.h,
                                                left: 2.w,
                                              ),
                                              child: Text(
                                                _weekdayError!,
                                                style: GoogleFonts.inter(
                                                  color: Colors.red,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ),
                                        ],

                                        SizedBox(height: 8.h),

                                        // Range of Time
                                        Text(
                                          'Range of Time',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0A0258),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),

                                        Row(
                                          children: [
                                            // Start Date
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Start :",
                                                    style: GoogleFonts.inter(
                                                      color: const Color(
                                                        0xFF3F3F3F,
                                                      ),
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 3.h),
                                                  _buildDateField(
                                                    controller:
                                                        startDateController,
                                                    onTap: () => showCustomDatePicker(
                                                      context: context,
                                                      controller:
                                                          startDateController,
                                                      initialDate:
                                                          startSelectedDate,
                                                      minDate: DateTime.now(),
                                                      onDateSelected: (d) => setState(() {
                                                        startSelectedDate = d;
                                                        if (endSelectedDate !=
                                                            null) {
                                                          final startDay =
                                                              DateTime(
                                                                d.year,
                                                                d.month,
                                                                d.day,
                                                              );
                                                          final endDay =
                                                              DateTime(
                                                                endSelectedDate!
                                                                    .year,
                                                                endSelectedDate!
                                                                    .month,
                                                                endSelectedDate!
                                                                    .day,
                                                              );
                                                          if (endDay.isBefore(
                                                            startDay,
                                                          )) {
                                                            endSelectedDate =
                                                                null;
                                                            endDateController
                                                                .clear();
                                                          }
                                                        }
                                                        if (dueSelectedDate !=
                                                            null) {
                                                          final startDay =
                                                              DateTime(
                                                                d.year,
                                                                d.month,
                                                                d.day,
                                                              );
                                                          final dueDay =
                                                              DateTime(
                                                                dueSelectedDate!
                                                                    .year,
                                                                dueSelectedDate!
                                                                    .month,
                                                                dueSelectedDate!
                                                                    .day,
                                                              );
                                                          if (dueDay.isBefore(
                                                            startDay,
                                                          )) {
                                                            dueSelectedDate =
                                                                null;
                                                            dueDateController
                                                                .clear();
                                                            _dueDateError =
                                                                "Due date cannot be before start date";
                                                          }
                                                        }
                                                      }),
                                                    ),
                                                    validator: (v) {
                                                      if (!isAssignmentEnabled) {
                                                        return null;
                                                      }
                                                      if (v == null ||
                                                          v.trim().isEmpty) {
                                                        return "Select start date";
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 10.w),

                                            // End Date / Occurrences
                                            if (selectedEndType != "no_end")
                                              Expanded(
                                                child:
                                                    selectedEndType ==
                                                        "end_after"
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "Occurrences :",
                                                            style: GoogleFonts.inter(
                                                              color:
                                                                  const Color(
                                                                    0xFF3F3F3F,
                                                                  ),
                                                              fontSize: 13.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          SizedBox(height: 3.h),
                                                          Container(
                                                            height: 36.h,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFF9FAFC,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10.r,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFFD9DEE5,
                                                                    ),
                                                              ),
                                                            ),
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10.w,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    occurrencesCount
                                                                        .toString(),
                                                                    style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          13.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: const Color(
                                                                        0xFF344054,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    GestureDetector(
                                                                      onTap: () =>
                                                                          setState(
                                                                            () =>
                                                                                occurrencesCount++,
                                                                          ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .keyboard_arrow_up,
                                                                        size: 18
                                                                            .r,
                                                                        color: const Color(
                                                                          0xFF4338CA,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    GestureDetector(
                                                                      onTap: () => setState(() {
                                                                        if (occurrencesCount >
                                                                            1) {
                                                                          occurrencesCount--;
                                                                        }
                                                                      }),
                                                                      child: Icon(
                                                                        Icons
                                                                            .keyboard_arrow_down,
                                                                        size: 18
                                                                            .r,
                                                                        color: const Color(
                                                                          0xFF4338CA,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "End :",
                                                            style: GoogleFonts.inter(
                                                              color:
                                                                  const Color(
                                                                    0xFF3F3F3F,
                                                                  ),
                                                              fontSize: 13.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          SizedBox(height: 3.h),
                                                          _buildDateField(
                                                            controller:
                                                                endDateController,
                                                            onTap: () => showCustomDatePicker(
                                                              context: context,
                                                              controller:
                                                                  endDateController,
                                                              initialDate:
                                                                  endSelectedDate,
                                                              minDate:
                                                                  startSelectedDate !=
                                                                      null
                                                                  ? DateTime(
                                                                      startSelectedDate!
                                                                          .year,
                                                                      startSelectedDate!
                                                                          .month,
                                                                      startSelectedDate!
                                                                          .day,
                                                                    )
                                                                  : DateTime.now(),
                                                              onDateSelected:
                                                                  (
                                                                    d,
                                                                  ) => setState(
                                                                    () =>
                                                                        endSelectedDate =
                                                                            d,
                                                                  ),
                                                            ),
                                                            validator: (v) {
                                                              if (!isAssignmentEnabled) {
                                                                return null;
                                                              }
                                                              if (selectedEndType ==
                                                                      "end_by" &&
                                                                  (v == null ||
                                                                      v
                                                                          .trim()
                                                                          .isEmpty)) {
                                                                return "Select end date";
                                                              }
                                                              return null;
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                          ],
                                        ),

                                        SizedBox(height: 8.h),

                                        // End Repeat Options
                                        Wrap(
                                          spacing: 14.w,
                                          runSpacing: 10.h,
                                          children: [
                                            _buildEndRepeatOption(
                                              "End by :",
                                              "end_by",
                                            ),
                                            _buildEndRepeatOption(
                                              "End after:",
                                              "end_after",
                                            ),
                                            _buildEndRepeatOption(
                                              "No end date",
                                              "no_end",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                SizedBox(height: 10.h),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE4E7EC),
                                ),
                                SizedBox(height: 10.h),

                                // ── Proof & AI Validation ─────────────────────
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'The "Proof" & AI Validation',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0A0258),
                                      ),
                                    ),
                                    _buildToggle(
                                      value: isProofEnabled,
                                      onTap: () => setState(() {
                                        isProofEnabled = !isProofEnabled;
                                        if (!isProofEnabled) {
                                          _proofTypeError = null;
                                          selectedProofTypes.clear();
                                          selectedProofRadioType = "";
                                        }
                                      }),
                                    ),
                                    // _buildToggle(
                                    //   value: isProofEnabled,
                                    //   onTap: () => setState(() {
                                    //     isProofEnabled = !isProofEnabled;
                                    //     if (isProofEnabled) {
                                    //       _proofToggleError = null;
                                    //     } else {
                                    //       _proofTypeError = null;
                                    //       _proofRadioError = null;
                                    //     }
                                    //   }),
                                    // ),
                                  ],
                                ),
                                if (_proofToggleError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4.h,
                                      left: 2.w,
                                    ),
                                    child: Text(
                                      _proofToggleError!,
                                      style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8.h),

                                if (isProofEnabled)
                                  _card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Proof Type"),
                                        SizedBox(height: 8.h),
                                        Wrap(
                                          spacing: 14.w,
                                          runSpacing: 10.h,
                                          children: [
                                            _buildProofOption("Image", "image"),
                                            _buildProofOption("Video", "video"),
                                            _buildProofOption(
                                              "Recording",
                                              "recording",
                                            ),
                                            _buildProofOption("Pdf", "pdf"),
                                            _buildProofOption("Doc", "doc"),
                                          ],
                                        ),
                                        if (_proofTypeError != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: 4.h,
                                              left: 2.w,
                                            ),
                                            child: Text(
                                              _proofTypeError!,
                                              style: GoogleFonts.inter(
                                                color: Colors.red,
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                          ),

                                        SizedBox(height: 10.h),

                                        if (selectedProofTypes
                                            .isNotEmpty) // was: selectedProofTypes.isNotEmpty
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "AI Validation (Optional)",
                                                style: GoogleFonts.inter(
                                                  color: const Color(
                                                    0xFF3F3F3F,
                                                  ),
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Wrap(
                                                spacing: 14.w,
                                                runSpacing: 10.h,
                                                children: [
                                                  _buildProoftypeOption(
                                                    "Yes",
                                                    "Yes",
                                                  ),
                                                  _buildProoftypeOption(
                                                    "No",
                                                    "No",
                                                  ),
                                                ],
                                              ),
                                              // DELETED: the _proofRadioError Padding widget
                                              SizedBox(height: 8.h),
                                              Text(
                                                'If enabled, the system uses Vision AI to scan the uploaded image to ensure it matches the task.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF797979,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                        // if (selectedProofTypes.isNotEmpty)
                                        //   Column(
                                        //     crossAxisAlignment:
                                        //         CrossAxisAlignment.start,
                                        //     children: [
                                        //       Text(
                                        //         "AI Validation (Optional)",
                                        //         style: GoogleFonts.inter(
                                        //           color: const Color(0xFF3F3F3F),
                                        //           fontSize: 13.sp,
                                        //           fontWeight: FontWeight.w600,
                                        //         ),
                                        //       ),
                                        //       SizedBox(height: 8.h),
                                        //       Wrap(
                                        //         spacing: 14.w,
                                        //         runSpacing: 10.h,
                                        //         children: [
                                        //           _buildProoftypeOption(
                                        //             "Yes",
                                        //             "Yes",
                                        //           ),
                                        //           _buildProoftypeOption(
                                        //             "No",
                                        //             "No",
                                        //           ),
                                        //         ],
                                        //       ),
                                        //       if (_proofRadioError != null)
                                        //         Padding(
                                        //           padding: EdgeInsets.only(
                                        //             top: 4.h,
                                        //             left: 2.w,
                                        //           ),
                                        //           child: Text(
                                        //             _proofRadioError!,
                                        //             style: GoogleFonts.inter(
                                        //               color: Colors.red,
                                        //               fontSize: 10.sp,
                                        //             ),
                                        //           ),
                                        //         ),
                                        //       SizedBox(height: 8.h),
                                        //       Text(
                                        //         'If enabled, the system uses Vision AI to scan the uploaded image to ensure it matches the task.',
                                        //         style: GoogleFonts.inter(
                                        //           fontSize: 11.sp,
                                        //           fontWeight: FontWeight.w400,
                                        //           color: const Color(0xFF797979),
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                      ],
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

  // Widget _assigneeChip(String name) => Container(
  //   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
  //   decoration: BoxDecoration(
  //     color: const Color(0xFFEEF0FF),
  //     borderRadius: BorderRadius.circular(20.r),
  //     border: Border.all(color: const Color(0xFF4338CA)),
  //   ),
  //   child: Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       CircleAvatar(
  //         radius: 8.r,
  //         backgroundColor: const Color(0xFF0A0258),
  //         child: Text(
  //           name[0].toUpperCase(),
  //           style: GoogleFonts.inter(
  //             fontSize: 8.sp,
  //             color: Colors.white,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ),
  //       SizedBox(width: 4.w),
  //       Text(
  //         name.split(" ").first,
  //         style: GoogleFonts.inter(
  //           fontSize: 11.sp,
  //           color: const Color(0xFF0A0258),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       SizedBox(width: 4.w),
  //       GestureDetector(
  //         onTap: () => setState(() {
  //           selectedAssignees.remove(name);
  //           if (selectedAssignees.isEmpty) {
  //             _assignToError = "Please select at least one assignee";
  //           }
  //         }),
  //         child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
  //       ),
  //     ],
  //   ),
  // );

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

  Widget _buildToggle({required bool value, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30.w,
          height: 15.h,
          padding: EdgeInsets.all(1.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: value ? const Color(0xFF1DC230) : const Color(0xFF676299),
              width: 1.2,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14.w,
              height: 14.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? const Color(0xFF1DC230)
                    : const Color(0xFF676299),
              ),
            ),
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

  Widget _buildRepeatOption(String title, String value) => GestureDetector(
    // When repeat type changes, clear selected weekdays if switching away from Weekly
    onTap: () => setState(() {
      selectedRepeatType = selectedRepeatType == value ? "" : value;
      if (selectedRepeatType != "Weekly") {
        selectedWeekdays.clear();
        _weekdayError = null; // ← add this
      }
      if (selectedRepeatType.isNotEmpty) _repeatTypeError = null;
    }),
    child: IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4338CA), width: 1.3),
            ),
            child: Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedRepeatType == value
                      ? const Color(0xFF24116A)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEndRepeatOption(String title, String value) => GestureDetector(
    onTap: () => setState(() => selectedEndType = value),
    child: IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4338CA), width: 1.3),
            ),
            child: Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedEndType == value
                      ? const Color(0xFF24116A)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildProofOption(String title, String value) {
    final isChecked = selectedProofTypes.contains(value);
    return GestureDetector(
      onTap: () => setState(() {
        if (isChecked) {
          selectedProofTypes.remove(value);
        } else {
          selectedProofTypes.add(value);
        }
        if (selectedProofTypes.isNotEmpty) _proofTypeError = null;
        // NOTE: no longer resetting selectedProofRadioType here —
        // AI Validation is global/optional, not tied to one proof type
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFF4338CA), width: 1.4),
              color: isChecked ? const Color(0xFF24116A) : Colors.transparent,
            ),
            child: isChecked
                ? Icon(Icons.check, size: 12.r, color: Colors.white)
                : null,
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildProofOption(String title, String value) => GestureDetector(
  //   onTap: () => setState(() {
  //     selectedProofTypes = selectedProofTypes == value ? "" : value;
  //     if (selectedProofTypes.isNotEmpty) _proofTypeError = null;
  //     selectedProofRadioType = "";
  //     _proofRadioError = null;
  //   }),
  //   child: Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 16.w,
  //         height: 16.w,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(4.r),
  //           border: Border.all(color: const Color(0xFF4338CA), width: 1.4),
  //           color: selectedProofTypes == value
  //               ? const Color(0xFF24116A)
  //               : Colors.transparent,
  //         ),
  //         child: selectedProofTypes == value
  //             ? Icon(Icons.check, size: 12.r, color: Colors.white)
  //             : null,
  //       ),
  //       SizedBox(width: 6.w),
  //       Text(
  //         title,
  //         overflow: TextOverflow.ellipsis,
  //         style: GoogleFonts.inter(
  //           fontSize: 11.5.sp,
  //           fontWeight: FontWeight.w400,
  //           color: const Color(0xFF344054),
  //         ),
  //       ),
  //     ],
  //   ),
  // );

  Widget _buildProoftypeOption(String title, String value) => GestureDetector(
    onTap: () => setState(() {
      selectedProofRadioType = selectedProofRadioType == value ? "" : value;
    }),
    // onTap: () => setState(() {
    //   selectedProofRadioType = selectedProofRadioType == value ? "" : value;
    //   if (selectedProofRadioType.isNotEmpty) _proofRadioError = null;
    // }),
    child: IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4338CA), width: 1.3),
            ),
            child: Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedProofRadioType == value
                      ? const Color(0xFF24116A)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    ),
  );

  // ── NEW: Weekday checkboxes (shown when Weekly is selected) ───────────────

  Widget _buildWeekdayCheckboxes() {
    const List<String> days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    return Wrap(
      spacing: 14.w,
      runSpacing: 10.h,
      children: days.map((day) {
        final isChecked = selectedWeekdays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            if (isChecked) {
              selectedWeekdays.remove(day);
              if (selectedWeekdays.isEmpty) {
                _weekdayError = "Please select at least one day";
              }
            } else {
              selectedWeekdays.add(day);
              _weekdayError = null;
            }
          }),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: const Color(0xFF4338CA),
                    width: 1.4,
                  ),
                  color: isChecked
                      ? const Color(0xFF24116A)
                      : Colors.transparent,
                ),
                child: isChecked
                    ? Icon(Icons.check, size: 11.r, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 6.w),
              Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF344054),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // // ── Assign To multi-select bottom sheet ───────────────────────────────────

  // void _showAssignToBottomSheet(BuildContext context) {
  //   List<String> tempSelected = List.from(selectedAssignees);
  //   List<Map<String, String>> filtered = List.from(_allUsers);

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     useRootNavigator: true,
  //     builder: (_) => StatefulBuilder(
  //       builder: (ctx, ss) => Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(ctx).viewInsets.bottom,
  //         ),
  //         child: Container(
  //           constraints: BoxConstraints(
  //             maxHeight: MediaQuery.of(ctx).size.height * 0.75,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.12),
  //                 blurRadius: 10.r,
  //                 offset: const Offset(0, -2),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Handle bar
  //               Container(
  //                 margin: EdgeInsets.only(top: 10.h),
  //                 width: 36.w,
  //                 height: 4.h,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFFD9DEE5),
  //                   borderRadius: BorderRadius.circular(4.r),
  //                 ),
  //               ),

  //               Padding(
  //                 padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           "Assign To",
  //                           style: GoogleFonts.inter(
  //                             fontSize: 14.sp,
  //                             fontWeight: FontWeight.w700,
  //                             color: const Color(0xFF0A0258),
  //                           ),
  //                         ),
  //                         GestureDetector(
  //                           onTap: () => Navigator.pop(ctx),
  //                           child: Icon(
  //                             Icons.close,
  //                             size: 20.r,
  //                             color: const Color(0xFF6C7278),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     if (tempSelected.isNotEmpty) ...[
  //                       SizedBox(height: 4.h),
  //                       Text(
  //                         "${tempSelected.length} selected",
  //                         style: GoogleFonts.inter(
  //                           fontSize: 11.sp,
  //                           color: const Color(0xFF4338CA),
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                     SizedBox(height: 10.h),
  //                     TextField(
  //                       autofocus: false,
  //                       onChanged: (val) => ss(() {
  //                         filtered = _allUsers
  //                             .where(
  //                               (u) =>
  //                                   u["name"]!.toLowerCase().contains(
  //                                     val.toLowerCase().trim(),
  //                                   ) ||
  //                                   u["role"]!.toLowerCase().contains(
  //                                     val.toLowerCase().trim(),
  //                                   ),
  //                             )
  //                             .toList();
  //                       }),
  //                       style: GoogleFonts.inter(
  //                         fontSize: 12.sp,
  //                         color: const Color(0xFF344054),
  //                       ),
  //                       decoration: InputDecoration(
  //                         isDense: true,
  //                         hintText: "Search by name or role...",
  //                         hintStyle: GoogleFonts.inter(
  //                           fontSize: 12.sp,
  //                           color: const Color(0xFFB8BEC5),
  //                         ),
  //                         prefixIcon: Icon(
  //                           CupertinoIcons.search,
  //                           size: 16.r,
  //                           color: const Color(0xFF4338CA),
  //                         ),
  //                         filled: true,
  //                         fillColor: const Color(0xFFF9FAFC),
  //                         contentPadding: EdgeInsets.symmetric(
  //                           horizontal: 10.w,
  //                           vertical: 10.h,
  //                         ),
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFFD9DEE5),
  //                           ),
  //                         ),
  //                         enabledBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFFD9DEE5),
  //                           ),
  //                         ),
  //                         focusedBorder: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.r),
  //                           borderSide: const BorderSide(
  //                             color: Color(0xFF0A0258),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(height: 8.h),
  //                   ],
  //                 ),
  //               ),

  //               Flexible(
  //                 child: filtered.isEmpty
  //                     ? Padding(
  //                         padding: EdgeInsets.symmetric(vertical: 24.h),
  //                         child: Center(
  //                           child: Text(
  //                             "No users found",
  //                             style: GoogleFonts.inter(
  //                               fontSize: 12.sp,
  //                               color: const Color(0xFF9AA0AB),
  //                             ),
  //                           ),
  //                         ),
  //                       )
  //                     : ListView.separated(
  //                         shrinkWrap: true,
  //                         padding: EdgeInsets.symmetric(horizontal: 16.w),
  //                         itemCount: filtered.length,
  //                         separatorBuilder: (_, __) => const Divider(
  //                           height: 1,
  //                           color: Color(0xFFE4E7EC),
  //                         ),
  //                         itemBuilder: (_, i) {
  //                           final user = filtered[i];
  //                           final name = user["name"]!;
  //                           final role = user["role"]!;
  //                           final isChecked = tempSelected.contains(name);
  //                           return InkWell(
  //                             borderRadius: BorderRadius.circular(8.r),
  //                             onTap: () => ss(
  //                               () => isChecked
  //                                   ? tempSelected.remove(name)
  //                                   : tempSelected.add(name),
  //                             ),
  //                             child: Padding(
  //                               padding: EdgeInsets.symmetric(vertical: 10.h),
  //                               child: Row(
  //                                 children: [
  //                                   CircleAvatar(
  //                                     radius: 18.r,
  //                                     backgroundColor: isChecked
  //                                         ? const Color(0xFF0A0258)
  //                                         : const Color(0xFFEEF0FF),
  //                                     child: Text(
  //                                       name[0].toUpperCase(),
  //                                       style: GoogleFonts.inter(
  //                                         fontSize: 13.sp,
  //                                         fontWeight: FontWeight.w700,
  //                                         color: isChecked
  //                                             ? Colors.white
  //                                             : const Color(0xFF4338CA),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                   SizedBox(width: 10.w),
  //                                   Expanded(
  //                                     child: Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: [
  //                                         Text(
  //                                           name,
  //                                           style: GoogleFonts.inter(
  //                                             fontSize: 13.sp,
  //                                             fontWeight: isChecked
  //                                                 ? FontWeight.w600
  //                                                 : FontWeight.w400,
  //                                             color: const Color(0xFF1D2939),
  //                                           ),
  //                                         ),
  //                                         SizedBox(height: 2.h),
  //                                         Text(
  //                                           role,
  //                                           style: GoogleFonts.inter(
  //                                             fontSize: 11.sp,
  //                                             color: const Color(0xFF9AA0AB),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                   AnimatedContainer(
  //                                     duration: const Duration(
  //                                       milliseconds: 200,
  //                                     ),
  //                                     width: 20.w,
  //                                     height: 20.h,
  //                                     decoration: BoxDecoration(
  //                                       color: isChecked
  //                                           ? const Color(0xFF0A0258)
  //                                           : Colors.transparent,
  //                                       borderRadius: BorderRadius.circular(
  //                                         5.r,
  //                                       ),
  //                                       border: Border.all(
  //                                         color: isChecked
  //                                             ? const Color(0xFF0A0258)
  //                                             : const Color(0xFFD9DEE5),
  //                                         width: 1.5,
  //                                       ),
  //                                     ),
  //                                     child: isChecked
  //                                         ? Icon(
  //                                             Icons.check,
  //                                             size: 13.r,
  //                                             color: Colors.white,
  //                                           )
  //                                         : null,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //               ),

  //               SafeArea(
  //                 top: false,
  //                 child: Padding(
  //                   padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
  //                   child: Row(
  //                     children: [
  //                       Expanded(
  //                         child: OutlinedButton(
  //                           onPressed: () => ss(() => tempSelected.clear()),
  //                           style: OutlinedButton.styleFrom(
  //                             side: const BorderSide(color: Color(0xFFD9DEE5)),
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(8.r),
  //                             ),
  //                             padding: EdgeInsets.symmetric(vertical: 10.h),
  //                           ),
  //                           child: Text(
  //                             "Clear All",
  //                             style: GoogleFonts.inter(
  //                               fontSize: 12.sp,
  //                               fontWeight: FontWeight.w500,
  //                               color: const Color(0xFF667085),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(width: 10.w),
  //                       Expanded(
  //                         flex: 2,
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(8.r),
  //                             gradient: const LinearGradient(
  //                               colors: [Color(0xFF0A0258), Color(0xFF4338CA)],
  //                             ),
  //                           ),
  //                           child: ElevatedButton(
  //                             onPressed: () {
  //                               setState(() {
  //                                 selectedAssignees = List.from(tempSelected);
  //                                 if (selectedAssignees.isNotEmpty) {
  //                                   _assignToError = null;
  //                                 }
  //                               });
  //                               Navigator.pop(ctx);
  //                             },
  //                             style: ElevatedButton.styleFrom(
  //                               elevation: 0,
  //                               backgroundColor: Colors.transparent,
  //                               shadowColor: Colors.transparent,
  //                               padding: EdgeInsets.symmetric(vertical: 10.h),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(8.r),
  //                               ),
  //                             ),
  //                             child: Text(
  //                               tempSelected.isEmpty
  //                                   ? "Confirm"
  //                                   : "Confirm (${tempSelected.length})",
  //                               style: GoogleFonts.inter(
  //                                 fontSize: 12.sp,
  //                                 fontWeight: FontWeight.w600,
  //                                 color: Colors.white,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

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
                      final departments = departmentController.departments
                          .where((d) => d.location?.id == selectedLocation?.id)
                          .toList();
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
                                  final oldIds = selectedNewDepartments
                                      .map((d) => d.id)
                                      .toSet();
                                  final newIds = tempSelected
                                      .map((d) => d.id)
                                      .toSet();
                                  final departmentsChanged =
                                      oldIds.length != newIds.length ||
                                      !oldIds.containsAll(newIds);
                                  selectedNewDepartments = List.from(
                                    tempSelected,
                                  );
                                  if (selectedNewDepartments.isNotEmpty) {
                                    _newDepartmentError = null;
                                  }
                                  // Previously selected assignees may not
                                  // belong to the newly chosen department(s).
                                  if (departmentsChanged) {
                                    selectedAssignees = [];
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

  /// Employees belonging to any of the currently selected "New Department"
  /// entries — the Assign To dropdown is scoped to this list.
  List<EmployeeModel> _employeesForSelectedDepartments() {
    if (selectedNewDepartments.isEmpty) return [];
    final departmentNames = selectedNewDepartments
        .map((d) => d.name)
        .whereType<String>()
        .toSet();
    return employeeController.allEmployees
        .where((e) => departmentNames.contains(e.department))
        .toList();
  }

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

  // Widget _reportingChip(String name) => Container(
  //   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
  //   decoration: BoxDecoration(
  //     color: const Color(0xFFEEF0FF),
  //     borderRadius: BorderRadius.circular(20.r),
  //     border: Border.all(color: const Color(0xFF4338CA)),
  //   ),
  //   child: Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       CircleAvatar(
  //         radius: 8.r,
  //         backgroundColor: const Color(0xFF0A0258),
  //         child: Text(
  //           name[0].toUpperCase(),
  //           style: GoogleFonts.inter(
  //             fontSize: 8.sp,
  //             color: Colors.white,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ),
  //       SizedBox(width: 4.w),
  //       Text(
  //         name.split(" ").first,
  //         style: GoogleFonts.inter(
  //           fontSize: 11.sp,
  //           color: const Color(0xFF0A0258),
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       SizedBox(width: 4.w),
  //       GestureDetector(
  //         onTap: () => setState(() {
  //           selectedReportingList.remove(name);
  //           selectedReporting = selectedReportingList.isEmpty
  //               ? "Select User"
  //               : selectedReportingList.join(", ");
  //           if (selectedReportingList.isEmpty) {
  //             _reportingToError = "Please select a user";
  //           }
  //         }),
  //         child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
  //       ),
  //     ],
  //   ),
  // );
}
