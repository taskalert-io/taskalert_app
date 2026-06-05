import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SectionValidatable.dart';

class TimeAttendSection extends StatefulWidget {
  const TimeAttendSection({super.key});
  @override
  State<TimeAttendSection> createState() => TimeAttendSectionState();
}

class TimeAttendSectionState extends State<TimeAttendSection>
    implements SectionValidatable {
  final TextEditingController _partTimeOffController = TextEditingController();
  final TextEditingController _sickLeaveController = TextEditingController();
  final TextEditingController _otherLeaveController = TextEditingController();
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  final TextEditingController _automatedActivityController = TextEditingController();
  final TextEditingController _regionalHolidaysController = TextEditingController();
  final TextEditingController _officeLocationController = TextEditingController();

  final FocusNode _partTimeOffFocus = FocusNode();
  final FocusNode _sickLeaveFocus = FocusNode();
  final FocusNode _otherLeaveFocus = FocusNode();
  final FocusNode _automatedActivityFocus = FocusNode();
  final FocusNode _regionalHolidaysFocus = FocusNode();
  final FocusNode _officeLocationFocus = FocusNode();

  bool _isPartTimeOffEditing = false;
  bool _isSickLeaveEditing = false;
  bool _isOtherLeaveEditing = false;
  bool _isAutomatedActivityEditing = false;
  bool _isRegionalHolidaysEditing = false;
  bool _isOfficeLocationEditing = false;

  String? _partTimeOffError;
  String? _sickLeaveError;
  String? _otherLeaveError;
  String? _checkInError;
  String? _checkOutError;
  String? _automatedActivityError;
  String? _regionalHolidaysError;
  String? _officeLocationError;

  @override
  void initState() {
    super.initState();
    _partTimeOffController.text = "2 Days";
    _sickLeaveController.text = "1 Day";
    _otherLeaveController.text = "None";
    _checkInController.text = "9:00AM";
    _checkOutController.text = "6:00PM";
    _automatedActivityController.text = "Available";
    _regionalHolidaysController.text = "Regional Holidays";
    _officeLocationController.text = "Office Location";
  }

  @override
  void dispose() {
    _partTimeOffController.dispose(); _sickLeaveController.dispose();
    _otherLeaveController.dispose(); _checkInController.dispose();
    _checkOutController.dispose(); _automatedActivityController.dispose();
    _regionalHolidaysController.dispose(); _officeLocationController.dispose();
    _partTimeOffFocus.dispose(); _sickLeaveFocus.dispose();
    _otherLeaveFocus.dispose(); _automatedActivityFocus.dispose();
    _regionalHolidaysFocus.dispose(); _officeLocationFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _partTimeOffError = _partTimeOffController.text.trim().isEmpty ? "Please enter part time off" : null;
      _sickLeaveError = _sickLeaveController.text.trim().isEmpty ? "Please enter sick leave" : null;
      _otherLeaveError = _otherLeaveController.text.trim().isEmpty ? "Please enter other leave" : null;
      _checkInError = _checkInController.text.trim().isEmpty ? "Please select check in time" : null;
      _checkOutError = _checkOutController.text.trim().isEmpty ? "Please select check out time" : null;
      _automatedActivityError = _automatedActivityController.text.trim().isEmpty ? "Please enter automated activity logs" : null;
      _regionalHolidaysError = _regionalHolidaysController.text.trim().isEmpty ? "Please enter regional holidays" : null;
      _officeLocationError = _officeLocationController.text.trim().isEmpty ? "Please enter office location" : null;

      if (_partTimeOffError != null || _sickLeaveError != null || _otherLeaveError != null ||
          _checkInError != null || _checkOutError != null || _automatedActivityError != null ||
          _regionalHolidaysError != null || _officeLocationError != null) {
        valid = false;
      }
    });
    return valid;
  }

  Widget _sectionHeading(String title, {Widget? leading}) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(children: [
      if (leading != null) ...[leading, SizedBox(width: 6.w)],
      Text(title, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0A0258))),
    ]),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller, focusNode: focusNode,
          readOnly: !isEditing, keyboardType: keyboardType,
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

  Widget _buildTimeField({
    required TextEditingController controller,
    String? errorText,
    VoidCallback? onClearError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller, readOnly: true,
          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF6C7278)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            suffixIcon: GestureDetector(
              onTap: () => _pickTime(context, controller, onClearError),
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

  Future<void> _pickTime(BuildContext context, TextEditingController controller, VoidCallback? onClearError) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF0A0258), onPrimary: Colors.white, onSurface: Color(0xFF303030))),
          child: child!),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        controller.text = '$hour:$minute $period';
        if (onClearError != null) onClearError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Leave Balance'),
        _fieldLabel('Part Time Off', required: true),
        _buildTextField(controller: _partTimeOffController, isEditing: _isPartTimeOffEditing, focusNode: _partTimeOffFocus,
            onEdit: () { if (!_isPartTimeOffEditing) setState(() => _isPartTimeOffEditing = true); },
            errorText: _partTimeOffError,
            onClearError: () => setState(() => _partTimeOffError = _partTimeOffController.text.trim().isEmpty ? "Please enter part time off" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Sick Leave', required: true),
        _buildTextField(controller: _sickLeaveController, isEditing: _isSickLeaveEditing, focusNode: _sickLeaveFocus,
            onEdit: () { if (!_isSickLeaveEditing) setState(() => _isSickLeaveEditing = true); },
            errorText: _sickLeaveError,
            onClearError: () => setState(() => _sickLeaveError = _sickLeaveController.text.trim().isEmpty ? "Please enter sick leave" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Other', required: true),
        _buildTextField(controller: _otherLeaveController, isEditing: _isOtherLeaveEditing, focusNode: _otherLeaveFocus,
            onEdit: () { if (!_isOtherLeaveEditing) setState(() => _isOtherLeaveEditing = true); },
            errorText: _otherLeaveError,
            onClearError: () => setState(() => _otherLeaveError = _otherLeaveController.text.trim().isEmpty ? "Please enter other leave" : null)),
        SizedBox(height: 16.h),
        _sectionHeading('Attendance Logs'),
        _fieldLabel('Check In Stamps', required: true),
        _buildTimeField(controller: _checkInController, errorText: _checkInError,
            onClearError: () => setState(() => _checkInError = _checkInController.text.trim().isEmpty ? "Please select check in time" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Check Out Stamps', required: true),
        _buildTimeField(controller: _checkOutController, errorText: _checkOutError,
            onClearError: () => setState(() => _checkOutError = _checkOutController.text.trim().isEmpty ? "Please select check out time" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Automated Activity Logs', required: true),
        _buildTextField(controller: _automatedActivityController, isEditing: _isAutomatedActivityEditing, focusNode: _automatedActivityFocus,
            onEdit: () { if (!_isAutomatedActivityEditing) setState(() => _isAutomatedActivityEditing = true); },
            errorText: _automatedActivityError,
            onClearError: () => setState(() => _automatedActivityError = _automatedActivityController.text.trim().isEmpty ? "Please enter automated activity logs" : null)),
        SizedBox(height: 16.h),
        _sectionHeading('Holiday Calendar',
            leading: Icon(Icons.calendar_month_outlined, size: 16.sp, color: const Color(0xFF0A0258))),
        _fieldLabel('Regional Holidays', required: true),
        _buildTextField(controller: _regionalHolidaysController, isEditing: _isRegionalHolidaysEditing, focusNode: _regionalHolidaysFocus,
            onEdit: () { if (!_isRegionalHolidaysEditing) setState(() => _isRegionalHolidaysEditing = true); },
            errorText: _regionalHolidaysError,
            onClearError: () => setState(() => _regionalHolidaysError = _regionalHolidaysController.text.trim().isEmpty ? "Please enter regional holidays" : null)),
        SizedBox(height: 10.h),
        _fieldLabel('Office Location', required: true),
        _buildTextField(controller: _officeLocationController, isEditing: _isOfficeLocationEditing, focusNode: _officeLocationFocus,
            onEdit: () { if (!_isOfficeLocationEditing) setState(() => _isOfficeLocationEditing = true); },
            errorText: _officeLocationError,
            onClearError: () => setState(() => _officeLocationError = _officeLocationController.text.trim().isEmpty ? "Please enter office location" : null)),
      ],
    );
  }
}