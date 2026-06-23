import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'SectionValidatable.dart';

class DcmntComplianceSection extends StatefulWidget {
  const DcmntComplianceSection({super.key});
  @override
  State<DcmntComplianceSection> createState() => DcmntComplianceSectionState();
}

class DcmntComplianceSectionState extends State<DcmntComplianceSection>
    implements SectionValidatable {
  final TextEditingController _ndasController = TextEditingController();
  final TextEditingController _employmentAgreementsController =
      TextEditingController();
  final TextEditingController _offerLettersController = TextEditingController();

  final FocusNode _ndasFocus = FocusNode();
  final FocusNode _employmentAgreementsFocus = FocusNode();
  final FocusNode _offerLettersFocus = FocusNode();

  bool _isNdasEditing = false;
  bool _isEmploymentAgreementsEditing = false;
  bool _isOfferLettersEditing = false;

  String? _ndasError;
  String? _employmentAgreementsError;
  String? _offerLettersError;
  String? _verificationStatusError;
  String? _verificationDateError;

  final List<_UploadedFile> _passportFiles = [];
  final List<_UploadedFile> _visaFiles = [];
  final List<_UploadedFile> _driversLicFiles = [];

  String? _verificationStatus;
  final List<String> _statuses = ['Approved', 'Pending', 'Rejected'];

  DateTime? _verificationDate;
  final TextEditingController _verDayController = TextEditingController();
  final TextEditingController _verMonthController = TextEditingController();
  final TextEditingController _verYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ndasController.text = "Business Negotiations";
    _employmentAgreementsController.text = "Yes";
    _offerLettersController.text = "Yes";
    _verificationDate = null;
  }

  @override
  void dispose() {
    _ndasController.dispose();
    _employmentAgreementsController.dispose();
    _offerLettersController.dispose();
    _verDayController.dispose();
    _verMonthController.dispose();
    _verYearController.dispose();
    _ndasFocus.dispose();
    _employmentAgreementsFocus.dispose();
    _offerLettersFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _ndasError = _ndasController.text.trim().isEmpty
          ? "Please enter NDAs"
          : null;
      _employmentAgreementsError =
          _employmentAgreementsController.text.trim().isEmpty
          ? "Please enter employment agreements"
          : null;
      _offerLettersError = _offerLettersController.text.trim().isEmpty
          ? "Please enter offer letters"
          : null;
      _verificationStatusError = _verificationStatus == null
          ? "Please select verification status"
          : null;
      _verificationDateError = _verificationDate == null
          ? "Please select verification date"
          : null;

      if (_ndasError != null ||
          _employmentAgreementsError != null ||
          _offerLettersError != null ||
          _verificationStatusError != null ||
          _verificationDateError != null) {
        valid = false;
      }
    });
    return valid;
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,

          readOnly: !isEditing,

          // FIX: same behavior as ProfileSetting
          enableInteractiveSelection: isEditing,
          showCursor: isEditing,

          onChanged: (_) {
            if (onClearError != null) {
              onClearError();
            }
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
                if (!isEditing) {
                  onEdit();
                }

                Future.microtask(() {
                  focusNode.requestFocus();
                });
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

  // ... keep all your existing _buildFileUploadSection, _buildFileTile, _addMockFile, _showVerificationDatePicker, _buildDateRow methods unchanged ...

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

  Widget _buildFileTile({
    required _UploadedFile file,
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
            onTap: onDelete,
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: Icon(Icons.delete_outline, size: 16.sp, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _addMockFile(List<_UploadedFile> list) {
    setState(() => list.add(_UploadedFile(name: 'Photo.jpg', size: '254 KB')));
  }

  void _showVerificationDatePicker(BuildContext context) {
    DateTime tempDate = _verificationDate ?? DateTime.now();
    bool hasSelected = _verificationDate != null;
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
                    initialSelectedDate: _verificationDate,
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
                        if (hasSelected) {
                          setState(() {
                            _verificationDate = tempDate;

                            _verDayController.text =
                                tempDate.day.toString().padLeft(2, '0');

                            _verMonthController.text =
                                tempDate.month.toString().padLeft(2, '0');

                            _verYearController.text =
                                tempDate.year.toString();

                            _verificationDateError = null;
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

  Widget _buildDateRow() {
    const borderColor = Color(0xFFD9DEE5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                    border: Border.all(
                      color: _verificationDateError != null
                          ? Colors.red
                          : borderColor,
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _verDayController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      showCursor: false,
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
                onTap: () => _showVerificationDatePicker(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    border: Border(
                      top: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      bottom: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      right: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _verMonthController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      showCursor: false,
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
                onTap: () => _showVerificationDatePicker(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      bottom: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                      right: BorderSide(
                        color: _verificationDateError != null
                            ? Colors.red
                            : borderColor,
                      ),
                    ),
                  ),
                  child: IgnorePointer(
                    child: TextField(
                      controller: _verYearController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      showCursor: false,
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
        if (_verificationDateError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _verificationDateError!,
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
        _sectionHeading('Signed Contracts'),
        _fieldLabel('NDAs', required: true),
        _buildTextField(
          controller: _ndasController,
          isEditing: _isNdasEditing,
          focusNode: _ndasFocus,
          onEdit: () {
            if (!_isNdasEditing) setState(() => _isNdasEditing = true);
          },
          errorText: _ndasError,
          onClearError: () => setState(
            () => _ndasError = _ndasController.text.trim().isEmpty
                ? "Please enter NDAs"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Employment Agreements', required: true),
        _buildTextField(
          controller: _employmentAgreementsController,
          isEditing: _isEmploymentAgreementsEditing,
          focusNode: _employmentAgreementsFocus,
          onEdit: () {
            if (!_isEmploymentAgreementsEditing) {
              setState(() => _isEmploymentAgreementsEditing = true);
            }
          },
          errorText: _employmentAgreementsError,
          onClearError: () => setState(
            () => _employmentAgreementsError =
                _employmentAgreementsController.text.trim().isEmpty
                ? "Please enter employment agreements"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Offer Letters', required: true),
        _buildTextField(
          controller: _offerLettersController,
          isEditing: _isOfferLettersEditing,
          focusNode: _offerLettersFocus,
          onEdit: () {
            if (!_isOfferLettersEditing) {
              setState(() => _isOfferLettersEditing = true);
            }
          },
          errorText: _offerLettersError,
          onClearError: () => setState(
            () =>
                _offerLettersError = _offerLettersController.text.trim().isEmpty
                ? "Please enter offer letters"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
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
        _sectionHeading('Background Checks'),
        _fieldLabel('Verification Status', required: true),
        DropdownButtonFormField<String>(
          value: _verificationStatus,
          hint: Text(
            'Select status',
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
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: _verificationStatusError != null
                    ? Colors.red
                    : const Color(0xFFD9DEE5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF0A0258)),
            ),
          ),
          items: _statuses
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() {
            _verificationStatus = v;
            _verificationStatusError = null;
          }),
        ),
        if (_verificationStatusError != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _verificationStatusError!,
              style: GoogleFonts.inter(color: Colors.red, fontSize: 10.sp),
            ),
          ),
        SizedBox(height: 10.h),
        _fieldLabel('Verification Date', required: true),
        _buildDateRow(),
      ],
    );
  }
}

class _UploadedFile {
  final String name;
  final String size;
  _UploadedFile({required this.name, required this.size});
}
