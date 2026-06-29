import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SectionValidatable.dart';

class SkillPerformSection extends StatefulWidget {
  const SkillPerformSection({super.key});
  @override
  State<SkillPerformSection> createState() => SkillPerformSectionState();
}

class SkillPerformSectionState extends State<SkillPerformSection>
    implements SectionValidatable {
  final TextEditingController _programmingController = TextEditingController();
  final TextEditingController _certificationController =
      TextEditingController();
  final TextEditingController _okrController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _trainingCoursesController =
      TextEditingController();
  final TextEditingController _complianceTrainingController =
      TextEditingController();

  final FocusNode _programmingFocus = FocusNode();
  final FocusNode _certificationFocus = FocusNode();
  final FocusNode _okrFocus = FocusNode();
  final FocusNode _feedbackFocus = FocusNode();
  final FocusNode _trainingCoursesFocus = FocusNode();
  final FocusNode _complianceTrainingFocus = FocusNode();

  bool _isProgrammingEditing = false;
  bool _isCertificationEditing = false;
  bool _isOkrEditing = false;
  bool _isFeedbackEditing = false;
  bool _isTrainingCoursesEditing = false;
  bool _isComplianceTrainingEditing = false;

  String? _programmingError;
  String? _certificationError;
  String? _okrError;
  String? _feedbackError;
  String? _trainingCoursesError;
  String? _complianceTrainingError;

  // ── Soft Skills ─────────────────────────────────────────────────────────────
  final List<String> _softSkillOptions = [
    'Teamwork',
    'Flexibility',
    'Communication',
    'Leadership',
    'Creativity',
  ];
  List<String> _selectedSoftSkills = ['Teamwork', 'Flexibility'];

  @override
  void initState() {
    super.initState();
    _programmingController.text = "Python";
    _certificationController.text = "Done";
    _okrController.text = "Track Progress";
    _feedbackController.text = "Lorem ipsum dolor sit amet, consectet...";
    _trainingCoursesController.text = "Completed Courses";
    _complianceTrainingController.text = "Mandatory Compliance Training";
  }

  @override
  void dispose() {
    _programmingController.dispose();
    _certificationController.dispose();
    _okrController.dispose();
    _feedbackController.dispose();
    _trainingCoursesController.dispose();
    _complianceTrainingController.dispose();
    _programmingFocus.dispose();
    _certificationFocus.dispose();
    _okrFocus.dispose();
    _feedbackFocus.dispose();
    _trainingCoursesFocus.dispose();
    _complianceTrainingFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _programmingError = _programmingController.text.trim().isEmpty
          ? "Please enter programming languages"
          : null;
      _certificationError = _certificationController.text.trim().isEmpty
          ? "Please enter certification"
          : null;
      _okrError = _okrController.text.trim().isEmpty
          ? "Please enter OKRs"
          : null;
      _feedbackError = _feedbackController.text.trim().isEmpty
          ? "Please enter feedback"
          : null;
      _trainingCoursesError = _trainingCoursesController.text.trim().isEmpty
          ? "Please enter training courses"
          : null;
      _complianceTrainingError =
          _complianceTrainingController.text.trim().isEmpty
          ? "Please enter compliance training"
          : null;

      if (_programmingError != null ||
          _certificationError != null ||
          _okrError != null ||
          _feedbackError != null ||
          _trainingCoursesError != null ||
          _complianceTrainingError != null) {
        valid = false;
      }
    });
    return valid;
  }

  // ── Soft Skills bottom sheet (same as Assign To) ───────────────────────────
  void _showSoftSkillsBottomSheet(BuildContext context) {
    List<String> tempSelected = List.from(_selectedSoftSkills);
    List<String> filtered = List.from(_softSkillOptions);

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
                            "Soft Skills",
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

                      // Search
                      TextField(
                        autofocus: false,
                        onChanged: (val) => ss(() {
                          filtered = _softSkillOptions
                              .where(
                                (s) => s.toLowerCase().contains(
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
                          hintText: "Search skills...",
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

                // Skills list
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No skills found",
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
                            final skill = filtered[i];
                            final isChecked = tempSelected.contains(skill);
                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () => ss(
                                () => isChecked
                                    ? tempSelected.remove(skill)
                                    : tempSelected.add(skill),
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
                                        skill[0].toUpperCase(),
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
                                      child: Text(
                                        skill,
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
                                setState(
                                  () => _selectedSoftSkills = List.from(
                                    tempSelected,
                                  ),
                                );
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

  // ── Chip (same as _assigneeChip) ───────────────────────────────────────────
  Widget _buildChip(String label) => Container(
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
            label[0].toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: const Color(0xFF0A0258),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => setState(() => _selectedSoftSkills.remove(label)),
          child: Icon(Icons.close, size: 11.r, color: const Color(0xFF4338CA)),
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0A0258),
      ),
    ),
  );

  Widget _fieldLabel(String label, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF303030),
        ),
        children: required
            ? const [
                TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : [],
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required FocusNode focusNode,
    String? errorText,
    VoidCallback? onClearError,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: !isEditing,
          maxLines: maxLines,
          enableInteractiveSelection: isEditing,
          showCursor: isEditing,
          onChanged: (_) {
            if (onClearError != null) onClearError();
          },
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6C7278),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            suffixIcon: GestureDetector(
              onTap: () {
                if (!isEditing) onEdit();
                Future.microtask(() => focusNode.requestFocus());
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18.sp,
                  color: const Color(0xFFB8BEC5),
                ),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFFD9DEE5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFF0A0258),
              ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Skill Tags'),
        _fieldLabel('Programming Languages', required: true),
        _buildTextField(
          controller: _programmingController,
          isEditing: _isProgrammingEditing,
          focusNode: _programmingFocus,
          onEdit: () {
            if (!_isProgrammingEditing) {
              setState(() => _isProgrammingEditing = true);
            }
          },
          errorText: _programmingError,
          onClearError: () => setState(
            () => _programmingError = _programmingController.text.trim().isEmpty
                ? "Please enter programming languages"
                : null,
          ),
        ),
        SizedBox(height: 10.h),

        // ── Soft Skills — same as Assign To ───────────────────────────
        _fieldLabel('Soft Skills'),
        GestureDetector(
          onTap: () => _showSoftSkillsBottomSheet(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFD9DEE5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedSoftSkills.isEmpty
                      ? Text(
                          "Select soft skills...",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFB8BEC5),
                          ),
                        )
                      : Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: _selectedSoftSkills
                              .map(_buildChip)
                              .toList(),
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

        SizedBox(height: 10.h),
        _fieldLabel('Certification', required: true),
        _buildTextField(
          controller: _certificationController,
          isEditing: _isCertificationEditing,
          focusNode: _certificationFocus,
          onEdit: () {
            if (!_isCertificationEditing) {
              setState(() => _isCertificationEditing = true);
            }
          },
          errorText: _certificationError,
          onClearError: () => setState(
            () => _certificationError =
                _certificationController.text.trim().isEmpty
                ? "Please enter certification"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Performance History'),
        GestureDetector(
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              'Move to Past Reviews',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0039F4),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF0039F4),
              ),
            ),
          ),
        ),
        _fieldLabel('OKRs (Objectives and Key Results)', required: true),
        _buildTextField(
          controller: _okrController,
          isEditing: _isOkrEditing,
          focusNode: _okrFocus,
          onEdit: () {
            if (!_isOkrEditing) setState(() => _isOkrEditing = true);
          },
          errorText: _okrError,
          onClearError: () => setState(
            () => _okrError = _okrController.text.trim().isEmpty
                ? "Please enter OKRs"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Feedback', required: true),
        _buildTextField(
          controller: _feedbackController,
          isEditing: _isFeedbackEditing,
          focusNode: _feedbackFocus,
          onEdit: () {
            if (!_isFeedbackEditing) setState(() => _isFeedbackEditing = true);
          },
          errorText: _feedbackError,
          maxLines: 3,
          onClearError: () => setState(
            () => _feedbackError = _feedbackController.text.trim().isEmpty
                ? "Please enter feedback"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Training & Development'),
        _fieldLabel('Training Courses', required: true),
        _buildTextField(
          controller: _trainingCoursesController,
          isEditing: _isTrainingCoursesEditing,
          focusNode: _trainingCoursesFocus,
          onEdit: () {
            if (!_isTrainingCoursesEditing) {
              setState(() => _isTrainingCoursesEditing = true);
            }
          },
          errorText: _trainingCoursesError,
          onClearError: () => setState(
            () => _trainingCoursesError =
                _trainingCoursesController.text.trim().isEmpty
                ? "Please enter training courses"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Compliance Training', required: true),
        _buildTextField(
          controller: _complianceTrainingController,
          isEditing: _isComplianceTrainingEditing,
          focusNode: _complianceTrainingFocus,
          onEdit: () {
            if (!_isComplianceTrainingEditing) {
              setState(() => _isComplianceTrainingEditing = true);
            }
          },
          errorText: _complianceTrainingError,
          onClearError: () => setState(
            () => _complianceTrainingError =
                _complianceTrainingController.text.trim().isEmpty
                ? "Please enter compliance training"
                : null,
          ),
        ),
      ],
    );
  }
}
