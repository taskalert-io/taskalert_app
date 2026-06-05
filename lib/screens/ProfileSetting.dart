import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/AssetSystemSection.dart';
import '../components/CmpFinanceSection.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../components/DcmntComplianceSection.dart';
import '../components/EmpJobDetailsSection.dart';
import '../components/SkillPerformSection.dart';
import '../components/TimeAttendSection.dart';

class ProfileSetting extends StatefulWidget {
  final String userId;
  const ProfileSetting({super.key, required this.userId});
  @override
  State<StatefulWidget> createState() => ProfileSettingState();
}

class ProfileSettingState extends State<ProfileSetting>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final TextEditingController _dateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  // ── Editing states (mirrors EmpJobDetailsSection pattern) ─────────────────
  bool _isFirstNameEditing = false;
  bool _isLastNameEditing = false;
  bool _isEmailEditing = false;
  bool _isPhoneEditing = false;

  // ── Section toggles ────────────────────────────────────────────────────────
  bool empJobDetailsEnabled = false;
  bool cmpFinanceEnabled = false;
  bool skillPerformEnabled = false;
  bool timeAttendEnabled = false;
  bool assetSystemEnabled = false;
  bool dcmntComplianceEnabled = false;

  int selectedTab = 0;
  DateTime? _selectedDate;

  // ── Profile controllers ────────────────────────────────────────────────────
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // ── DOB controllers ────────────────────────────────────────────────────────
  final TextEditingController dayController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  bool isDobError = false;

  // ── Account Settings controllers & states ──────────────────────────────────
  final TextEditingController _accountEmailController    = TextEditingController();
  final TextEditingController _accountPasswordController = TextEditingController();
  bool _isAccountEmailEditing    = false;
  bool _isAccountPasswordEditing = false;
  bool _isTwoStepEnabled         = true;
  bool _isSupportAccessEnabled   = true;

  String selectedProofType = "";
  String selectedProofRadioType = "";

  String? _selectedLanguage;
  final List<String> _languages = [
    'English', 'Hindi', 'Bengali', 'Spanish', 'French', 'Arabic', 'Chinese',
  ];

  @override
  void initState() {
    super.initState();

    // Default DOB to today
    final now = DateTime.now();
    _selectedDate = now;
    dayController.text = now.day.toString().padLeft(2, '0');
    monthController.text = now.month.toString().padLeft(2, '0');
    yearController.text = now.year.toString();

    // Default profile values
    _firstNameController.text = "Michael";
    _lastNameController.text = "Smith";
    _emailController.text = "michaelsmith@gmail.com";
    _phoneController.text = "+14547260592";

    _accountEmailController.text    = "michael Smith@gmail.com";
    _accountPasswordController.text = "••••••••";
  }

  @override
  void dispose() {
    _dateController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    _accountEmailController.dispose();
    _accountPasswordController.dispose();

    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  void _submitForm() {
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill all required fields.",
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Form submitted successfully!",
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  // ── Tab pill ───────────────────────────────────────────────────────────────
  Widget _buildTab(String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? const Color(0xFF0A0258)
                  : const Color(0xFF8B8C8E),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          width: double.infinity,
          height: 3.h,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [
                Color(0xFFE040FB),
                Color(0xFF40C4FF),
                Color(0xFF64FFDA),
              ],
            )
                : null,
            color: isSelected ? null : const Color(0xFFE5E5E5),
          ),
        ),
      ],
    );
  }

  // ── Phone / Email launchers ────────────────────────────────────────────────
  Future<void> _callPhone() async {
    final Uri uri = Uri.parse('tel:+14547260592');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Phone error: $e');
    }
  }

  Future<void> _sendEmail() async {
    const String email = 'michaelsmith@gmail.com';
    const String subject = 'Hello';
    const String body = '';

    final Uri gmailUri = Uri.parse(
      'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri webGmail = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}',
        );
        await launchUrl(webGmail, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  // ── Reusable text field (exact EmpJobDetailsSection pattern) ───────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditing,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
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
        errorStyle: TextStyle(fontSize: 10.sp),
        // ── Edit / Done icon toggles exactly like EmpJobDetailsSection ──
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionHeading(String title) => Text(
    title,
    style: GoogleFonts.inter(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0A0258),
    ),
  );

  Widget _fieldLabel(String label) => Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 12.sp,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF303030),
    ),
  );

  // ── Toggle switch ──────────────────────────────────────────────────────────
  Widget _buildToggle({
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 30.w,
        height: 15.h,
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: value ? const Color(0xFF1DC230) : const Color(0xFF676299),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14.w,
            height: 14.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
              value ? const Color(0xFF1DC230) : const Color(0xFF676299),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section row (label + toggle + optional content) ───────────────────────
  Widget _buildSectionRow({
    required String label,
    required bool value,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        const Divider(height: 1, color: Color(0xFFE4E7EC)),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A0258),
              ),
            ),
            _buildToggle(value: value, onTap: onTap),
          ],
        ),
        SizedBox(height: 8.h),
        if (value)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withOpacity(0.06),
                  blurRadius: 24.r,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
      ],
    );
  }

  // ── Date picker bottom sheet ───────────────────────────────────────────────
  void _showDatePicker(BuildContext context) {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext builder) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return SafeArea(
              child: Container(
                height: 420,
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SfDateRangePicker(
                        initialSelectedDate: tempSelectedDate,
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
                            dialogSetState(
                                    () => tempSelectedDate = args.value);
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
                              _selectedDate = tempSelectedDate;
                              _dateController.text =
                              "${tempSelectedDate.day.toString().padLeft(2, '0')}-"
                                  "${tempSelectedDate.month.toString().padLeft(2, '0')}-"
                                  "${tempSelectedDate.year}";
                              dayController.text = tempSelectedDate.day
                                  .toString()
                                  .padLeft(2, '0');
                              monthController.text = tempSelectedDate.month
                                  .toString()
                                  .padLeft(2, '0');
                              yearController.text =
                                  tempSelectedDate.year.toString();
                              isDobError = false;
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
            );
          },
        );
      },
    );
  }

  // ── My Profile tab content ─────────────────────────────────────────────────
  Widget _buildMyProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 15.w,
        top: 16.h,
        bottom: 16.h,
        right: 15.w,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Details card ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15.w,
                  vertical: 16.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Details ──────────────────────────────
                    _sectionHeading('Profile Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('First Name'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter first name',
                      controller: _firstNameController,
                      isEditing: _isFirstNameEditing,
                      onEdit: () => setState(
                              () => _isFirstNameEditing = !_isFirstNameEditing),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 8.h),

                    _fieldLabel('Last Name'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter last name',
                      controller: _lastNameController,
                      isEditing: _isLastNameEditing,
                      onEdit: () => setState(
                              () => _isLastNameEditing = !_isLastNameEditing),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 10.h),

                    // ── Contact Details ──────────────────────────────
                    _sectionHeading('Contact Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('Email ID'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter email address',
                      controller: _emailController,
                      isEditing: _isEmailEditing,
                      onEdit: () =>
                          setState(() => _isEmailEditing = !_isEmailEditing),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(v)) return 'Invalid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 8.h),

                    _fieldLabel('Phone Number'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter phone number',
                      controller: _phoneController,
                      isEditing: _isPhoneEditing,
                      onEdit: () =>
                          setState(() => _isPhoneEditing = !_isPhoneEditing),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\-\+\(\)]'),
                        ),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 8.h),

                    // ── Date of Birth ────────────────────────────────
                    _fieldLabel('Date of Birth'),
                    SizedBox(height: 6.h),

                    Row(
                      children: [
                        // DAY
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showDatePicker(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8.r),
                                  bottomLeft: Radius.circular(8.r),
                                ),
                                border: Border.all(
                                  color: isDobError
                                      ? Colors.red
                                      : const Color(0xFFD9DEE5),
                                ),
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
                                    hintText: "Day",
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
                            onTap: () => _showDatePicker(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFC),
                                border: Border(
                                  top: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
                                  bottom: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
                                  right: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
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
                                    hintText: "Month",
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
                            onTap: () => _showDatePicker(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8.r),
                                  bottomRight: Radius.circular(8.r),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
                                  bottom: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
                                  right: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : const Color(0xFFD9DEE5),
                                  ),
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
                                    hintText: "Year",
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

                    if (isDobError)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 4),
                        child: Text(
                          "Please select date of birth",
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),

                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),

            // ── Expandable sections ────────────────────────────────────
            _buildSectionRow(
              label: "Employment & Job Details",
              value: empJobDetailsEnabled,
              onTap: () => setState(() {
                empJobDetailsEnabled = !empJobDetailsEnabled;
                if (empJobDetailsEnabled) {
                  cmpFinanceEnabled = false;
                  dcmntComplianceEnabled = false;
                  skillPerformEnabled = false;
                  timeAttendEnabled = false;
                  assetSystemEnabled = false;
                }
              }),
              child: const EmpJobDetailsSection(),
            ),

            _buildSectionRow(
              label: 'Compensation & Finance',
              value: cmpFinanceEnabled,
              onTap: () => setState(() {
                cmpFinanceEnabled = !cmpFinanceEnabled;
                if (cmpFinanceEnabled) {
                  empJobDetailsEnabled = false;
                  dcmntComplianceEnabled = false;
                  skillPerformEnabled = false;
                  timeAttendEnabled = false;
                  assetSystemEnabled = false;
                }
              }),
              child: const CmpFinanceSection(),
            ),

            _buildSectionRow(
              label: 'Skills & Performance',
              value: skillPerformEnabled,
              onTap: () => setState(() {
                skillPerformEnabled = !skillPerformEnabled;
                if (skillPerformEnabled) {
                  empJobDetailsEnabled = false;
                  cmpFinanceEnabled = false;
                  dcmntComplianceEnabled = false;
                  timeAttendEnabled = false;
                  assetSystemEnabled = false;
                }
              }),
              child: const SkillPerformSection(),
            ),

            _buildSectionRow(
              label: 'Time & Attendance',
              value: timeAttendEnabled,
              onTap: () => setState(() {
                timeAttendEnabled = !timeAttendEnabled;
                if (timeAttendEnabled) {
                  empJobDetailsEnabled = false;
                  cmpFinanceEnabled = false;
                  dcmntComplianceEnabled = false;
                  skillPerformEnabled = false;
                  assetSystemEnabled = false;
                }
              }),
              child: const TimeAttendSection(),
            ),

            _buildSectionRow(
              label: 'Assets & Systems',
              value: assetSystemEnabled,
              onTap: () => setState(() {
                assetSystemEnabled = !assetSystemEnabled;
                if (assetSystemEnabled) {
                  empJobDetailsEnabled = false;
                  cmpFinanceEnabled = false;
                  dcmntComplianceEnabled = false;
                  skillPerformEnabled = false;
                  timeAttendEnabled = false;
                }
              }),
              child: const AssetSystemSection(),
            ),

            _buildSectionRow(
              label: 'Document & Compliance',
              value: dcmntComplianceEnabled,
              onTap: () => setState(() {
                dcmntComplianceEnabled = !dcmntComplianceEnabled;
                if (dcmntComplianceEnabled) {
                  empJobDetailsEnabled = false;
                  cmpFinanceEnabled = false;
                  skillPerformEnabled = false;
                  timeAttendEnabled = false;
                  assetSystemEnabled = false;
                }
              }),
              child: const DcmntComplianceSection(),
            ),

            SizedBox(height: 16.h),

            // ── Save button ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 8.h,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Save Changes",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Account Settings tab ───────────────────────────────────────────────────
  Widget _buildAccountSettingsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 15.w,
        top: 16.h,
        bottom: 16.h,
        right: 15.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account Information card ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account Information ──────────────────────────────
                  Text(
                    'Account Information',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0258),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // ── Email ID ─────────────────────────────────────────
                  Text(
                    'Email ID',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF303030),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    hint: 'Enter email address',
                    controller: _accountEmailController,
                    isEditing: _isAccountEmailEditing,
                    onEdit: () => setState(
                          () => _isAccountEmailEditing = !_isAccountEmailEditing,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 10.h),

                  // ── Password ─────────────────────────────────────────
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF303030),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    hint: '••••••••',
                    controller: _accountPasswordController,
                    isEditing: _isAccountPasswordEditing,
                    onEdit: () => setState(
                          () => _isAccountPasswordEditing = !_isAccountPasswordEditing,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Divider ──────────────────────────────────────────
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  SizedBox(height: 16.h),

                  // ── 2-Step Verifications ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2 - Step Verifications',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Add an additional layer of security to your account during login.',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildToggle(
                        value: _isTwoStepEnabled,
                        onTap: () => setState(
                              () => _isTwoStepEnabled = !_isTwoStepEnabled,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  SizedBox(height: 16.h),

                  // ── Support Access ────────────────────────────────────
                  Text(
                    'Support Access',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0258),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Access',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF303030),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'You have granted us to access to your account for support purposes until Aug 31, 2026, 9:40 PM.',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildToggle(
                        value: _isSupportAccessEnabled,
                        onTap: () => setState(
                              () => _isSupportAccessEnabled = !_isSupportAccessEnabled,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  SizedBox(height: 16.h),

                  // ── Delete My Account ─────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete my account',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF303030),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Permanently delete the account and remove access from all workspaces.',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              title: Text(
                                'Delete Account',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF303030),
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to permanently delete your account? This action cannot be undone.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6C7278),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF6C7278),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Delete Account',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                  const Divider(height: 1, color: Color(0xFFE4E7EC)),
                  SizedBox(height: 16.h),

// ── Language Settings ─────────────────────────────────────────
                  Text(
                    'Language Settings',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3F3F3F),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  DropdownButtonFormField<String>(
                    value: _selectedLanguage ?? 'English',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF3F3F3F),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF6C7278),
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
                    items: _languages
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF3F3F3F),
                          ),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLanguage = v),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            SingleChildScrollView(
              child: Container(
                color: const Color(0xFFF5F7FB),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          size: 20.r,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ),

                    Center(
                      child: SizedBox(
                        width: 100.w,
                        height: 100.h,
                        child: const CircleAvatar(
                          backgroundImage:
                          AssetImage('assets/images/profile.png'),
                        ),
                      ),
                    ),

                    Center(
                      child: Text(
                        "Mr. Michel Smith",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),

                    Center(
                      child: TextButton(
                        onPressed: _callPhone,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          "(454) 726-0592",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0A0258),
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child: TextButton(
                        onPressed: _sendEmail,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          "michaelsmith@gmail.com",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0A0258),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => selectedTab = 0),
                          child: SizedBox(
                            width: 140.w,
                            child:
                            _buildTab("My Profile", selectedTab == 0),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        GestureDetector(
                          onTap: () => setState(() => selectedTab = 1),
                          child: SizedBox(
                            width: 140.w,
                            child: _buildTab(
                                "Account Settings", selectedTab == 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab body ──────────────────────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FB),
                child: selectedTab == 0
                    ? _buildMyProfileContent()
                    : _buildAccountSettingsContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}