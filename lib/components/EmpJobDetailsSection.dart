import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class EmpJobDetailsSection extends StatefulWidget {
  const EmpJobDetailsSection({super.key});
  @override
  State<EmpJobDetailsSection> createState() => _EmpJobDetailsSectionState();
}

class _EmpJobDetailsSectionState extends State<EmpJobDetailsSection> {
  // Controllers
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _shiftController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _whoReportsToController = TextEditingController();
  final TextEditingController _whoReportsThemController =
      TextEditingController();
  final TextEditingController _tenureController = TextEditingController();

  bool _isJobTitleEditing = false;
  bool _isDepartmentEditing = false;
  bool _isShiftEditing = false;
  bool _isHoursEditing = false;
  bool _isReportToEditing = false;
  bool _isReportThemEditing = false;
  bool _isTenureEditing = false;

  // Employment Type dropdown
  String? _selectedEmploymentType;
  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Intern',
    'Freelance',
  ];

  // Hire Date controllers
  final TextEditingController _hireDayController = TextEditingController();
  final TextEditingController _hireMonthController = TextEditingController();
  final TextEditingController _hireYearController = TextEditingController();
  DateTime? _hireDate;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _departmentController.dispose();
    _shiftController.dispose();
    _hoursController.dispose();
    _whoReportsToController.dispose();
    _whoReportsThemController.dispose();
    _tenureController.dispose();
    _hireDayController.dispose();
    _hireMonthController.dispose();
    _hireYearController.dispose();
    super.dispose();
  }

  // ── Field label ────────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF303030),
      ),
    ),
  );

  // ── Section heading ────────────────────────────────────────────────────────
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

  // ── Edit icon ──────────────────────────────────────────────────────────────
  Widget get _editIcon => Padding(
    padding: const EdgeInsets.all(10),
    child: Icon(
      Icons.edit_outlined,
      size: 18.sp,
      color: const Color(0xFFB8BEC5),
    ),
  );

  Widget get _titlePrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Title:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _departmentPrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Dept:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _shiftPrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Shift:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _hourPrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Hours:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _reportToPrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Manager:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _reportThemPrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Team:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  Widget get _tenurePrefix => Padding(
    padding: EdgeInsets.only(left: 12.w, right: 8.w),
    child: Text(
      "Years:",
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF303030),
      ),
    ),
  );

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditing,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6C7278),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
        suffixIcon: GestureDetector(
          onTap: onEdit,
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
    );
  }

  // ── Self-contained DD/MM/YYYY row with built-in date picker ───────────────
  Widget _buildDateRow({
    required TextEditingController dayController,
    required TextEditingController monthController,
    required TextEditingController yearController,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    const borderColor = Color(0xFFD9DEE5);

    void showPicker() {
      DateTime tempDate = selectedDate ?? DateTime.now();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setModal) => SafeArea(
            child: Container(
              height: 420,
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10.r,
                    spreadRadius: 2.r,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SfDateRangePicker(
                      initialSelectedDate: tempDate,
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
                          (DateRangePickerSelectionChangedArgs args) {
                            if (args.value is DateTime) {
                              setModal(() => tempDate = args.value);
                            }
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
                          onDateSelected(tempDate);

                          dayController.text = tempDate.day.toString().padLeft(
                            2,
                            '0',
                          );

                          monthController.text = tempDate.month
                              .toString()
                              .padLeft(2, '0');

                          yearController.text = tempDate.year.toString();

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

    return Row(
      children: [
        // DAY
        Expanded(
          child: GestureDetector(
            onTap: showPicker,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  bottomLeft: Radius.circular(8.r),
                ),
                border: Border.all(color: borderColor),
              ),
              child: IgnorePointer(
                child: TextField(
                  controller: dayController,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF303030),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "DD",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFB8BEC5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // MONTH
        Expanded(
          child: GestureDetector(
            onTap: showPicker,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFC),
                border: Border(
                  top: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                ),
              ),
              child: IgnorePointer(
                child: TextField(
                  controller: monthController,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF303030),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "MM",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFB8BEC5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // YEAR
        Expanded(
          child: GestureDetector(
            onTap: showPicker,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r),
                ),
                border: const Border(
                  top: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                ),
              ),
              child: IgnorePointer(
                child: TextField(
                  controller: yearController,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF303030),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "YYYY",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFB8BEC5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _jobTitleController.text = "Senior Backend Engineer";
    _departmentController.text = "Product";
    _shiftController.text = "Morning";
    _hoursController.text = "8";
    _whoReportsToController.text = "Amit Kumar Mondal";
    _whoReportsThemController.text = "Maulik Seith";
    _tenureController.text = "5";

    _hireDate = DateTime.now();

    _hireDayController.text =
        _hireDate!.day.toString().padLeft(2, '0');

    _hireMonthController.text =
        _hireDate!.month.toString().padLeft(2, '0');

    _hireYearController.text =
        _hireDate!.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Employment & Job Details ─────────────────────────────────────
        _sectionHeading('Employment & Job Details'),

        _fieldLabel('Job Title'),
        _buildTextField(
          controller: _jobTitleController,
          isEditing: _isJobTitleEditing,
          onEdit: () {
            setState(() {
              _isJobTitleEditing = true;
            });
          },
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Department'),
        _buildTextField(
          controller: _departmentController,
          isEditing: _isDepartmentEditing,
          onEdit: () {
            setState(() {
              _isDepartmentEditing = true;
            });
          },
        ),
        SizedBox(height: 14.h),

        // ── Employment Type ──────────────────────────────────────────────
        _sectionHeading('Employment Type'),

        DropdownButtonFormField<String>(
          value: _selectedEmploymentType,
          hint: Text(
            'Full-time',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF6C7278),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: const Color(0xFF6C7278),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFFB8BEC5),
            size: 18.sp,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
          ),
          items: _employmentTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedEmploymentType = v),
        ),
        SizedBox(height: 8.h),

        // ── Work Schedule ────────────────────────────────────────────────
        _sectionHeading('Work Schedule'),

        _fieldLabel('Shift'),
        _buildTextField(
          controller: _shiftController,
          isEditing: _isShiftEditing,
          onEdit: () {
            setState(() {
              _isShiftEditing = true;
            });
          },
        ),
        SizedBox(height: 8.h),

        _fieldLabel('Hours'),
        _buildTextField(
          controller: _hoursController,
          isEditing: _isHoursEditing,
          onEdit: () {
            setState(() {
              _isHoursEditing = true;
            });
          },
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        SizedBox(height: 8.h),

        // ── Reporting Line ───────────────────────────────────────────────
        _sectionHeading('Reporting Line'),

        _fieldLabel('Who They Report To'),
        _buildTextField(
          controller: _whoReportsToController,
          isEditing: _isReportToEditing,
          onEdit: () {
            setState(() {
              _isReportToEditing = true;
            });
          },
        ),
        SizedBox(height: 8.h),

        _fieldLabel('Who Reports To Them'),
        _buildTextField(
          controller: _whoReportsThemController,
          isEditing: _isReportThemEditing,
          onEdit: () {
            setState(() {
              _isReportThemEditing = true;
            });
          },
        ),
        SizedBox(height: 8.h),

        // ── Hire Date ────────────────────────────────────────────────────
        _sectionHeading('Hire Date'),
        _buildDateRow(
          dayController: _hireDayController,
          monthController: _hireMonthController,
          yearController: _hireYearController,
          selectedDate: _hireDate,
          onDateSelected: (date) => setState(() => _hireDate = date),
        ),
        SizedBox(height: 8.h),

        // ── Tenure ───────────────────────────────────────────────────────
        _sectionHeading('Tenure'),
        _buildTextField(
          controller: _tenureController,
          isEditing: _isTenureEditing,
          onEdit: () {
            setState(() {
              _isTenureEditing = true;
            });
          },
        ),
        SizedBox(height: 6.h),

        Text(
          'Used for calculating benefits and work anniversaries.',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
