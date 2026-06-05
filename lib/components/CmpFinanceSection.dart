import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CmpFinanceSection extends StatefulWidget {
  const CmpFinanceSection({super.key});
  @override
  State<CmpFinanceSection> createState() => _CmpFinanceSectionState();
}

class _CmpFinanceSectionState extends State<CmpFinanceSection> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _basePayController        = TextEditingController();
  final TextEditingController _hourlyRateController     = TextEditingController();
  final TextEditingController _commissionController     = TextEditingController();
  final TextEditingController _accountHolderController  = TextEditingController();
  final TextEditingController _accountNumberController  = TextEditingController();
  final TextEditingController _branchNameController     = TextEditingController();
  final TextEditingController _ifscCodeController       = TextEditingController();
  final TextEditingController _taxIdController          = TextEditingController();
  final TextEditingController _ssnNumberController      = TextEditingController();
  final TextEditingController _panNumberController      = TextEditingController();
  final TextEditingController _healthInsuranceController = TextEditingController();
  final TextEditingController _pensionDetailsController = TextEditingController();

  // ── Editing states ─────────────────────────────────────────────────────────
  bool _isBasePayEditing          = false;
  bool _isHourlyRateEditing       = false;
  bool _isCommissionEditing       = false;
  bool _isAccountHolderEditing    = false;
  bool _isAccountNumberEditing    = false;
  bool _isBranchNameEditing       = false;
  bool _isIfscCodeEditing         = false;
  bool _isTaxIdEditing            = false;
  bool _isSsnNumberEditing        = false;
  bool _isPanNumberEditing        = false;
  bool _isHealthInsuranceEditing  = false;
  bool _isPensionDetailsEditing   = false;

  @override
  void initState() {
    super.initState();
    _basePayController.text         = "85000";
    _hourlyRateController.text      = "42";
    _commissionController.text      = "10% on net sales";
    _accountHolderController.text   = "Amit Kumar Mondal";
    _accountNumberController.text   = "123456456822";
    _branchNameController.text      = "New Alipore";
    _ifscCodeController.text        = "ABCN012345";
    _taxIdController.text           = "TX-998877";
    _ssnNumberController.text       = "123456456822";
    _panNumberController.text       = "FBGN7502";
    _healthInsuranceController.text = "Health Insurance Plans";
    _pensionDetailsController.text  = "401k/Pension Details";
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Salary / Rate ────────────────────────────────────────────────
        _sectionHeading('Salary / Rate'),

        _fieldLabel('Base Pay'),
        _buildTextField(
          hint: '85000',
          controller: _basePayController,
          isEditing: _isBasePayEditing,
          onEdit: () => setState(() => _isBasePayEditing = !_isBasePayEditing),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Hourly Rate'),
        _buildTextField(
          hint: '42',
          controller: _hourlyRateController,
          isEditing: _isHourlyRateEditing,
          onEdit: () => setState(() => _isHourlyRateEditing = !_isHourlyRateEditing),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Commission Structure'),
        _buildTextField(
          hint: '10% on net sales',
          controller: _commissionController,
          isEditing: _isCommissionEditing,
          onEdit: () => setState(() => _isCommissionEditing = !_isCommissionEditing),
        ),
        SizedBox(height: 16.h),

        // ── Bank Details ─────────────────────────────────────────────────
        _sectionHeading('Bank Details'),

        _fieldLabel('Account Holder Name'),
        _buildTextField(
          hint: 'Amit Kumar Mondal',
          controller: _accountHolderController,
          isEditing: _isAccountHolderEditing,
          onEdit: () => setState(() => _isAccountHolderEditing = !_isAccountHolderEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Account Number'),
        _buildTextField(
          hint: '123456456822',
          controller: _accountNumberController,
          isEditing: _isAccountNumberEditing,
          onEdit: () => setState(() => _isAccountNumberEditing = !_isAccountNumberEditing),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Branch Name'),
        _buildTextField(
          hint: 'New Alipore',
          controller: _branchNameController,
          isEditing: _isBranchNameEditing,
          onEdit: () => setState(() => _isBranchNameEditing = !_isBranchNameEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('IFSC Code'),
        _buildTextField(
          hint: 'ABCN012345',
          controller: _ifscCodeController,
          isEditing: _isIfscCodeEditing,
          onEdit: () => setState(() => _isIfscCodeEditing = !_isIfscCodeEditing),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Tax Information ──────────────────────────────────────────────
        _sectionHeading('Tax Information'),

        _fieldLabel('Tax ID'),
        _buildTextField(
          hint: 'TX-998877',
          controller: _taxIdController,
          isEditing: _isTaxIdEditing,
          onEdit: () => setState(() => _isTaxIdEditing = !_isTaxIdEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('SSN Number'),
        _buildTextField(
          hint: '123456456822',
          controller: _ssnNumberController,
          isEditing: _isSsnNumberEditing,
          onEdit: () => setState(() => _isSsnNumberEditing = !_isSsnNumberEditing),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('PAN Number'),
        _buildTextField(
          hint: 'FBGN7502',
          controller: _panNumberController,
          isEditing: _isPanNumberEditing,
          onEdit: () => setState(() => _isPanNumberEditing = !_isPanNumberEditing),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Benefits Enrollment ──────────────────────────────────────────
        _sectionHeading('Benefits Enrollment'),

        _fieldLabel('Health Insurance'),
        _buildTextField(
          hint: 'Health Insurance Plans',
          controller: _healthInsuranceController,
          isEditing: _isHealthInsuranceEditing,
          onEdit: () => setState(() => _isHealthInsuranceEditing = !_isHealthInsuranceEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Pension Details'),
        _buildTextField(
          hint: '401k/Pension Details',
          controller: _pensionDetailsController,
          isEditing: _isPensionDetailsEditing,
          onEdit: () => setState(() => _isPensionDetailsEditing = !_isPensionDetailsEditing),
        ),
      ],
    );
  }
}