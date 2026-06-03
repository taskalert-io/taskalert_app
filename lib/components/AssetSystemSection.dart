import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AssetSystemSection extends StatefulWidget {
  const AssetSystemSection({super.key});
  @override
  State<AssetSystemSection> createState() => _AssetSystemSectionState();
}

class _AssetSystemSectionState extends State<AssetSystemSection> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _hardwareInventoryController   = TextEditingController();
  final TextEditingController _serialMonitorsController      = TextEditingController();
  final TextEditingController _serialPhonesController        = TextEditingController();
  final TextEditingController _softwarePermissionsController = TextEditingController();
  final TextEditingController _securityClearanceController   = TextEditingController();

  // ── Editing states ─────────────────────────────────────────────────────────
  bool _isHardwareInventoryEditing   = false;
  bool _isSerialMonitorsEditing      = false;
  bool _isSerialPhonesEditing        = false;
  bool _isSoftwarePermissionsEditing = false;
  bool _isSecurityClearanceEditing   = false;

  @override
  void initState() {
    super.initState();
    _hardwareInventoryController.text   = "2 Days";
    _serialMonitorsController.text      = "1 Day";
    _serialPhonesController.text        = "None";
    _softwarePermissionsController.text = "None";
    _securityClearanceController.text   = "Editor";
  }

  @override
  void dispose() {
    _hardwareInventoryController.dispose();
    _serialMonitorsController.dispose();
    _serialPhonesController.dispose();
    _softwarePermissionsController.dispose();
    _securityClearanceController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Hardware Inventory ───────────────────────────────────────────
        _sectionHeading('Hardware Inventory'),

        _fieldLabel('Hardware Inventory'),
        _buildTextField(
          hint: '2 Days',
          controller: _hardwareInventoryController,
          isEditing: _isHardwareInventoryEditing,
          onEdit: () => setState(
                  () => _isHardwareInventoryEditing = !_isHardwareInventoryEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Serial Numbers for Monitors'),
        _buildTextField(
          hint: '1 Day',
          controller: _serialMonitorsController,
          isEditing: _isSerialMonitorsEditing,
          onEdit: () => setState(
                  () => _isSerialMonitorsEditing = !_isSerialMonitorsEditing),
        ),
        SizedBox(height: 10.h),

        _fieldLabel('Serial Numbers for Phones'),
        _buildTextField(
          hint: 'None',
          controller: _serialPhonesController,
          isEditing: _isSerialPhonesEditing,
          onEdit: () => setState(
                  () => _isSerialPhonesEditing = !_isSerialPhonesEditing),
        ),
        SizedBox(height: 16.h),

        // ── Software Permissions ─────────────────────────────────────────
        _sectionHeading('Software Permissions'),

        _buildTextField(
          hint: 'None',
          controller: _softwarePermissionsController,
          isEditing: _isSoftwarePermissionsEditing,
          onEdit: () => setState(
                  () => _isSoftwarePermissionsEditing = !_isSoftwarePermissionsEditing),
        ),
        SizedBox(height: 16.h),

        // ── Security Clearance ───────────────────────────────────────────
        _sectionHeading('Security Clearance'),

        _buildTextField(
          hint: 'Editor',
          controller: _securityClearanceController,
          isEditing: _isSecurityClearanceEditing,
          onEdit: () => setState(
                  () => _isSecurityClearanceEditing = !_isSecurityClearanceEditing),
        ),
      ],
    );
  }
}