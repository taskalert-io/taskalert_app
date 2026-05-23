import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

class IdentityAssignmentScreen extends StatefulWidget {
  const IdentityAssignmentScreen({super.key, required this.userId});
  final String userId;
  @override
  State<StatefulWidget> createState() => IdentityAssignmentScreenState();
}

class IdentityAssignmentScreenState extends State<IdentityAssignmentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  String selectedDepartment = "Retail";
  String selectedPriority = "High";

  int selectedTabIndex = 0;

  List<String> selectedFiles = [];

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

    // if (result != null) {
    //   setState(() {
    //     selectedFiles = result.paths.map((e) => e ?? "").toList();
    //   });
    // }
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files
            .map((file) => file.name)
            .toList();
      });
    }
  }

  final titleNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId, // ✅ Pass the correct userId
        showLeading: true, // ✅ Set to true to show the back button
        onBackPressed: () {
          Navigator.pop(context); // Optional: customize back behavior if needed
        },
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
    child: LayoutBuilder(
          builder: (context, constraints){
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 120.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),

                child: Container(
                  color: const Color(0xFFF5F7FB),
                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Tabs
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),

                              onTap: () {
                                setState(() {
                                  selectedTabIndex = 0;
                                });
                              },

                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),

                                child: _buildTab(
                                  title: "Store Identity & Media",
                                  isSelected: selectedTabIndex == 0,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10.w),

                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),

                              onTap: () {
                                setState(() {
                                  selectedTabIndex = 1;
                                });
                              },

                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),

                                child: _buildTab(
                                  title: "Assignment & Recurrence",
                                  isSelected: selectedTabIndex == 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      /// Main Card
                      if (selectedTabIndex == 0) Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  _buildLabel("Title"),

                                  SizedBox(height: 3.h),

                                  buildTextField(
                                    suffixIcon: Icon(
                                      CupertinoIcons.pencil,
                                      size: 18.r,
                                      color: Colors.black54,
                                    ),

                                    hint: "Clean Production Floor",
                                    controller: titleNameController,

                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "Enter title";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 8.h),

                                  _buildLabel("Department"),

                                  SizedBox(height: 3.h),

                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      canvasColor: Colors.white,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                    ),

                                    child: ButtonTheme(
                                      alignedDropdown: true,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedDepartment,

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

                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 8.h,
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

                                        items: ["Retail", "Marketing", "Sales"]
                                            .map(
                                              (e) => DropdownMenuItem<String>(
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

                                        onChanged: (value) {
                                          setState(() {
                                            selectedDepartment = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 8.h),

                                  _buildLabel("Priority"),

                                  SizedBox(height: 3.h),

                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      canvasColor: Colors.white,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                    ),

                                    child: ButtonTheme(
                                      alignedDropdown: true,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedPriority,

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

                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 8.h,
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

                                        items: ["High", "Medium", "Low"]
                                            .map(
                                              (e) => DropdownMenuItem<String>(
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

                                        onChanged: (value) {
                                          setState(() {
                                            selectedPriority = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 8.h),

                                  _buildLabel("Description"),

                                  SizedBox(height: 3.h),

                                  TextFormField(
                                    maxLines: 3,

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

                                  Text(
                                    "Add Attachments",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                      color: Color(0xFF3F3F3F)
                                    ),
                                  ),

                                  Text(
                                    "File must be in pdf, doc, png, jpg, gif or mp4 format\nand upto 5 file(s) at a time.",

                                    style: GoogleFonts.inter(
                                      color: Color(0xFF797979),
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
                                          color: const Color(0xFFB9C3FF),
                                        ),
                                      ),

                                      child: Column(
                                        children: [
                                          Text(
                                            "Drag & drop your file(s) here or",

                                            style: GoogleFonts.inter(
                                              color: Color(0xFF797979),
                                              fontSize: 11.sp,
                                            ),
                                          ),

                                          SizedBox(height: 3.h),

                                          Text(
                                            "Browse",

                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF304DDB),

                                              fontWeight: FontWeight.w600,

                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: EdgeInsets.only(top: 14.h),

                                    child: Column(
                                      children: [

                                        /// FILE LIST
                                        if (selectedFiles.isNotEmpty)
                                          ...List.generate(selectedFiles.length, (index) {

                                            final fileName = selectedFiles[index];

                                            final progress = index == 0 ? 0.30 : 0.82;

                                            return Padding(
                                              padding: EdgeInsets.only(bottom: 12.h),

                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.insert_drive_file_outlined,
                                                        size: 18.r,
                                                        color: const Color(0xFF7B7B7B),
                                                      ),

                                                      SizedBox(width: 6.w),

                                                      Expanded(
                                                        child: Text(
                                                          fileName,
                                                          overflow: TextOverflow.ellipsis,

                                                          style: GoogleFonts.inter(
                                                            fontSize: 11.sp,
                                                            fontWeight: FontWeight.w500,
                                                            color: const Color(0xFF5F6368),
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(width: 8.w),

                                                      Text(
                                                        "${(progress * 100).toInt()}%",

                                                        style: GoogleFonts.inter(
                                                          fontSize: 11.sp,
                                                          fontWeight: FontWeight.w500,
                                                          color: const Color(0xFF5F6368),
                                                        ),
                                                      ),

                                                      SizedBox(width: 6.w),

                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedFiles.removeAt(index);
                                                          });
                                                        },

                                                        child: Icon(
                                                          Icons.close,
                                                          size: 16.r,
                                                          color: const Color(0xFF7B7B7B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  SizedBox(height: 6.h),

                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(20.r),

                                                    child: LinearProgressIndicator(
                                                      value: progress,
                                                      minHeight: 2.5.h,
                                                      backgroundColor: const Color(0xFFE5E7EB),
                                                      valueColor: const AlwaysStoppedAnimation(
                                                        Color(0xFF304DDB),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                        SizedBox(height: 20.h),

                                        /// BUTTONS ALWAYS VISIBLE
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,

                                          children: [

                                            /// CANCEL BUTTON
                                            OutlinedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedFiles.clear();
                                                });
                                              },

                                              style: OutlinedButton.styleFrom(
                                                minimumSize: Size(90.w, 40.h),

                                                side: const BorderSide(
                                                  color: Color(0xFF21187F),
                                                ),

                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.r),
                                                ),
                                              ),

                                              child: Text(
                                                "Cancel",

                                                style: GoogleFonts.inter(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF21187F),
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 10.w),

                                            /// SAVE BUTTON
                                            Container(
                                              height: 40.h,

                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10.r),

                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFD96CFF),
                                                    Color(0xFF5CE1E6),
                                                  ],
                                                ),
                                              ),

                                              child: ElevatedButton(
                                                onPressed: () {

                                                  /// SUBMIT FORM HERE

                                                },

                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,

                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10.r),
                                                  ),
                                                ),

                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 20.w),

                                                  child: Text(
                                                    "Save",

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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ) else Container(
                              width: double.infinity,

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                              ),

                              child: Center(
                                child: Text(
                                  "Assignment & Recurrence",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),

            ),
          );})

      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildTab({required String title, required bool isSelected}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,

          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF1E1B4B) : Colors.grey,
          ),
        ),

        SizedBox(height: 3.h),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),

          height: 2.h,
          width: double.infinity,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),

            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFD969FF),
                      Color(0xFF4DA5FB),
                      Color(0xFF54DBC6),
                    ],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade300],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: Color(0xFF3F3F3F),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),

        children: [
          TextSpan(
            text: " *",
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required Icon suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,

      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6C7278),
      ),

      decoration: InputDecoration(
        isDense: true,

        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        hintText: hint,

        hintStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
        ),

        // REMOVE THESE
        // helperText: " ",
        // helperStyle: TextStyle(height: 0.h),
        errorStyle: TextStyle(fontSize: 10.sp),

        prefixIcon: prefix,
        suffixIcon: suffix,

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
  }
}
