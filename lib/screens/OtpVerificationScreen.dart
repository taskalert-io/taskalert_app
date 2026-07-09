// ignore_for_file: use_build_context_synchronously, avoid_function_literals_in_foreach_calls, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/HomeScreen.dart';
import 'package:taskalert_app/screens/LoginConfirmationScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart';
import '../core/features/auth/controllers/login_controller.dart';
import '../core/features/auth/controllers/signup_controller.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isSignUpFlow;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? dateOfBirth;
  final String? password;
  final bool? agreeTerms;
  final String? accountType;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.isSignUpFlow,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.password,
    this.agreeTerms,
    this.accountType,
  });

  @override
  State<StatefulWidget> createState() => OtpVerificationScreenState();
}

class OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _loginController = sl<LoginController>();
  final _signupController = sl<SignUpController>();

  // ✅ Secure storage to write account_type after successful verification
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loginController.addListener(_onControllerChanged);
    startTimer();

    // Dev/test backends echo the generated OTP back in the response —
    // auto-fill it so the user doesn't have to type it in manually.
    _fillOtp(
      widget.isSignUpFlow ? _signupController.otp : _loginController.otp,
    );
  }

  @override
  void dispose() {
    _loginController.removeListener(_onControllerChanged);
    otpControllers.forEach((controller) => controller.dispose());
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _fillOtp(String? otp) {
    if (otp == null || otp.length != otpControllers.length) return;
    for (int i = 0; i < otpControllers.length; i++) {
      otpControllers[i].text = otp[i];
    }
    setState(() {});
  }

  int secondsRemaining = 60;
  Timer? timer;

  void startTimer() {
    timer?.cancel();
    setState(() {
      secondsRemaining = 60;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      if (secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          secondsRemaining = 0;
        });
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // TOP SECTION
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: const BoxDecoration(color: Color(0xFF12006C)),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // TOP RIGHT GLOW
                      Positioned(
                        top: -140.h,
                        left: -90.w,
                        right: -90.w,
                        child: IgnorePointer(
                          child: Container(
                            height: 260.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(260.r),
                                bottomRight: Radius.circular(260.r),
                              ),
                              gradient: RadialGradient(
                                center: Alignment.topCenter,
                                radius: 1.35.r,
                                colors: [
                                  const Color(0xFFEACAFF).withOpacity(0.95),
                                  const Color(0xFFEACAFF).withOpacity(0.45),
                                  const Color(0xFFEACAFF).withOpacity(0.12),
                                  Colors.transparent,
                                ],
                                stops: const [0.15, 0.45, 0.75, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 150,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/antprolgo.png",
                              fit: BoxFit.cover,
                              width: 200.w,
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Log in to your account",
                                style: GoogleFonts.inter(
                                  fontSize: 25.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFFFFF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Enter your OTP to sign in",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFFFFFFF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 45.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // OTP CARD
                Transform.translate(
                  offset: const Offset(0, -130),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20.r,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "OTP Verification",
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "Enter the one-time password sent to your\nregistered mobile number or email to securely\naccess your account.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF7B7B7B),
                          ),
                        ),
                        SizedBox(height: 22.h),

                        // OTP BOXES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            6,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (KeyEvent event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.backspace) {
                                      if (otpControllers[index].text.isEmpty &&
                                          index > 0) {
                                        otpFocusNodes[index - 1].requestFocus();
                                        otpControllers[index - 1].clear();
                                      }
                                    }
                                  },
                                  child: TextFormField(
                                    controller: otpControllers[index],
                                    focusNode: otpFocusNodes[index],
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                    ],
                                    maxLength: 1,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0A0258),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      isDense: true,
                                      filled: true,
                                      fillColor: const Color(0xFFF7F8FA),
                                      contentPadding: const EdgeInsets.only(
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD8DCE3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: const Color(0xFF0A0258),
                                          width: 1.2.w,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 5) {
                                        otpFocusNodes[index + 1].requestFocus();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // TIMER
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            secondsRemaining > 0
                                ? "00:${secondsRemaining.toString().padLeft(2, '0')} sec"
                                : "00:00 sec",
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF7B7B7B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // VERIFY BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _loginController.isLoading
                                ? null
                                : () async {
                                    bool isOtpComplete = otpControllers.every(
                                      (controller) =>
                                          controller.text.trim().isNotEmpty,
                                    );

                                    if (!isOtpComplete) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter complete OTP",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    String completeOtp = otpControllers
                                        .map((c) => c.text.trim())
                                        .join();

                                    final userModel = widget.isSignUpFlow
                                        ? await _signupController
                                              .handleVerifySignUpOtp(
                                                firstName:
                                                    widget.firstName ?? '',
                                                lastName: widget.lastName ?? '',
                                                password: widget.password ?? '',
                                                agreeTerms:
                                                    widget.agreeTerms ?? false,
                                                otpCode: completeOtp,
                                                email: widget.email ?? '',
                                                gender: widget.gender ?? '',
                                                dateOfBirth:
                                                    widget.dateOfBirth ?? '',
                                                accountType:
                                                    widget.accountType ?? '',
                                              )
                                        : await _loginController
                                              .handleVerifyOtp(
                                                otp: completeOtp,
                                              );

                                    if (!mounted) return;

                                    if (userModel != null) {
                                      // ✅ SIGN-UP FLOW:
                                      // account_type comes from widget.accountType
                                      // passed from SignUpScreen. Write it to
                                      // storage so HomeScreen can check it.
                                      if (widget.isSignUpFlow) {
                                        final accountType =
                                            widget.accountType ?? '';

                                        // Always save account_type for future logins
                                        await _secureStorage.write(
                                          key: 'account_type',
                                          value: accountType,
                                        );

                                        // Trigger org dialog on HomeScreen
                                        // only if org account
                                        if (accountType == 'organization') {
                                          await _secureStorage.write(
                                            key: 'pending_account_type',
                                            value: 'organization',
                                          );
                                        }
                                      } else {
                                        // ✅ SIGN-IN FLOW:
                                        // userModel should have account_type
                                        // from the API response. Write it so
                                        // HomeScreen can check it.
                                        // ⚠️ Replace 'userModel.accountType'
                                        // with the actual field name your
                                        // API returns (e.g. userModel.role,
                                        // userModel.type, etc.)
                                        final accountType =
                                            userModel.accountType ?? '';

                                        // Always save account_type for
                                        // future reference
                                        await _secureStorage.write(
                                          key: 'account_type',
                                          value: accountType,
                                        );

                                        // Check if org setup was already done
                                        final orgSetupDone =
                                            await _secureStorage.read(
                                              key: 'org_setup_done',
                                            );

                                        // Trigger org dialog on HomeScreen
                                        // if org account and setup not done
                                        if (accountType == 'organization' &&
                                            orgSetupDone == null) {
                                          await _secureStorage.write(
                                            key: 'pending_account_type',
                                            value: 'organization',
                                          );
                                        }
                                      }

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Welcome ${widget.isSignUpFlow ? '' : 'back'} ${userModel.firstName}!",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              widget.isSignUpFlow
                                              ? LoginConfirmationScreen()
                                              : HomeScreen(userId: ''),
                                        ),
                                      );
                                    } else if (_loginController.errorMessage !=
                                        null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _loginController.errorMessage!,
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } else if (_signupController.errorMessage !=
                                        null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _signupController.errorMessage!,
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            style:
                                ElevatedButton.styleFrom(
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ).copyWith(
                                  backgroundColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF45D6C4),
                                    Color(0xFF5D9CFF),
                                    Color(0xFFE54BEF),
                                  ],
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child:
                                    _loginController.isLoading ||
                                        _signupController.isLoading
                                    ? SizedBox(
                                        height: 18.h,
                                        width: 18.h,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Verify Code",
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
                        SizedBox(height: 10.h),

                        // RESEND LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF6C7278),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  (secondsRemaining == 0 &&
                                      (!_loginController.isLoading ||
                                          !_signupController.isLoading))
                                  ? () async {
                                      final isResent = widget.isSignUpFlow
                                          ? await _signupController
                                                .handleResendSignUpOtp()
                                          : await _loginController
                                                .handleResendOtp();

                                      if (!mounted) return;

                                      if (isResent &&
                                          (_loginController.successMessage !=
                                                  null ||
                                              _signupController
                                                      .successMessage !=
                                                  null)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              widget.isSignUpFlow
                                                  ? _signupController
                                                        .successMessage!
                                                  : _loginController
                                                        .successMessage!,
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        startTimer();
                                        _fillOtp(
                                          widget.isSignUpFlow
                                              ? _signupController.otp
                                              : _loginController.otp,
                                        );
                                      } else if (_loginController
                                                  .errorMessage !=
                                              null ||
                                          _signupController.errorMessage !=
                                              null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              widget.isSignUpFlow
                                                  ? _signupController
                                                        .errorMessage!
                                                  : _loginController
                                                        .errorMessage!,
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Resend",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color:
                                      (secondsRemaining == 0 &&
                                          (!_loginController.isLoading ||
                                              !_signupController.isLoading))
                                      ? const Color(0xFF4D81E7)
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      (secondsRemaining == 0 &&
                                          (!_loginController.isLoading ||
                                              !_signupController.isLoading))
                                      ? const Color(0xFF4D81E7)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
