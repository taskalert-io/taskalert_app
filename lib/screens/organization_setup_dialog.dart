import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Replace this import with your actual SignInScreen import path
import 'SignInScreen.dart';

class OrganizationSetupDialog extends StatefulWidget {
  const OrganizationSetupDialog({super.key});

  @override
  State<OrganizationSetupDialog> createState() =>
      _OrganizationSetupDialogState();
}

class _OrganizationSetupDialogState extends State<OrganizationSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;

  // ✅ Tracks whether the user has attempted to submit at least once.
  // Before first submit: no errors shown.
  // After first submit: errors show and clear in real-time as user fixes them.
  bool _autoValidate = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Shows a warning snackbar — does NOT close the dialog.
  void _onClosePressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Please complete the organization setup or logout to exit.",
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0258),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Confirms logout, clears storage, navigates to SignInScreen.
  Future<void> _onLogoutPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          "Logout?",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to logout? You will need to sign in again.",
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: const Color(0xFF6C7278),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C7278),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Logout",
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

    if (confirmed == true && mounted) {
      await _secureStorage.deleteAll();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SignInScreen()),
        (route) => false,
      );
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        color: const Color(0xFFB8BEC5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      errorStyle: TextStyle(fontSize: 10.sp, height: 1.2),
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
    );
  }

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onClosePressed();
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              child: Form(
                key: _formKey,
                // ✅ After first submit attempt, validate in real-time so
                // errors disappear the moment the user fixes each field.
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ──────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Set up your organization",
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                "Fill in your details to get started.",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // X button — shows warning, does NOT close
                        GestureDetector(
                          onTap: _onClosePressed,
                          child: Icon(
                            Icons.close,
                            size: 20.r,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // ── Organization Name ────────────────────────────
                    _label("Organization Name"),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: _orgNameController,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF6C7278),
                      ),
                      decoration: _fieldDecoration("Organization Name"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Enter organization name";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 12.h),

                    // ── Phone + Email row ────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Phone"),
                              SizedBox(height: 4.h),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6C7278),
                                ),
                                decoration: _fieldDecoration("Phone Number"),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Enter phone";
                                  }
                                  if (v.length != 10) {
                                    return "10 digits required";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 10.w),

                        // Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Email"),
                              SizedBox(height: 4.h),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-z0-9@._]'),
                                  ),
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6C7278),
                                ),
                                decoration: _fieldDecoration("Email"),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Enter email";
                                  }
                                  if (!RegExp(
                                    r'^[a-z0-9._]+@[a-z0-9]+\.[a-z]{2,}$',
                                  ).hasMatch(v.trim())) {
                                    return "Invalid email";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // ── Concierge banner ─────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 28.r,
                            color: const Color(0xFF0A0258),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Need help setting up?",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0A0258),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  "Our concierge team can help migrate your data in 24 hours.",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6C7278),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // ── Buttons row ──────────────────────────────────
                    Row(
                      children: [
                        // Create Organization
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    // ✅ Enable real-time validation on first submit tap
                                    setState(() => _autoValidate = true);

                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    // TODO: Replace with your actual API call
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );

                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    // ✅ Mark org setup as done so dialog never shows again
                                    await _secureStorage.write(
                                      key: 'org_setup_done',
                                      value: 'true',
                                    );
                                    // Only closes dialog after successful submission
                                    Navigator.pop(context, {
                                      'orgName': _orgNameController.text.trim(),
                                      'phone': _phoneController.text.trim(),
                                      'email': _emailController.text.trim(),
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          const Color(
                                            0xFF98E0D5,
                                          ).withOpacity(0.5),
                                          const Color(
                                            0xFFE49AEF,
                                          ).withOpacity(0.5),
                                        ]
                                      : const [
                                          Color(0xFF98E0D5),
                                          Color(0xFFE49AEF),
                                        ],
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 16.w,
                                        width: 16.w,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Create Organization",
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10.w),

                        // Logout
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _onLogoutPressed,
                            icon: Icon(
                              Icons.logout_rounded,
                              size: 16.r,
                              color: Colors.red,
                            ),
                            label: Text(
                              "Logout",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
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
        ),
      ),
    );
  }
}
