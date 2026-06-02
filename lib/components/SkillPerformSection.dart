import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillPerformSection extends StatefulWidget {
  const SkillPerformSection({super.key});
  @override
  State<SkillPerformSection> createState() => _SkillPerformSectionState();
}

class _SkillPerformSectionState extends State<SkillPerformSection> {
  // Skill Tags
  final TextEditingController _programmingController  = TextEditingController();
  final TextEditingController _certificationController = TextEditingController();

  // Soft Skills chips
  final List<String> _softSkillOptions = ['Teamwork', 'Flexibility', 'Communication', 'Leadership', 'Creativity'];
  final List<String> _selectedSoftSkills = ['Teamwork', 'Flexibility'];
  bool _softSkillDropdownOpen = false;

  // Performance History
  final TextEditingController _okrController       = TextEditingController();
  final TextEditingController _feedbackController  = TextEditingController();

  // Training & Development
  final TextEditingController _trainingCoursesController   = TextEditingController();
  final TextEditingController _complianceTrainingController = TextEditingController();

  @override
  void dispose() {
    _programmingController.dispose();
    _certificationController.dispose();
    _okrController.dispose();
    _feedbackController.dispose();
    _trainingCoursesController.dispose();
    _complianceTrainingController.dispose();
    super.dispose();
  }

  // ── Edit icon ──────────────────────────────────────────────────────────────
  Widget get _editIcon => Padding(
    padding: const EdgeInsets.all(10),
    child: Icon(Icons.edit_outlined, size: 18.sp, color: const Color(0xFFB8BEC5)),
  );

  // ── Section heading ────────────────────────────────────────────────────────
  Widget _sectionHeading(String title) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(title,
        style: GoogleFonts.inter(
            fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0A0258))),
  );

  // ── Field label ────────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF303030))),
  );

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF6C7278)),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFFB8BEC5)),
        suffixIcon: _editIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Color(0xFFD9DEE5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Color(0xFFD9DEE5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Color(0xFF0A0258))),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  // ── Soft Skills multi-select chip field ────────────────────────────────────
  Widget _buildSoftSkillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip container mimicking a text field
        GestureDetector(
          onTap: () => setState(() => _softSkillDropdownOpen = !_softSkillDropdownOpen),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFD9DEE5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      ..._selectedSoftSkills.map((skill) => _buildChip(skill)),
                      if (_selectedSoftSkills.isEmpty)
                        Text('Select soft skills',
                            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFB8BEC5))),
                    ],
                  ),
                ),
                Icon(
                  _softSkillDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18.sp,
                  color: const Color(0xFFB8BEC5),
                ),
              ],
            ),
          ),
        ),

        // Dropdown options
        if (_softSkillDropdownOpen)
          Container(
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFD9DEE5)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: _softSkillOptions.map((skill) {
                final isSelected = _selectedSoftSkills.contains(skill);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSoftSkills.remove(skill);
                      } else {
                        _selectedSoftSkills.add(skill);
                      }
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(skill,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: isSelected ? const Color(0xFF0A0258) : const Color(0xFF6C7278),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                        ),
                        if (isSelected)
                          Icon(Icons.check, size: 14.sp, color: const Color(0xFF0A0258)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Single removable chip ──────────────────────────────────────────────────
  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FB),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0A0258))),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => setState(() => _selectedSoftSkills.remove(label)),
            child: Icon(Icons.close, size: 12.sp, color: const Color(0xFF0A0258)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Skill Tags ───────────────────────────────────────────────────
        _sectionHeading('Skill Tags:'),

        _fieldLabel('Programing Languages :'),
        _buildTextField(hint: 'Python', controller: _programmingController),
        SizedBox(height: 10.h),

        _fieldLabel('Soft Skills :'),
        _buildSoftSkillsField(),
        SizedBox(height: 10.h),

        _fieldLabel('Certification :'),
        _buildTextField(hint: 'Done', controller: _certificationController),
        SizedBox(height: 16.h),

        // ── Performance History ──────────────────────────────────────────
        _sectionHeading('Performance History :'),

        // Move to Past Reviews link
        GestureDetector(
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              'Move to Past Reviews',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A0258),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF0A0258),
              ),
            ),
          ),
        ),

        _fieldLabel('OKRs (Objectives and Key Results) :'),
        _buildTextField(hint: 'Track Progress', controller: _okrController),
        SizedBox(height: 10.h),

        _fieldLabel('Feedback :'),
        _buildTextField(
          hint: 'Lorem ipsum dolor sit amet, consectet...',
          controller: _feedbackController,
          maxLines: 3,
        ),
        SizedBox(height: 16.h),

        // ── Training & Development ───────────────────────────────────────
        _sectionHeading('Training & Development :'),

        _fieldLabel('Training Courses :'),
        _buildTextField(hint: 'Completed Courses', controller: _trainingCoursesController),
        SizedBox(height: 10.h),

        _fieldLabel('Compliance Training :'),
        _buildTextField(hint: 'Mandatory Compliance Training', controller: _complianceTrainingController),
      ],
    );
  }
}