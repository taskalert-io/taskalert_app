import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SectionValidatable.dart';

class AssetSystemSection extends StatefulWidget {
  const AssetSystemSection({super.key});
  @override
  State<AssetSystemSection> createState() => AssetSystemSectionState();
}

class AssetSystemSectionState extends State<AssetSystemSection>
    implements SectionValidatable {
  final TextEditingController _hardwareInventoryController =
      TextEditingController();
  final TextEditingController _serialMonitorsController =
      TextEditingController();
  final TextEditingController _serialPhonesController = TextEditingController();
  final TextEditingController _softwarePermissionsController =
      TextEditingController();
  final TextEditingController _securityClearanceController =
      TextEditingController();

  final FocusNode _hardwareInventoryFocus = FocusNode();
  final FocusNode _serialMonitorsFocus = FocusNode();
  final FocusNode _serialPhonesFocus = FocusNode();
  final FocusNode _softwarePermissionsFocus = FocusNode();
  final FocusNode _securityClearanceFocus = FocusNode();

  bool _isHardwareInventoryEditing = false;
  bool _isSerialMonitorsEditing = false;
  bool _isSerialPhonesEditing = false;
  bool _isSoftwarePermissionsEditing = false;
  bool _isSecurityClearanceEditing = false;

  String? _hardwareInventoryError;
  String? _serialMonitorsError;
  String? _serialPhonesError;
  String? _softwarePermissionsError;
  String? _securityClearanceError;

  @override
  void initState() {
    super.initState();
    _hardwareInventoryController.text = "2 Days";
    _serialMonitorsController.text = "1 Day";
    _serialPhonesController.text = "None";
    _softwarePermissionsController.text = "None";
    _securityClearanceController.text = "Editor";
  }

  @override
  void dispose() {
    _hardwareInventoryController.dispose();
    _serialMonitorsController.dispose();
    _serialPhonesController.dispose();
    _softwarePermissionsController.dispose();
    _securityClearanceController.dispose();
    _hardwareInventoryFocus.dispose();
    _serialMonitorsFocus.dispose();
    _serialPhonesFocus.dispose();
    _softwarePermissionsFocus.dispose();
    _securityClearanceFocus.dispose();
    super.dispose();
  }

  @override
  bool validate() {
    bool valid = true;
    setState(() {
      _hardwareInventoryError = _hardwareInventoryController.text.trim().isEmpty
          ? "Please enter hardware inventory"
          : null;
      _serialMonitorsError = _serialMonitorsController.text.trim().isEmpty
          ? "Please enter serial numbers for monitors"
          : null;
      _serialPhonesError = _serialPhonesController.text.trim().isEmpty
          ? "Please enter serial numbers for phones"
          : null;
      _softwarePermissionsError =
          _softwarePermissionsController.text.trim().isEmpty
          ? "Please enter software permissions"
          : null;
      _securityClearanceError = _securityClearanceController.text.trim().isEmpty
          ? "Please enter security clearance"
          : null;

      if (_hardwareInventoryError != null ||
          _serialMonitorsError != null ||
          _serialPhonesError != null ||
          _softwarePermissionsError != null ||
          _securityClearanceError != null) {
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
          enableInteractiveSelection: isEditing,
          showCursor: isEditing,
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
        _sectionHeading('Hardware Inventory'),
        _fieldLabel('Hardware Inventory', required: true),
        _buildTextField(
          controller: _hardwareInventoryController,
          isEditing: _isHardwareInventoryEditing,
          focusNode: _hardwareInventoryFocus,
          onEdit: () {
            if (!_isHardwareInventoryEditing)
              setState(() => _isHardwareInventoryEditing = true);
          },
          errorText: _hardwareInventoryError,
          onClearError: () => setState(
            () => _hardwareInventoryError =
                _hardwareInventoryController.text.trim().isEmpty
                ? "Please enter hardware inventory"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Serial Numbers for Monitors', required: true),
        _buildTextField(
          controller: _serialMonitorsController,
          isEditing: _isSerialMonitorsEditing,
          focusNode: _serialMonitorsFocus,
          onEdit: () {
            if (!_isSerialMonitorsEditing)
              setState(() => _isSerialMonitorsEditing = true);
          },
          errorText: _serialMonitorsError,
          onClearError: () => setState(
            () => _serialMonitorsError =
                _serialMonitorsController.text.trim().isEmpty
                ? "Please enter serial numbers for monitors"
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        _fieldLabel('Serial Numbers for Phones', required: true),
        _buildTextField(
          controller: _serialPhonesController,
          isEditing: _isSerialPhonesEditing,
          focusNode: _serialPhonesFocus,
          onEdit: () {
            if (!_isSerialPhonesEditing)
              setState(() => _isSerialPhonesEditing = true);
          },
          errorText: _serialPhonesError,
          onClearError: () => setState(
            () =>
                _serialPhonesError = _serialPhonesController.text.trim().isEmpty
                ? "Please enter serial numbers for phones"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Software Permissions'),
        _fieldLabel('Software Permissions', required: true),
        _buildTextField(
          controller: _softwarePermissionsController,
          isEditing: _isSoftwarePermissionsEditing,
          focusNode: _softwarePermissionsFocus,
          onEdit: () {
            if (!_isSoftwarePermissionsEditing)
              setState(() => _isSoftwarePermissionsEditing = true);
          },
          errorText: _softwarePermissionsError,
          onClearError: () => setState(
            () => _softwarePermissionsError =
                _softwarePermissionsController.text.trim().isEmpty
                ? "Please enter software permissions"
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        _sectionHeading('Security Clearance'),
        _fieldLabel('Security Clearance', required: true),
        _buildTextField(
          controller: _securityClearanceController,
          isEditing: _isSecurityClearanceEditing,
          focusNode: _securityClearanceFocus,
          onEdit: () {
            if (!_isSecurityClearanceEditing)
              setState(() => _isSecurityClearanceEditing = true);
          },
          errorText: _securityClearanceError,
          onClearError: () => setState(
            () => _securityClearanceError =
                _securityClearanceController.text.trim().isEmpty
                ? "Please enter security clearance"
                : null,
          ),
        ),
      ],
    );
  }
}
