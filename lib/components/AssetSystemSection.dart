import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AssetSystemSection extends StatefulWidget {
  const AssetSystemSection({super.key});
  @override
  State<AssetSystemSection> createState() => _AssetSystemSectionState();
}

class _AssetSystemSectionState extends State<AssetSystemSection> {
  // Leave Balance (Asset)
  final TextEditingController _hardwareInventoryController     = TextEditingController();
  final TextEditingController _serialMonitorsController        = TextEditingController();
  final TextEditingController _serialPhonesController          = TextEditingController();

  // Software Permissions
  final TextEditingController _softwarePermissionsController   = TextEditingController();

  // Security Clearance
  final TextEditingController _securityClearanceController     = TextEditingController();

  @override
  void dispose() {
    _hardwareInventoryController.dispose();
    _serialMonitorsController.dispose();
    _serialPhonesController.dispose();
    _softwarePermissionsController.dispose();
    _securityClearanceController.dispose();
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
    child: Text(
      title,
      style: GoogleFonts.inter(
          fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0A0258)),
    ),
  );

  // ── Field label ────────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      label,
      style: GoogleFonts.inter(
          fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF303030)),
    ),
  );

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
          fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFF6C7278)),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFFB8BEC5)),
        suffixIcon: _editIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFF0A0258))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Leave Balance (Hardware) ─────────────────────────────────────
        _sectionHeading('Leave Balance'),

        _fieldLabel('Hardware Inventory :'),
        _buildTextField(hint: '2 Days', controller: _hardwareInventoryController),
        SizedBox(height: 10.h),

        _fieldLabel('Serial Numbers for Monitors :'),
        _buildTextField(hint: '1 Day', controller: _serialMonitorsController),
        SizedBox(height: 10.h),

        _fieldLabel('Serial Numbers for Phones : :'),
        _buildTextField(hint: 'None', controller: _serialPhonesController),
        SizedBox(height: 16.h),

        // ── Software Permissions ─────────────────────────────────────────
        _sectionHeading('Software Permissions :'),

        _buildTextField(hint: 'None', controller: _softwarePermissionsController),
        SizedBox(height: 16.h),

        // ── Security Clearance ───────────────────────────────────────────
        _sectionHeading('Security Clearance'),

        _buildTextField(hint: 'Editor', controller: _securityClearanceController),
      ],
    );
  }
}