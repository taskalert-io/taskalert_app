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
  bool empJobDetailsEnabled = false;
  bool cmpFinanceEnabled = false;
  bool skillPerformEnabled = false;
  bool timeAttendEnabled = false;
  bool assetSystemEnabled = false;
  bool dcmntComplianceEnabled = false;

  int selectedTab = 0;
  DateTime? _selectedDate;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  TextEditingController dayController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FocusNode dayFocus = FocusNode();
  final FocusNode monthFocus = FocusNode();
  final FocusNode yearFocus = FocusNode();
  bool isDayFocused = false;
  bool isMonthFocused = false;
  bool isYearFocused = false;
  bool isDobError = false;

  String selectedProofType = "";
  String selectedProofRadioType = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    dayController.text = now.day.toString().padLeft(2, '0');
    monthController.text = now.month.toString().padLeft(2, '0');
    yearController.text = now.year.toString();
  }

  @override
  void dispose() {
    _dateController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    dayFocus.dispose();
    monthFocus.dispose();
    yearFocus.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    setState(() {
      _autoValidate = true;
    });

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

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

  Widget buildTextField({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
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
        prefixIcon: prefix,
        suffixIcon: suffix,
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

  Widget get _editIcon => Padding(
    padding: const EdgeInsets.all(10),
    child: Icon(
      Icons.edit_outlined,
      size: 18.sp,
      color: const Color(0xFFB8BEC5),
    ),
  );

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

  Widget _buildMyProfileContent() {
    return SingleChildScrollView(
      // ✅ FIX: top padding gives room so shadow/border-radius is never cut off
      padding: EdgeInsets.only(left: 15.w, top: 16.h, bottom: 16.h, right: 15.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIX: removed clipBehavior — it was clipping the rounded corners during scroll
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
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
                padding: EdgeInsets.only(
                  left: 15.w,
                  top: 16.h,
                  right: 15.w,
                  bottom: 16.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading('Profile Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('First Name'),
                    SizedBox(height: 6.h),
                    buildTextField(
                      hint: 'Enter first name',
                      suffix: _editIcon,
                      controller: _firstNameController,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),

                    SizedBox(height: 8.h),

                    _fieldLabel('Last Name'),
                    SizedBox(height: 6.h),
                    buildTextField(
                      hint: 'Enter last name',
                      suffix: _editIcon,
                      controller: _lastNameController,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),

                    SizedBox(height: 10.h),

                    _sectionHeading('Contact Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('Email ID'),
                    SizedBox(height: 6.h),
                    buildTextField(
                      hint: 'Enter email address',
                      suffix: _editIcon,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
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
                    buildTextField(
                      hint: 'Enter phone number',
                      suffix: _editIcon,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\-\+\(\)]'),
                        ),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      controller: _phoneController,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      "Date of Birth",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                        color: const Color(0xFF6C7278),
                      ),
                    ),

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
                                    color: const Color(0xFF303030),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "Day",
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
                                    color: const Color(0xFF303030),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "Month",
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
                                    color: const Color(0xFF303030),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "Year",
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

            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Assignment & Recurrence",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: empJobDetailsEnabled,
                  onTap: () => setState(() {
                    empJobDetailsEnabled = !empJobDetailsEnabled;
                    if (empJobDetailsEnabled) cmpFinanceEnabled =false; dcmntComplianceEnabled =false; skillPerformEnabled = false; timeAttendEnabled = false; assetSystemEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (empJobDetailsEnabled)
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
                child: const EmpJobDetailsSection(),  // 👈 drop it right here
              ),

            SizedBox(height: 10.h),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The "Proof" & AI Validation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: cmpFinanceEnabled,
                  onTap: () => setState(() {
                    cmpFinanceEnabled = !cmpFinanceEnabled;
                    if (cmpFinanceEnabled) empJobDetailsEnabled = false; dcmntComplianceEnabled =false; skillPerformEnabled = false; timeAttendEnabled = false; assetSystemEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (cmpFinanceEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                  child: const CmpFinanceSection(),  // 👈 drop it right here
              ),
            SizedBox(height: 10.h),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The "Proof" & AI Validation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: dcmntComplianceEnabled,
                  onTap: () => setState(() {
                    dcmntComplianceEnabled = !dcmntComplianceEnabled;
                    if (dcmntComplianceEnabled) empJobDetailsEnabled = false; cmpFinanceEnabled =false; skillPerformEnabled = false; timeAttendEnabled = false; assetSystemEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (dcmntComplianceEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: const DcmntComplianceSection(),  // 👈 drop it right here
              ),

            SizedBox(height: 10.h),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The "Proof" & AI Validation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: skillPerformEnabled,
                  onTap: () => setState(() {
                    skillPerformEnabled = !skillPerformEnabled;
                    if (skillPerformEnabled) empJobDetailsEnabled = false; cmpFinanceEnabled =false; dcmntComplianceEnabled = false; timeAttendEnabled = false; assetSystemEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (skillPerformEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: const SkillPerformSection(),  // 👈 drop it right here
              ),
            SizedBox(height: 10.h),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The "Proof" & AI Validation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: timeAttendEnabled,
                  onTap: () => setState(() {
                    timeAttendEnabled = !timeAttendEnabled;
                    if (timeAttendEnabled) empJobDetailsEnabled = false; cmpFinanceEnabled =false; dcmntComplianceEnabled = false; skillPerformEnabled = false; assetSystemEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (timeAttendEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: const TimeAttendSection(),  // 👈 drop it right here
              ),
            SizedBox(height: 10.h),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The "Proof" & AI Validation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0258),
                  ),
                ),
                _buildToggle(
                  value: assetSystemEnabled,
                  onTap: () => setState(() {
                    assetSystemEnabled = !assetSystemEnabled;
                    if (assetSystemEnabled) empJobDetailsEnabled = false; cmpFinanceEnabled =false; dcmntComplianceEnabled = false; skillPerformEnabled = false; timeAttendEnabled = false;
                  }),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            if (assetSystemEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: const AssetSystemSection(),  // 👈 drop it right here
              ),

            SizedBox(height: 16.h),

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

  Widget _buildAccountSettingsContent() {
    return Center(
      child: Text(
        "Account Settings Content",
        style: GoogleFonts.inter(fontSize: 18.sp),
      ),
    );
  }

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
                            dialogSetState(() {
                              tempSelectedDate = args.value;
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
                            style: GoogleFonts.poppins(
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
                              dayController.text =
                                  tempSelectedDate.day.toString().padLeft(2, '0');
                              monthController.text =
                                  tempSelectedDate.month.toString().padLeft(2, '0');
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
              color: value ? const Color(0xFF1DC230) : const Color(0xFF676299),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: const Color(0xFF3F3F3F),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          TextSpan(text: " *", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildProofOption(String title, String value) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedProofType = selectedProofType == value ? "" : value;
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFF4338CA), width: 1.4),
              color: selectedProofType == value
                  ? const Color(0xFF24116A)
                  : Colors.transparent,
            ),
            child: selectedProofType == value
                ? Icon(Icons.check, size: 12.r, color: Colors.white)
                : null,
          ),
          SizedBox(width: 6.w),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProoftypeOption(String title, String value) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedProofRadioType = selectedProofRadioType == value ? "" : value;
      }),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4338CA), width: 1.3),
              ),
              child: Center(
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedProofRadioType == value
                        ? const Color(0xFF24116A)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                          backgroundImage: AssetImage(
                            'assets/images/profile.png',
                          ),
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
                        onPressed: () async => await _callPhone(),
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
                        onPressed: () async => await _sendEmail(),
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
                            child: _buildTab("My Profile", selectedTab == 0),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        GestureDetector(
                          onTap: () => setState(() => selectedTab = 1),
                          child: SizedBox(
                            width: 140.w,
                            child: _buildTab(
                              "Account Settings",
                              selectedTab == 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),

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