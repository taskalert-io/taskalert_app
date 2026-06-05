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
  final TextEditingController _certificationController = TextEditingController();
  final TextEditingController _okrController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _trainingCoursesController = TextEditingController();
  final TextEditingController _complianceTrainingController = TextEditingController();

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

  final List<String> _softSkillOptions = ['Teamwork', 'Flexibility', 'Communication', 'Leadership', 'Creativity'];
  final List<String> _selectedSoftSkills = ['Teamwork', 'Flexibility'];
  bool _softSkillDropdownOpen = false;

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
    _programmingController.dispose(); _certificationController.dispose();
    _okrController.dispose(); _feedbackController.dispose();
    _trainingCoursesController.dispose(); _complianceTrainingController.dispose();
    _programmingFocus.dispose(); _certificationFocus.dispose();
    _okrFocus.dispose(); _feedbackFocus.dispose();
    _trainingCoursesFocus.dispose(); _complianceTrainingFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _programmingError = _programmingController.text.trim().isEmpty ? "Please enter programming languages" : null;
      _certificationError = _certificationController.text.trim().isEmpty ? "Please enter certification" : null;
      _okrError = _okrController.text.trim().isEmpty ? "Please enter OKRs" : null;
      _feedbackError = _feedbackController.text.trim().isEmpty ? "Please enter feedback" : null;
      _trainingCoursesError = _trainingCoursesController.text.trim().isEmpty ? "Please enter training courses" : null;
      _complianceTrainingError = _complianceTrainingController.text.trim().isEmpty ? "Please enter compliance training" : null;

      if (_programmingError != null || _certificationError != null || _okrError != null ||
          _feedbackError != null || _trainingCoursesError != null || _complianceTrainingError != null) {
        valid = false;
      }
    });
    return valid;
  }

  Widget _sectionHeading(String title) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(title, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0A0258))),
  );

  Widget _fieldLabel(String label, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF303030)),
        children: required ? const [TextSpan(text: " *", style: TextStyle(color: Colors.red))] : [],
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
          controller: controller, focusNode: focusNode,
          readOnly: !isEditing, maxLines: maxLines,
          onChanged: (_) { if (onClearError != null) onClearError(); },
          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF6C7278)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            suffixIcon: GestureDetector(
              onTap: () {
                if (!isEditing) onEdit();
                Future.microtask(() => focusNode.requestFocus());
              },
              child: Padding(padding: const EdgeInsets.all(10),
                  child: Icon(Icons.edit_outlined, size: 18.sp, color: const Color(0xFFB8BEC5))),
            ),
            filled: true, fillColor: const Color(0xFFF9FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Color(0xFFD9DEE5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: errorText != null ? Colors.red : const Color(0xFFD9DEE5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: errorText != null ? Colors.red : const Color(0xFF0A0258))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
        if (errorText != null)
          Padding(padding: EdgeInsets.only(top: 4.h, left: 4.w),
              child: Text(errorText, style: GoogleFonts.inter(color: Colors.red, fontSize: 10.sp))),
      ],
    );
  }

  Widget _buildSoftSkillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _softSkillDropdownOpen = !_softSkillDropdownOpen),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFC), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: const Color(0xFFD9DEE5))),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(spacing: 6.w, runSpacing: 4.h,
                    children: [
                      ..._selectedSoftSkills.map((skill) => _buildChip(skill)),
                      if (_selectedSoftSkills.isEmpty)
                        Text('Select soft skills', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFB8BEC5))),
                    ],
                  ),
                ),
                Icon(_softSkillDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18.sp, color: const Color(0xFFB8BEC5)),
              ],
            ),
          ),
        ),
        if (_softSkillDropdownOpen)
          Container(
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFD9DEE5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]),
            child: Column(
              children: _softSkillOptions.map((skill) {
                final isSelected = _selectedSoftSkills.contains(skill);
                return InkWell(
                  onTap: () => setState(() => isSelected ? _selectedSoftSkills.remove(skill) : _selectedSoftSkills.add(skill)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(children: [
                      Expanded(child: Text(skill, style: GoogleFonts.inter(fontSize: 12.sp,
                          color: isSelected ? const Color(0xFF0A0258) : const Color(0xFF6C7278),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
                      if (isSelected) Icon(Icons.check, size: 14.sp, color: const Color(0xFF0A0258)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(color: const Color(0xFFEEF0FB), borderRadius: BorderRadius.circular(20.r)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0A0258))),
      SizedBox(width: 4.w),
      GestureDetector(onTap: () => setState(() => _selectedSoftSkills.remove(label)),
          child: Icon(Icons.close, size: 12.sp, color: const Color(0xFF0A0258))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Skill Tags'),
        _fieldLabel('Programming Languages', required: true),
        _buildTextField(controller: _programmingController, isEditing: _isProgrammingEditing, focusNode: _programmingFocus,
            onEdit: () { if (!_isProgrammingEditing) setState(() => _isProgrammingEditing = true); },
            errorText: _programmingError,
            onClearError: () => setState(() => _programmingError = _programmingController.text.trim().isEmpty ? "Please enter programming languages" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Soft Skills'),
        _buildSoftSkillsField(),
        SizedBox(height: 10.h),
        _fieldLabel('Certification', required: true),
        _buildTextField(controller: _certificationController, isEditing: _isCertificationEditing, focusNode: _certificationFocus,
            onEdit: () { if (!_isCertificationEditing) setState(() => _isCertificationEditing = true); },
            errorText: _certificationError,
            onClearError: () => setState(() => _certificationError = _certificationController.text.trim().isEmpty ? "Please enter certification" : null)),
        SizedBox(height: 16.h),
        _sectionHeading('Performance History'),
        GestureDetector(onTap: () {},
            child: Padding(padding: EdgeInsets.only(bottom: 10.h),
                child: Text('Move to Past Reviews', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500,
                    color: const Color(0xFF0039F4), decoration: TextDecoration.underline, decorationColor: const Color(0xFF0039F4))))),
        _fieldLabel('OKRs (Objectives and Key Results)', required: true),
        _buildTextField(controller: _okrController, isEditing: _isOkrEditing, focusNode: _okrFocus,
            onEdit: () { if (!_isOkrEditing) setState(() => _isOkrEditing = true); },
            errorText: _okrError,
            onClearError: () => setState(() => _okrError = _okrController.text.trim().isEmpty ? "Please enter OKRs" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Feedback', required: true),
        _buildTextField(controller: _feedbackController, isEditing: _isFeedbackEditing, focusNode: _feedbackFocus,
            onEdit: () { if (!_isFeedbackEditing) setState(() => _isFeedbackEditing = true); },
            errorText: _feedbackError, maxLines: 3,
            onClearError: () => setState(() => _feedbackError = _feedbackController.text.trim().isEmpty ? "Please enter feedback" : null)),
        SizedBox(height: 16.h),
        _sectionHeading('Training & Development'),
        _fieldLabel('Training Courses', required: true),
        _buildTextField(controller: _trainingCoursesController, isEditing: _isTrainingCoursesEditing, focusNode: _trainingCoursesFocus,
            onEdit: () { if (!_isTrainingCoursesEditing) setState(() => _isTrainingCoursesEditing = true); },
            errorText: _trainingCoursesError,
            onClearError: () => setState(() => _trainingCoursesError = _trainingCoursesController.text.trim().isEmpty ? "Please enter training courses" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Compliance Training', required: true),
        _buildTextField(controller: _complianceTrainingController, isEditing: _isComplianceTrainingEditing, focusNode: _complianceTrainingFocus,
            onEdit: () { if (!_isComplianceTrainingEditing) setState(() => _isComplianceTrainingEditing = true); },
            errorText: _complianceTrainingError,
            onClearError: () => setState(() => _complianceTrainingError = _complianceTrainingController.text.trim().isEmpty ? "Please enter compliance training" : null)),
      ],
    );
  }
}