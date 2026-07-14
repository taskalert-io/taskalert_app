import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:taskalert_app/core/features/auth/controllers/login_controller.dart';
import 'package:taskalert_app/utils/injection_container.dart';
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
import '../components/ToggleSwitch.dart';

class ProfileSetting extends StatefulWidget {
  final String userId;
  const ProfileSetting({super.key, required this.userId});
  @override
  State<StatefulWidget> createState() => ProfileSettingState();
}

class ProfileSettingState extends State<ProfileSetting> {
  // ── Constants ──────────────────────────────────────────────────────────────
  static const _primaryColor = Color(0xFF0A0258);
  static const _borderColor = Color(0xFFD9DEE5);
  static const _fillColor = Color(0xFFF9FAFC);
  static const _labelColor = Color(0xFF303030);
  static const _hintColor = Color(0xFFB8BEC5);
  static const _textColor = Color(0xFF6C7278);
  static const _dividerColor = Color(0xFFE4E7EC);
  static const _shadowBlack08 = Color(0x14000000); // black.withOpacity(0.08)
  static const _shadowBlack06 = Color(
    0x0F101828,
  ); // 0xFF101828.withOpacity(0.06)
  static const _shadowBlack012 = Color(0x1F000000); // black.withOpacity(0.12)
  static const _shadowBlack02 = Color(0x33000000); // black.withOpacity(0.2)

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final TextEditingController _dateController = TextEditingController();

  // ── Form Keys ──────────────────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _acFormKey = GlobalKey<FormState>();

  // ── Section GlobalKeys ─────────────────────────────────────────────────────
  final GlobalKey<EmpJobDetailsSectionState> _empKey = GlobalKey();
  final GlobalKey<CmpFinanceSectionState> _cmpKey = GlobalKey();
  final GlobalKey<SkillPerformSectionState> _skillKey = GlobalKey();
  final GlobalKey<TimeAttendSectionState> _timeKey = GlobalKey();
  final GlobalKey<AssetSystemSectionState> _assetKey = GlobalKey();
  final GlobalKey<DcmntComplianceSectionState> _dcmntKey = GlobalKey();

  bool _autoValidate = false;
  bool _acAutoValidate = false;

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _accountEmailFocus = FocusNode();
  final FocusNode _accountPasswordFocus = FocusNode();

  // ── Editing states ─────────────────────────────────────────────────────────
  bool _isFirstNameEditing = false;
  bool _isLastNameEditing = false;
  bool _isEmailEditing = false;
  bool _isPhoneEditing = false;
  bool _isAccountEmailEditing = false;
  bool _isAccountPasswordEditing = false;

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

  // ── Account Settings ───────────────────────────────────────────────────────
  final TextEditingController _accountEmailController = TextEditingController();
  final TextEditingController _accountPasswordController =
      TextEditingController();
  bool _isTwoStepEnabled = true;
  bool _isSupportAccessEnabled = true;

  String _selectedLanguage = "Select Language";
  String? _languageError;
  final List<String> _languages = [
    'English',
    'Hindi',
    'Bengali',
    'Spanish',
    'French',
    'Arabic',
    'Chinese',
  ];

  final _loginController = sl<LoginController>();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String userName = "User";
  String userPhone = "";
  String userEmail = "";
  String userThumbnail = "";

  Map<String, dynamic>? _employeeData;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstNameController.text = "";
        _lastNameController.text = "";
        _emailController.text = "";
        _phoneController.text = "";
        _accountEmailController.text = "";
        _accountPasswordController.text = "••••••••";

        _loginController.handleGetProfile();
        loadUserData();
      }
    });
  }

  Future<void> loadUserData() async {
    String? storedFirstName = await storage.read(key: "user_first_name");
    String? storedLastName = await storage.read(key: "user_last_name");
    String? storedName = (storedFirstName != null && storedLastName != null)
        ? "$storedFirstName $storedLastName"
        : null;
    String? storedEmail = await storage.read(key: "user_email");

    String? storedThumbnail = await storage.read(key: "user_avatar_thumbnail");
    String? storedPhoneNumber = await storage.read(key: "user_phone");

    String? storedDOB = await storage.read(key: "user_dob");

    DateTime dateTime = DateTime.parse(storedDOB!);

    String? storedJobRole = await storage.read(key: "user_job");
    String? storedDepartment = await storage.read(key: "user_department");

    setState(() {
      userName = storedName ?? "User";
      userEmail = storedEmail ?? "";
      userThumbnail = storedThumbnail ?? "assets/images/profile.png";
      userPhone = storedPhoneNumber ?? "";

      _firstNameController.text = storedFirstName ?? "";
      _lastNameController.text = storedLastName ?? "";
      _emailController.text = storedEmail ?? "";
      _phoneController.text = storedPhoneNumber ?? "";
      _accountEmailController.text = storedEmail ?? "";
      _selectedDate = dateTime;
      // dayController.text = dateTime.day;
      dayController.text = dateTime.day.toString().padLeft(2, '0');
      monthController.text = dateTime.month.toString().padLeft(2, '0');
      yearController.text = dateTime.year.toString();

      _employeeData = {
        // "id": employeeId ?? "",
        "designation": storedJobRole ?? "Not Assigned",
        "department": storedDepartment ?? "General",
      };

      isLoading = false;
    });
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
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _accountEmailFocus.dispose();
    _accountPasswordFocus.dispose();
    super.dispose();
  }

  // ── My Profile Submit ──────────────────────────────────────────────────────
  void _submitForm() {
    setState(() => _autoValidate = true);
    bool mainValid = _formKey.currentState!.validate();

    if (_selectedDate == null) {
      setState(() => isDobError = true);
      mainValid = false;
    }

    bool sectionsValid = true;
    if (empJobDetailsEnabled && !(_empKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }
    if (cmpFinanceEnabled && !(_cmpKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }
    if (skillPerformEnabled && !(_skillKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }
    if (timeAttendEnabled && !(_timeKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }
    if (assetSystemEnabled && !(_assetKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }
    if (dcmntComplianceEnabled && !(_dcmntKey.currentState?.validate() ?? true)) {
      sectionsValid = false;
    }

    if (!mainValid || !sectionsValid) {
      _showSnackBar("Please fill all required fields.", Colors.red);
      return;
    }
    _showSnackBar("Form submitted successfully!", Colors.green);
  }

  // ── Account Settings Submit ────────────────────────────────────────────────
  void _submitAcForm() {
    setState(() => _acAutoValidate = true);
    bool valid = _acFormKey.currentState!.validate();

    if (_selectedLanguage == "Select Language") {
      setState(() => _languageError = "Please select language");
      valid = false;
    } else {
      setState(() => _languageError = null);
    }

    if (!valid) {
      _showSnackBar("Please fill all required fields.", Colors.red);
      return;
    }
    _showSnackBar("Account settings saved successfully!", Colors.green);
  }

  // ── SnackBar helper ────────────────────────────────────────────────────────
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  // ── Language bottom sheet ──────────────────────────────────────────────────
  void _showLanguageBottomSheet(BuildContext context) {
    List<String> filtered = List.from(_languages);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: _shadowBlack012,
                  blurRadius: 10.r,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Language",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 20.r, color: _textColor),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                TextField(
                  autofocus: true,
                  onChanged: (val) => ss(() {
                    filtered = _languages
                        .where(
                          (e) => e.toLowerCase().contains(
                            val.toLowerCase().trim(),
                          ),
                        )
                        .toList();
                  }),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF344054),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "Search language...",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: _hintColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16.r,
                      color: const Color(0xFF4338CA),
                    ),
                    filled: true,
                    fillColor: _fillColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              "No results found",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _dividerColor),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isSel = item == _selectedLanguage;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = item;
                                  _languageError = null;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: isSel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSel
                                              ? _primaryColor
                                              : const Color(0xFF344054),
                                        ),
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(
                                        Icons.check,
                                        size: 16.r,
                                        color: _primaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
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
              color: isSelected ? _primaryColor : const Color(0xFF8B8C8E),
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
    try {
      await launchUrl(Uri.parse('tel:+14547260592'));
    } catch (e) {
      debugPrint('Phone error: $e');
    }
  }

  Future<void> _sendEmail() async {
    const email = 'michaelsmith@gmail.com';
    const subject = 'Hello';
    final gmailUri = Uri.parse(
      'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=',
    );
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': ''},
    );
    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse(
            'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isAccountField = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !isEditing,
      enableInteractiveSelection: isEditing,
      showCursor: isEditing,
      cursorColor: isEditing ? _primaryColor : Colors.transparent,
      cursorWidth: isEditing ? 2.0 : 0,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: (isAccountField ? _acAutoValidate : _autoValidate)
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: _textColor,
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
          color: _hintColor,
        ),
        errorStyle: TextStyle(fontSize: 10.sp),
        suffixIcon: GestureDetector(
          onTap: () {
            onEdit();
            Future.microtask(() => focusNode.requestFocus());
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.edit_outlined, size: 18.sp, color: _hintColor),
          ),
        ),
        filled: true,
        fillColor: _fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: _primaryColor),
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
      color: _primaryColor,
    ),
  );

  Widget _fieldLabel(String label) => Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 12.sp,
      fontWeight: FontWeight.w400,
      color: _labelColor,
    ),
  );

  // ── Section row ───────────────────────────────────────────────────────────
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
        const Divider(height: 1, color: _dividerColor),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
            ),
            ToggleSwitch(value: value, onTap: onTap, semanticLabel: label),
          ],
        ),
        SizedBox(height: 8.h),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Offstage(
            offstage: !value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: _shadowBlack06,
                    blurRadius: 24.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
      ],
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────
  Widget _buildSaveButton(VoidCallback onPressed) {
    return Row(
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
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
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
    );
  }

  // ── Date picker bottom sheet ───────────────────────────────────────────────
  void _showDatePicker(BuildContext context) {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now();
    bool hasSelected = _selectedDate != null;

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
                      color: _shadowBlack02,
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
                        initialSelectedDate: _selectedDate,
                        selectionMode: DateRangePickerSelectionMode.single,
                        view: DateRangePickerView.month,
                        allowViewNavigation: true,
                        showNavigationArrow: true,
                        backgroundColor: Colors.white,
                        selectionColor: _primaryColor,
                        todayHighlightColor: _primaryColor,
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
                                yearController.text = tempSelectedDate.year
                                    .toString();
                                isDobError = false;
                              });
                            }
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

  // ── My Profile tab ─────────────────────────────────────────────────────────
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: _shadowBlack08,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading('Profile Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('First Name'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter first name',
                      controller: _firstNameController,
                      isEditing: _isFirstNameEditing,
                      focusNode: _firstNameFocus,
                      onEdit: () {
                        if (!_isFirstNameEditing) {
                          setState(() => _isFirstNameEditing = true);
                        }
                      },
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
                      focusNode: _lastNameFocus,
                      onEdit: () {
                        if (!_isLastNameEditing) {
                          setState(() => _isLastNameEditing = true);
                        }
                      },
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 10.h),

                    _sectionHeading('Contact Details'),
                    SizedBox(height: 8.h),

                    _fieldLabel('Email ID'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter email address',
                      controller: _emailController,
                      isEditing: _isEmailEditing,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      onEdit: () {
                        if (!_isEmailEditing) {
                          setState(() => _isEmailEditing = true);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Invalid email';
                        }
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
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      onEdit: () {
                        if (!_isPhoneEditing) {
                          setState(() => _isPhoneEditing = true);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (v.trim().length < 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8.h),

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
                                color: _fillColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8.r),
                                  bottomLeft: Radius.circular(8.r),
                                ),
                                border: Border.all(
                                  color: isDobError ? Colors.red : _borderColor,
                                ),
                              ),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: dayController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  showCursor: false,
                                  cursorColor: Colors.transparent,
                                  cursorWidth: 0,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: _labelColor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "dd",
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: _hintColor,
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
                                color: _fillColor,
                                border: Border(
                                  top: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                  bottom: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                  right: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                ),
                              ),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: monthController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  showCursor: false,
                                  cursorColor: Colors.transparent,
                                  cursorWidth: 0,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: _labelColor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "mm",
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: _hintColor,
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
                                color: _fillColor,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8.r),
                                  bottomRight: Radius.circular(8.r),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                  bottom: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                  right: BorderSide(
                                    color: isDobError
                                        ? Colors.red
                                        : _borderColor,
                                  ),
                                ),
                              ),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: yearController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  showCursor: false,
                                  cursorColor: Colors.transparent,
                                  cursorWidth: 0,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: _labelColor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "yyyy",
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: _hintColor,
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
              child: EmpJobDetailsSection(
                key: _empKey,
                employeeData: _employeeData,
              ),
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
              child: CmpFinanceSection(key: _cmpKey),
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
              child: SkillPerformSection(key: _skillKey),
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
              child: TimeAttendSection(key: _timeKey),
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
              child: AssetSystemSection(key: _assetKey),
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
              child: DcmntComplianceSection(key: _dcmntKey),
            ),

            SizedBox(height: 16.h),
            _buildSaveButton(_submitForm),
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
      child: Form(
        key: _acFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: _shadowBlack08,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _fieldLabel('Email ID'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: 'Enter email address',
                      controller: _accountEmailController,
                      isEditing: _isAccountEmailEditing,
                      focusNode: _accountEmailFocus,
                      isAccountField: true,
                      keyboardType: TextInputType.emailAddress,
                      onEdit: () {
                        if (!_isAccountEmailEditing) {
                          setState(() => _isAccountEmailEditing = true);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),

                    _fieldLabel('Password'),
                    SizedBox(height: 6.h),
                    _buildTextField(
                      hint: '••••••••',
                      controller: _accountPasswordController,
                      isEditing: _isAccountPasswordEditing,
                      focusNode: _accountPasswordFocus,
                      isAccountField: true,
                      onEdit: () {
                        if (!_isAccountPasswordEditing) {
                          setState(() => _isAccountPasswordEditing = true);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 6) {
                          return 'Minimum 6 characters required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    const Divider(height: 1, color: _dividerColor),
                    SizedBox(height: 16.h),

                    // 2-Step
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
                                  color: _primaryColor,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Add an additional layer of security to your account during login.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        ToggleSwitch(
                          value: _isTwoStepEnabled,
                          semanticLabel: '2 - Step Verifications',
                          onTap: () => setState(
                            () => _isTwoStepEnabled = !_isTwoStepEnabled,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    const Divider(height: 1, color: _dividerColor),
                    SizedBox(height: 16.h),

                    Text(
                      'Support Access',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
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
                                  color: _labelColor,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'You have granted us to access to your account for support purposes until Aug 31, 2026, 9:40 PM.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        ToggleSwitch(
                          value: _isSupportAccessEnabled,
                          semanticLabel: 'Support Access',
                          onTap: () => setState(
                            () => _isSupportAccessEnabled =
                                !_isSupportAccessEnabled,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    const Divider(height: 1, color: _dividerColor),
                    SizedBox(height: 16.h),

                    // Delete Account
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
                                  color: _labelColor,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Permanently delete the account and remove access from all workspaces.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _textColor,
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
                                    color: _labelColor,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to permanently delete your account? This action cannot be undone.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: _textColor,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: _textColor,
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
                    const Divider(height: 1, color: _dividerColor),
                    SizedBox(height: 16.h),

                    Text(
                      'Language Settings',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3F3F3F),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    GestureDetector(
                      onTap: () => _showLanguageBottomSheet(context),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: _fillColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _languageError != null
                                ? Colors.red
                                : _borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedLanguage,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: _selectedLanguage == "Select Language"
                                      ? _hintColor
                                      : _textColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: _textColor,
                              size: 18.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_languageError != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: Text(
                          _languageError!,
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),
            _buildSaveButton(_submitAcForm),
          ],
        ),
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
      drawer: CustomDrawer(activeTile: "User", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF5F7FB),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                        color: _primaryColor,
                      ),
                    ),
                  ),

                  Center(
                    child: SizedBox(
                      width: 100.w,
                      height: 100.h,
                      child: CircleAvatar(
                        backgroundImage: userThumbnail.isNotEmpty
                            ? NetworkImage(userThumbnail)
                            : const AssetImage("assets/images/profile.png")
                                  as ImageProvider,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
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
                        "(+91) $userPhone",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
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
                        userEmail,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
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
                ],
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
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}
