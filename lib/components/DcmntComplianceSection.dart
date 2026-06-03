import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class DcmntComplianceSection extends StatefulWidget {
  const DcmntComplianceSection({super.key});
  @override
  State<DcmntComplianceSection> createState() => _DcmntComplianceSectionState();
}

class _DcmntComplianceSectionState extends State<DcmntComplianceSection> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _ndasController                 = TextEditingController();
  final TextEditingController _employmentAgreementsController = TextEditingController();
  final TextEditingController _offerLettersController         = TextEditingController();

  // ── Editing states ─────────────────────────────────────────────────────────
  bool _isNdasEditing                 = false;
  bool _isEmploymentAgreementsEditing = false;
  bool _isOfferLettersEditing         = false;

  // ── Identification file lists ──────────────────────────────────────────────
  List<_UploadedFile> _passportFiles   = [];
  List<_UploadedFile> _visaFiles       = [];
  List<_UploadedFile> _driversLicFiles = [];

  // ── Background Checks ──────────────────────────────────────────────────────
  String? _verificationStatus;
  final List<String> _statuses = ['Approved', 'Pending', 'Rejected'];

  DateTime? _verificationDate;
  final TextEditingController _verDayController   = TextEditingController();
  final TextEditingController _verMonthController = TextEditingController();
  final TextEditingController _verYearController  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ndasController.text                 = "Business Negotiations";
    _employmentAgreementsController.text = "Yes";
    _offerLettersController.text         = "Yes";

    final now = DateTime.now();
    _verificationDate        = now;
    _verDayController.text   = now.day.toString().padLeft(2, '0');
    _verMonthController.text = now.month.toString().padLeft(2, '0');
    _verYearController.text  = now.year.toString();
  }

  @override
  void dispose() {
    _ndasController.dispose();
    _employmentAgreementsController.dispose();
    _offerLettersController.dispose();
    _verDayController.dispose();
    _verMonthController.dispose();
    _verYearController.dispose();
    super.dispose();
  }

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

  // ── Reusable text field (EmpJobDetailsSection pattern) ────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditing,
      keyboardType: keyboardType,
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
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
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

  // ── File upload section ────────────────────────────────────────────────────
  Widget _buildFileUploadSection({
    required String label,
    required List<_UploadedFile> files,
    required VoidCallback onAdd,
    required void Function(int) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        ...files.asMap().entries.map(
              (entry) => _buildFileTile(
            file: entry.value,
            onEdit: () {},
            onDelete: () => onDelete(entry.key),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFD9DEE5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 16.sp,
                  color: const Color(0xFFB8BEC5),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Tap to upload file',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFFB8BEC5),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  // ── Single file tile ───────────────────────────────────────────────────────
  Widget _buildFileTile({
    required _UploadedFile file,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFD9DEE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF4),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 20.sp,
              color: const Color(0xFF0A0258),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF303030),
                  ),
                ),
                Text(
                  file.size,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: Icon(
                Icons.edit_outlined,
                size: 16.sp,
                color: const Color(0xFFB8BEC5),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: Icon(
                Icons.delete_outline,
                size: 16.sp,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mock file add ──────────────────────────────────────────────────────────
  void _addMockFile(List<_UploadedFile> list) {
    setState(() => list.add(_UploadedFile(name: 'Photo.jpg', size: '254 KB')));
  }

  // ── Verification date picker ───────────────────────────────────────────────
  void _showVerificationDatePicker(BuildContext context) {
    DateTime tempDate = _verificationDate ?? DateTime.now();
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
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r)),
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
                      onPressed: () => Navigator.pop(context),
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
                        setState(() {
                          _verificationDate        = tempDate;
                          _verDayController.text   = tempDate.day.toString().padLeft(2, '0');
                          _verMonthController.text = tempDate.month.toString().padLeft(2, '0');
                          _verYearController.text  = tempDate.year.toString();
                        });
                        Navigator.pop(context);
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

  // ── Date row ───────────────────────────────────────────────────────────────
  Widget _buildDateRow() {
    const borderColor = Color(0xFFD9DEE5);
    return Row(
      children: [
        // DAY
        Expanded(
          child: GestureDetector(
            onTap: () => _showVerificationDatePicker(context),
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
                  controller: _verDayController,
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
            onTap: () => _showVerificationDatePicker(context),
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
                  controller: _verMonthController,
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
            onTap: () => _showVerificationDatePicker(context),
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
                  controller: _verYearController,
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Signed Contracts ─────────────────────────────────────────────
        _sectionHeading('Signed Contracts'),

        _fieldLabel('NDAs'),
        _buildTextField(
          hint: 'Business Negotiations',
          controller: _ndasController,
          isEditing: _isNdasEditing,
          onEdit: () => setState(() => _isNdasEditing = !_isNdasEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Employment Agreements'),
        _buildTextField(
          hint: 'Yes',
          controller: _employmentAgreementsController,
          isEditing: _isEmploymentAgreementsEditing,
          onEdit: () => setState(
                  () => _isEmploymentAgreementsEditing = !_isEmploymentAgreementsEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Offer Letters'),
        _buildTextField(
          hint: 'Yes',
          controller: _offerLettersController,
          isEditing: _isOfferLettersEditing,
          onEdit: () =>
              setState(() => _isOfferLettersEditing = !_isOfferLettersEditing),
        ),
        SizedBox(height: 16.h),

        // ── Identification ───────────────────────────────────────────────
        _sectionHeading('Identification'),

        _buildFileUploadSection(
          label: 'Scans of Passports',
          files: _passportFiles,
          onAdd: () => _addMockFile(_passportFiles),
          onDelete: (i) => setState(() => _passportFiles.removeAt(i)),
        ),

        _buildFileUploadSection(
          label: 'Visas',
          files: _visaFiles,
          onAdd: () => _addMockFile(_visaFiles),
          onDelete: (i) => setState(() => _visaFiles.removeAt(i)),
        ),

        _buildFileUploadSection(
          label: "Driver's Licenses",
          files: _driversLicFiles,
          onAdd: () => _addMockFile(_driversLicFiles),
          onDelete: (i) => setState(() => _driversLicFiles.removeAt(i)),
        ),

        SizedBox(height: 6.h),

        // ── Background Checks ────────────────────────────────────────────
        _sectionHeading('Background Checks'),

        _fieldLabel('Verification Status'),
        DropdownButtonFormField<String>(
          value: _verificationStatus,
          hint: Text(
            'Approved',
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
            size: 20.sp,
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
          items: _statuses
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _verificationStatus = v),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Verification Date'),
        _buildDateRow(),
      ],
    );
  }
}

// ── Model ──────────────────────────────────────────────────────────────────
class _UploadedFile {
  final String name;
  final String size;
  _UploadedFile({required this.name, required this.size});
}