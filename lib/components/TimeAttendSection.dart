import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeAttendSection extends StatefulWidget {
  const TimeAttendSection({super.key});
  @override
  State<TimeAttendSection> createState() => _TimeAttendSectionState();
}

class _TimeAttendSectionState extends State<TimeAttendSection> {
  // Leave Balance
  final TextEditingController _partTimeOffController        = TextEditingController();
  final TextEditingController _sickLeaveController          = TextEditingController();
  final TextEditingController _otherLeaveController         = TextEditingController();

  // Attendance Logs
  final TextEditingController _checkInController            = TextEditingController();
  final TextEditingController _checkOutController           = TextEditingController();
  final TextEditingController _automatedActivityController  = TextEditingController();

  // Holiday Calendar
  final TextEditingController _regionalHolidaysController   = TextEditingController();
  final TextEditingController _officeLocationController     = TextEditingController();

  @override
  void dispose() {
    _partTimeOffController.dispose();
    _sickLeaveController.dispose();
    _otherLeaveController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _automatedActivityController.dispose();
    _regionalHolidaysController.dispose();
    _officeLocationController.dispose();
    super.dispose();
  }

  // ── Edit icon ──────────────────────────────────────────────────────────────
  Widget get _editIcon => Padding(
    padding: const EdgeInsets.all(10),
    child: Icon(Icons.edit_outlined, size: 18.sp, color: const Color(0xFFB8BEC5)),
  );

  // ── Section heading ────────────────────────────────────────────────────────
  Widget _sectionHeading(String title, {Widget? leading}) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      children: [
        if (leading != null) ...[leading, SizedBox(width: 6.w)],
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0A0258))),
      ],
    ),
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
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
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

  // ── Time picker ────────────────────────────────────────────────────────────
  Future<void> _pickTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0A0258),
            onPrimary: Colors.white,
            onSurface: Color(0xFF303030),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour   = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() => controller.text = '$hour:$minute$period');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Leave Balance ────────────────────────────────────────────────
        _sectionHeading('Leave Balance'),

        _fieldLabel('Part Time Off :'),
        _buildTextField(hint: '2 Days', controller: _partTimeOffController),
        SizedBox(height: 10.h),

        _fieldLabel('Sick Leave :'),
        _buildTextField(hint: '1 Day', controller: _sickLeaveController),
        SizedBox(height: 10.h),

        _fieldLabel('Other :'),
        _buildTextField(hint: 'None', controller: _otherLeaveController),
        SizedBox(height: 16.h),

        // ── Attendance Logs ──────────────────────────────────────────────
        _sectionHeading('Attendance Logs :'),

        _fieldLabel('Check in Stamps :'),
        _buildTextField(
          hint: '9:00AM',
          controller: _checkInController,
          readOnly: true,
          onTap: () => _pickTime(context, _checkInController),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Check Out Stamps :'),
        _buildTextField(
          hint: '6:00PM',
          controller: _checkOutController,
          readOnly: true,
          onTap: () => _pickTime(context, _checkOutController),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Automated Activity Logs :'),
        _buildTextField(hint: 'Available', controller: _automatedActivityController),
        SizedBox(height: 16.h),

        // ── Holiday Calendar ─────────────────────────────────────────────
        _sectionHeading(
          'Holiday Calendar :',
          leading: Icon(Icons.calendar_month_outlined, size: 16.sp, color: const Color(0xFF0A0258)),
        ),

        _buildTextField(hint: 'Regional Holidays', controller: _regionalHolidaysController),
        SizedBox(height: 10.h),

        _buildTextField(hint: 'Office Location', controller: _officeLocationController),
      ],
    );
  }
}