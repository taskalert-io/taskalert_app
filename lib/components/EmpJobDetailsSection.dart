import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'SectionValidatable.dart';

class EmpJobDetailsSection extends StatefulWidget {
  const EmpJobDetailsSection({super.key});
  @override
  State<EmpJobDetailsSection> createState() => EmpJobDetailsSectionState();
}

class EmpJobDetailsSectionState extends State<EmpJobDetailsSection>
    implements SectionValidatable {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _shiftController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _whoReportsToController = TextEditingController();
  final TextEditingController _whoReportsThemController =
      TextEditingController();
  final TextEditingController _tenureController = TextEditingController();

  final FocusNode _jobTitleFocus = FocusNode();
  final FocusNode _departmentFocus = FocusNode();
  final FocusNode _shiftFocus = FocusNode();
  final FocusNode _hoursFocus = FocusNode();
  final FocusNode _reportToFocus = FocusNode();
  final FocusNode _reportThemFocus = FocusNode();
  final FocusNode _tenureFocus = FocusNode();

  bool _isJobTitleEditing = false;
  bool _isDepartmentEditing = false;
  bool _isShiftEditing = false;
  bool _isHoursEditing = false;
  bool _isReportToEditing = false;
  bool _isReportThemEditing = false;
  bool _isTenureEditing = false;

  String? _jobTitleError;
  String? _departmentError;
  String? _shiftError;
  String? _hoursError;
  String? _reportToError;
  String? _reportThemError;
  String? _tenureError;
  String? _employmentTypeError;
  String? _hireDateError;

  String? _selectedEmploymentType;
  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Intern',
    'Freelance',
  ];

  final TextEditingController _hireDayController = TextEditingController();
  final TextEditingController _hireMonthController = TextEditingController();
  final TextEditingController _hireYearController = TextEditingController();
  DateTime? _hireDate;

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
  }

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
    _jobTitleFocus.dispose();
    _departmentFocus.dispose();
    _shiftFocus.dispose();
    _hoursFocus.dispose();
    _reportToFocus.dispose();
    _reportThemFocus.dispose();
    _tenureFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _jobTitleError = _jobTitleController.text.trim().isEmpty
          ? "Please enter job title"
          : null;
      _departmentError = _departmentController.text.trim().isEmpty
          ? "Please enter department"
          : null;
      _employmentTypeError = _selectedEmploymentType == null
          ? "Please select employment type"
          : null;
      _shiftError = _shiftController.text.trim().isEmpty
          ? "Please enter shift"
          : null;
      _hoursError = _hoursController.text.trim().isEmpty
          ? "Please enter hours"
          : null;
      _reportToError = _whoReportsToController.text.trim().isEmpty
          ? "Please enter reporting manager"
          : null;
      _reportThemError = _whoReportsThemController.text.trim().isEmpty
          ? "Please enter team member"
          : null;
      _hireDateError = _hireDate == null ? "Please select hire date" : null;
      _tenureError = _tenureController.text.trim().isEmpty
          ? "Please enter tenure"
          : null;

      if (_jobTitleError != null ||
          _departmentError != null ||
          _employmentTypeError != null ||
          _shiftError != null ||
          _hoursError != null ||
          _reportToError != null ||
          _reportThemError != null ||
          _hireDateError != null ||
          _tenureError != null) {
        valid = false;
      }
    });
    return valid;
  }

  void _showEmploymentTypeBottomSheet(BuildContext context) {
    List<String> filtered = List.from(_employmentTypes);

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
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1F000000),
                  blurRadius: 10.r,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Employment Type",
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
                SizedBox(height: 12.h),
                TextField(
                  autofocus: true,
                  onChanged: (val) => ss(() {
                    filtered = _employmentTypes
                        .where(
                          (e) => e.toLowerCase().contains(
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
                    hintText: "Search type...",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFB8BEC5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
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
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No results found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isSel = item == _selectedEmploymentType;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () {
                                setState(() {
                                  _selectedEmploymentType = item;
                                  _employmentTypeError = null;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: isSel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSel
                                              ? const Color(0xFF0A0258)
                                              : const Color(0xFF344054),
                                        ),
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(
                                        Icons.check,
                                        size: 16.r,
                                        color: const Color(0xFF0A0258),
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
    );
  }

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
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: !isEditing,
          enableInteractiveSelection:
              isEditing, // ✅ no drag handle when readOnly
          showCursor: isEditing, // ✅ no cursor when readOnly
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
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

  Widget _buildDateRow() {
    const borderColor = Color(0xFFD9DEE5);
    void showPicker() {
      DateTime tempDate = _hireDate ?? DateTime.now();
      bool hasSelected = _hireDate != null;
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
                      initialSelectedDate: _hireDate,
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
                      onSelectionChanged: (args) {
                        if (args.value is DateTime) {
                          setModal(() {
                            tempDate = args.value;
                            hasSelected = true;
                          });
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
                          if (hasSelected) {
                            setState(() {
                              _hireDate = tempDate;

                              _hireDayController.text = tempDate.day
                                  .toString()
                                  .padLeft(2, '0');

                              _hireMonthController.text = tempDate.month
                                  .toString()
                                  .padLeft(2, '0');

                              _hireYearController.text = tempDate.year
                                  .toString();

                              _hireDateError = null;
                            });
                          }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                    border: Border.all(
                      color: _hireDateError != null ? Colors.red : borderColor,
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _hireDayController,
                      readOnly: true,
                      enableInteractiveSelection: false, // ✅
                      showCursor: false, // ✅
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF303030),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "dd",
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
            Expanded(
              child: GestureDetector(
                onTap: showPicker,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    border: Border(
                      top: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      bottom: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      right: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _hireMonthController,
                      readOnly: true,
                      enableInteractiveSelection: false, // ✅
                      showCursor: false, // ✅
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF303030),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "mm",
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
                    border: Border(
                      top: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      bottom: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      right: BorderSide(
                        color: _hireDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _hireYearController,
                      readOnly: true,
                      enableInteractiveSelection: false, // ✅
                      showCursor: false, // ✅
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF303030),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: "yyyy",
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
        ),
        if (_hireDateError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _hireDateError!,
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
        _sectionHeading('Employment & Job Details'),
        _fieldLabel('Job Title', required: true),
        _buildTextField(
          controller: _jobTitleController,
          isEditing: _isJobTitleEditing,
          focusNode: _jobTitleFocus,
          onEdit: () {
            if (!_isJobTitleEditing) setState(() => _isJobTitleEditing = true);
          },
          errorText: _jobTitleError,
          onClearError: () => setState(
            () => _jobTitleError = _jobTitleController.text.trim().isEmpty
                ? "Please enter job title"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Department', required: true),
        _buildTextField(
          controller: _departmentController,
          isEditing: _isDepartmentEditing,
          focusNode: _departmentFocus,
          onEdit: () {
            if (!_isDepartmentEditing)
              setState(() => _isDepartmentEditing = true);
          },
          errorText: _departmentError,
          onClearError: () => setState(
            () => _departmentError = _departmentController.text.trim().isEmpty
                ? "Please enter department"
                : null,
          ),
        ),
        SizedBox(height: 14.h),
        _sectionHeading('Employment Type'),
        GestureDetector(
          onTap: () => _showEmploymentTypeBottomSheet(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _employmentTypeError != null
                    ? Colors.red
                    : const Color(0xFFD9DEE5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedEmploymentType ?? 'Select type',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: _selectedEmploymentType == null
                          ? const Color(0xFFB8BEC5)
                          : const Color(0xFF6C7278),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF6C7278),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
        if (_employmentTypeError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _employmentTypeError!,
              style: GoogleFonts.inter(color: Colors.red, fontSize: 10.sp),
            ),
          ),
        SizedBox(height: 8.h),
        _sectionHeading('Work Schedule'),
        _fieldLabel('Shift', required: true),
        _buildTextField(
          controller: _shiftController,
          isEditing: _isShiftEditing,
          focusNode: _shiftFocus,
          onEdit: () {
            if (!_isShiftEditing) setState(() => _isShiftEditing = true);
          },
          errorText: _shiftError,
          onClearError: () => setState(
            () => _shiftError = _shiftController.text.trim().isEmpty
                ? "Please enter shift"
                : null,
          ),
        ),
        SizedBox(height: 8.h),
        _fieldLabel('Hours', required: true),
        _buildTextField(
          controller: _hoursController,
          isEditing: _isHoursEditing,
          focusNode: _hoursFocus,
          onEdit: () {
            if (!_isHoursEditing) setState(() => _isHoursEditing = true);
          },
          errorText: _hoursError,
          onClearError: () => setState(
            () => _hoursError = _hoursController.text.trim().isEmpty
                ? "Please enter hours"
                : null,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 8.h),
        _sectionHeading('Reporting Line'),
        _fieldLabel('Who They Report To', required: true),
        _buildTextField(
          controller: _whoReportsToController,
          isEditing: _isReportToEditing,
          focusNode: _reportToFocus,
          onEdit: () {
            if (!_isReportToEditing) setState(() => _isReportToEditing = true);
          },
          errorText: _reportToError,
          onClearError: () => setState(
            () => _reportToError = _whoReportsToController.text.trim().isEmpty
                ? "Please enter reporting manager"
                : null,
          ),
        ),
        SizedBox(height: 8.h),
        _fieldLabel('Who Reports To Them', required: true),
        _buildTextField(
          controller: _whoReportsThemController,
          isEditing: _isReportThemEditing,
          focusNode: _reportThemFocus,
          onEdit: () {
            if (!_isReportThemEditing)
              setState(() => _isReportThemEditing = true);
          },
          errorText: _reportThemError,
          onClearError: () => setState(
            () =>
                _reportThemError = _whoReportsThemController.text.trim().isEmpty
                ? "Please enter team member"
                : null,
          ),
        ),
        SizedBox(height: 8.h),
        _sectionHeading('Hire Date'),
        _buildDateRow(),
        SizedBox(height: 8.h),
        _sectionHeading('Tenure'),
        _buildTextField(
          controller: _tenureController,
          isEditing: _isTenureEditing,
          focusNode: _tenureFocus,
          onEdit: () {
            if (!_isTenureEditing) setState(() => _isTenureEditing = true);
          },
          errorText: _tenureError,
          onClearError: () => setState(
            () => _tenureError = _tenureController.text.trim().isEmpty
                ? "Please enter tenure"
                : null,
          ),
          keyboardType: TextInputType.number, // ✅
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // ✅
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
