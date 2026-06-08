import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SectionValidatable.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class CmpFinanceSection extends StatefulWidget {
  const CmpFinanceSection({super.key});
  @override
  State<CmpFinanceSection> createState() => CmpFinanceSectionState();
}

class CmpFinanceSectionState extends State<CmpFinanceSection>
    implements SectionValidatable {
  final TextEditingController _basePayController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _ssnNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _healthInsuranceController =
      TextEditingController();
  final TextEditingController _pensionDetailsController =
      TextEditingController();

  final FocusNode _basePayFocus = FocusNode();
  final FocusNode _hourlyRateFocus = FocusNode();
  final FocusNode _commissionFocus = FocusNode();
  final FocusNode _accountHolderFocus = FocusNode();
  final FocusNode _accountNumberFocus = FocusNode();
  final FocusNode _branchNameFocus = FocusNode();
  final FocusNode _ifscCodeFocus = FocusNode();
  final FocusNode _taxIdFocus = FocusNode();
  final FocusNode _ssnNumberFocus = FocusNode();
  final FocusNode _panNumberFocus = FocusNode();
  final FocusNode _healthInsuranceFocus = FocusNode();
  final FocusNode _pensionDetailsFocus = FocusNode();

  bool _isBasePayEditing = false;
  bool _isHourlyRateEditing = false;
  bool _isCommissionEditing = false;
  bool _isAccountHolderEditing = false;
  bool _isAccountNumberEditing = false;
  bool _isBranchNameEditing = false;
  bool _isIfscCodeEditing = false;
  bool _isTaxIdEditing = false;
  bool _isSsnNumberEditing = false;
  bool _isPanNumberEditing = false;
  bool _isHealthInsuranceEditing = false;
  bool _isPensionDetailsEditing = false;

  String? _basePayError;
  String? _hourlyRateError;
  String? _commissionError;
  String? _accountHolderError;
  String? _accountNumberError;
  String? _branchNameError;
  String? _ifscCodeError;
  String? _taxIdError;
  String? _ssnNumberError;
  String? _panNumberError;
  String? _healthInsuranceError;
  String? _pensionDetailsError;

  @override
  void initState() {
    super.initState();
    _basePayController.text = "85000";
    _hourlyRateController.text = "42";
    _commissionController.text = "10% on net sales";
    _accountHolderController.text = "Amit Kumar Mondal";
    _accountNumberController.text = "123456456822";
    _branchNameController.text = "New Alipore";
    _ifscCodeController.text = "ABCN012345";
    _taxIdController.text = "TX-998877";
    _ssnNumberController.text = "123456456822";
    _panNumberController.text = "FBGN7502";
    _healthInsuranceController.text = "Health Insurance Plans";
    _pensionDetailsController.text = "401k/Pension Details";
  }

  @override
  void dispose() {
    _basePayController.dispose();
    _hourlyRateController.dispose();
    _commissionController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _branchNameController.dispose();
    _ifscCodeController.dispose();
    _taxIdController.dispose();
    _ssnNumberController.dispose();
    _panNumberController.dispose();
    _healthInsuranceController.dispose();
    _pensionDetailsController.dispose();
    _basePayFocus.dispose();
    _hourlyRateFocus.dispose();
    _commissionFocus.dispose();
    _accountHolderFocus.dispose();
    _accountNumberFocus.dispose();
    _branchNameFocus.dispose();
    _ifscCodeFocus.dispose();
    _taxIdFocus.dispose();
    _ssnNumberFocus.dispose();
    _panNumberFocus.dispose();
    _healthInsuranceFocus.dispose();
    _pensionDetailsFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _basePayError = _basePayController.text.trim().isEmpty
          ? "Please enter base pay"
          : null;
      _hourlyRateError = _hourlyRateController.text.trim().isEmpty
          ? "Please enter hourly rate"
          : null;
      _commissionError = _commissionController.text.trim().isEmpty
          ? "Please enter commission structure"
          : null;
      _accountHolderError = _accountHolderController.text.trim().isEmpty
          ? "Please enter account holder name"
          : null;
      _accountNumberError = _accountNumberController.text.trim().isEmpty
          ? "Please enter account number"
          : null;
      _branchNameError = _branchNameController.text.trim().isEmpty
          ? "Please enter branch name"
          : null;
      _ifscCodeError = _ifscCodeController.text.trim().isEmpty
          ? "Please enter IFSC code"
          : null;
      _taxIdError = _taxIdController.text.trim().isEmpty
          ? "Please enter tax ID"
          : null;
      _ssnNumberError = _ssnNumberController.text.trim().isEmpty
          ? "Please enter SSN number"
          : null;

      // ✅ PAN validation — format: ABCDE1234F
      final pan = _panNumberController.text.trim();
      if (pan.isEmpty) {
        _panNumberError = "Please enter PAN number";
      } else if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
        _panNumberError = "Invalid PAN format (e.g. ABCDE1234F)";
      } else {
        _panNumberError = null;
      }

      _healthInsuranceError = _healthInsuranceController.text.trim().isEmpty
          ? "Please enter health insurance details"
          : null;
      _pensionDetailsError = _pensionDetailsController.text.trim().isEmpty
          ? "Please enter pension details"
          : null;

      if (_basePayError != null ||
          _hourlyRateError != null ||
          _commissionError != null ||
          _accountHolderError != null ||
          _accountNumberError != null ||
          _branchNameError != null ||
          _ifscCodeError != null ||
          _taxIdError != null ||
          _ssnNumberError != null ||
          _panNumberError != null ||
          _healthInsuranceError != null ||
          _pensionDetailsError != null) {
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
          keyboardType: keyboardType,
          enableInteractiveSelection:
              isEditing, // ✅ no drag handle when readOnly
          showCursor: isEditing, // ✅ no cursor when readOnly
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
        _sectionHeading('Salary / Rate'),
        _fieldLabel('Base Pay', required: true),
        _buildTextField(
          controller: _basePayController,
          isEditing: _isBasePayEditing,
          focusNode: _basePayFocus,
          onEdit: () {
            if (!_isBasePayEditing) setState(() => _isBasePayEditing = true);
          },
          errorText: _basePayError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onClearError: () => setState(
            () => _basePayError = _basePayController.text.trim().isEmpty
                ? "Please enter base pay"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Hourly Rate', required: true),
        _buildTextField(
          controller: _hourlyRateController,
          isEditing: _isHourlyRateEditing,
          focusNode: _hourlyRateFocus,
          onEdit: () {
            if (!_isHourlyRateEditing)
              setState(() => _isHourlyRateEditing = true);
          },
          errorText: _hourlyRateError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onClearError: () => setState(
            () => _hourlyRateError = _hourlyRateController.text.trim().isEmpty
                ? "Please enter hourly rate"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Commission Structure', required: true),
        _buildTextField(
          controller: _commissionController,
          isEditing: _isCommissionEditing,
          focusNode: _commissionFocus,
          onEdit: () {
            if (!_isCommissionEditing)
              setState(() => _isCommissionEditing = true);
          },
          errorText: _commissionError,
          onClearError: () => setState(
            () => _commissionError = _commissionController.text.trim().isEmpty
                ? "Please enter commission structure"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Bank Details'),
        _fieldLabel('Account Holder Name', required: true),
        _buildTextField(
          controller: _accountHolderController,
          isEditing: _isAccountHolderEditing,
          focusNode: _accountHolderFocus,
          onEdit: () {
            if (!_isAccountHolderEditing)
              setState(() => _isAccountHolderEditing = true);
          },
          errorText: _accountHolderError,
          onClearError: () => setState(
            () => _accountHolderError =
                _accountHolderController.text.trim().isEmpty
                ? "Please enter account holder name"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Account Number', required: true),
        _buildTextField(
          controller: _accountNumberController,
          isEditing: _isAccountNumberEditing,
          focusNode: _accountNumberFocus,
          onEdit: () {
            if (!_isAccountNumberEditing)
              setState(() => _isAccountNumberEditing = true);
          },
          errorText: _accountNumberError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onClearError: () => setState(
            () => _accountNumberError =
                _accountNumberController.text.trim().isEmpty
                ? "Please enter account number"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Branch Name', required: true),
        _buildTextField(
          controller: _branchNameController,
          isEditing: _isBranchNameEditing,
          focusNode: _branchNameFocus,
          onEdit: () {
            if (!_isBranchNameEditing)
              setState(() => _isBranchNameEditing = true);
          },
          errorText: _branchNameError,
          onClearError: () => setState(
            () => _branchNameError = _branchNameController.text.trim().isEmpty
                ? "Please enter branch name"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('IFSC Code', required: true),
        _buildTextField(
          controller: _ifscCodeController,
          isEditing: _isIfscCodeEditing,
          focusNode: _ifscCodeFocus,
          onEdit: () {
            if (!_isIfscCodeEditing) setState(() => _isIfscCodeEditing = true);
          },
          errorText: _ifscCodeError,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
            LengthLimitingTextInputFormatter(11),
          ],
          onClearError: () => setState(
            () => _ifscCodeError = _ifscCodeController.text.trim().isEmpty
                ? "Please enter IFSC code"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Tax Information'),
        _fieldLabel('Tax ID', required: true),
        _buildTextField(
          controller: _taxIdController,
          isEditing: _isTaxIdEditing,
          focusNode: _taxIdFocus,
          onEdit: () {
            if (!_isTaxIdEditing) setState(() => _isTaxIdEditing = true);
          },
          errorText: _taxIdError,
          onClearError: () => setState(
            () => _taxIdError = _taxIdController.text.trim().isEmpty
                ? "Please enter tax ID"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('SSN Number', required: true),
        _buildTextField(
          controller: _ssnNumberController,
          isEditing: _isSsnNumberEditing,
          focusNode: _ssnNumberFocus,
          onEdit: () {
            if (!_isSsnNumberEditing)
              setState(() => _isSsnNumberEditing = true);
          },
          errorText: _ssnNumberError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onClearError: () => setState(
            () => _ssnNumberError = _ssnNumberController.text.trim().isEmpty
                ? "Please enter SSN number"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('PAN Number', required: true),
        _buildTextField(
          controller: _panNumberController,
          isEditing: _isPanNumberEditing,
          focusNode: _panNumberFocus,
          onEdit: () {
            if (!_isPanNumberEditing)
              setState(() => _isPanNumberEditing = true);
          },
          errorText: _panNumberError,
          keyboardType: TextInputType.visiblePassword, // ✅ full keyboard
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9]'),
            ), // ✅ alphanumeric only
            LengthLimitingTextInputFormatter(10),
            UpperCaseTextFormatter(), // ✅ auto uppercase
          ],
          onClearError: () => setState(() {
            final pan = _panNumberController.text.trim();
            if (pan.isEmpty) {
              _panNumberError = "Please enter PAN number";
            } else if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
              _panNumberError = "Invalid PAN format (e.g. ABCDE1234F)";
            } else {
              _panNumberError = null;
            }
          }),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Benefits Enrollment'),
        _fieldLabel('Health Insurance', required: true),
        _buildTextField(
          controller: _healthInsuranceController,
          isEditing: _isHealthInsuranceEditing,
          focusNode: _healthInsuranceFocus,
          onEdit: () {
            if (!_isHealthInsuranceEditing)
              setState(() => _isHealthInsuranceEditing = true);
          },
          errorText: _healthInsuranceError,
          onClearError: () => setState(
            () => _healthInsuranceError =
                _healthInsuranceController.text.trim().isEmpty
                ? "Please enter health insurance details"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Pension Details', required: true),
        _buildTextField(
          controller: _pensionDetailsController,
          isEditing: _isPensionDetailsEditing,
          focusNode: _pensionDetailsFocus,
          onEdit: () {
            if (!_isPensionDetailsEditing)
              setState(() => _isPensionDetailsEditing = true);
          },
          errorText: _pensionDetailsError,
          onClearError: () => setState(
            () => _pensionDetailsError =
                _pensionDetailsController.text.trim().isEmpty
                ? "Please enter pension details"
                : null,
          ),
        ),
      ],
    );
  }
}
