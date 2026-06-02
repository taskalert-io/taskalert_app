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
  // Salary / Rate
  final TextEditingController _basePayController           = TextEditingController();
  final TextEditingController _hourlyRateController        = TextEditingController();
  final TextEditingController _commissionController        = TextEditingController();

  // Bank Details
  final TextEditingController _accountHolderController    = TextEditingController();
  final TextEditingController _accountNumberController     = TextEditingController();
  final TextEditingController _branchNameController        = TextEditingController();
  final TextEditingController _ifscCodeController          = TextEditingController();

  // Tax Information
  final TextEditingController _taxIdController             = TextEditingController();
  final TextEditingController _ssnNumberController         = TextEditingController();
  final TextEditingController _panNumberController         = TextEditingController();

  // Benefits Enrollment
  final TextEditingController _healthInsuranceController   = TextEditingController();
  final TextEditingController _pensionDetailsController    = TextEditingController();

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

  // ── Edit icon ──────────────────────────────────────────────────────────────
  Widget get _editIcon => Padding(
    padding: const EdgeInsets.all(10),
    child: Icon(
      Icons.edit_outlined,
      size: 18.sp,
      color: const Color(0xFFB8BEC5),
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

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6C7278),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
        ),
        suffixIcon: _editIcon,
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
        _sectionHeading('Salary / Rate:'),

        _fieldLabel('Base Pay :'),
        _buildTextField(
          hint: 'Senior Backend Engineer',
          controller: _basePayController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Hourly Rate :'),
        _buildTextField(
          hint: 'Product',
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Commission Structure :'),
        _buildTextField(
          hint: 'Product',
          controller: _commissionController,
        ),
        SizedBox(height: 16.h),

        // ── Bank Details ─────────────────────────────────────────────────
        _sectionHeading('Bank Details :'),

        _fieldLabel('Account Holder Name :'),
        _buildTextField(
          hint: 'Amit Kumar Mondal',
          controller: _accountHolderController,
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Account Number :'),
        _buildTextField(
          hint: '123456456822',
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Branch Name'),
        _buildTextField(
          hint: 'New Alipore',
          controller: _branchNameController,
        ),
        SizedBox(height: 10.h),

        _fieldLabel('IFSC Code'),
        _buildTextField(
          hint: 'ABCN012345',
          controller: _ifscCodeController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Tax Information ──────────────────────────────────────────────
        _sectionHeading('Tax Information :'),

        _fieldLabel('Tax ID :'),
        _buildTextField(
          hint: 'Amit Kumar Mondal',
          controller: _taxIdController,
        ),
        SizedBox(height: 10.h),

        _fieldLabel('SSN Number :'),
        _buildTextField(
          hint: '123456456822',
          controller: _ssnNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: 10.h),

        _fieldLabel('PAN Number'),
        _buildTextField(
          hint: 'FBGN7502',
          controller: _panNumberController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Benefits Enrollment ──────────────────────────────────────────
        _sectionHeading('Benefits Enrollment :'),

        _fieldLabel('Health Insurance :'),
        _buildTextField(
          hint: 'Health Insurance Plans',
          controller: _healthInsuranceController,
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Pension Details :'),
        _buildTextField(
          hint: '401k/Pension Details',
          controller: _pensionDetailsController,
        ),
      ],
    );
  }
}