import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'OtpVerificationScreen.dart';
import 'SignUpScreen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isTermsAccepted = false;
  bool _autoValidate = false;
  final phoneController = TextEditingController();
  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
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

                              // USE RADIAL GRADIENT
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
                        padding: EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 150,
                          bottom: 20,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),
                            // LOGO
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
                                  color: Color(0xFFFFFFFF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            SizedBox(height: 10.h),

                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Enter your phone number and password to sign in",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFFFFFF),
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

                // LOGIN CARD
                Transform.translate(
                  offset: const Offset(0, -130),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20.r,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    // IMPORTANT
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          // GOOGLE BUTTON
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),

                            child: SizedBox(
                              height: 42,

                              child: ElevatedButton(
                                onPressed: () {},

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9D9D9),
                                  elevation: 0,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/images/google.png",
                                      height: 14.h,
                                      width: 14.w,
                                    ),

                                    SizedBox(width: 12.w),

                                    Text(
                                      "Continue with Email",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0A0258),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 18.h),

                          // OR DIVIDER
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE4E7EC),
                                  thickness: 1,
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),

                                child: Text(
                                  "Or",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                              ),

                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFE4E7EC),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 24.h),

                          // PHONE LABEL
                          Align(
                            alignment: Alignment.centerLeft,

                            child: Text(
                              "Phone Number",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ),

                          SizedBox(height: 8.h),

                          // PHONE FIELD
                          buildTextField(
                            hint: "",
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Enter phone number";
                              }
                              if (value.trim().length != 10) {
                                return "Enter valid 10 digit phone number";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 10.h),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2C1AA8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color(0xFF2C1AA8),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();

                                setState(() {
                                  _autoValidate =
                                      true; // ✅ trigger validation on press
                                });

                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpVerificationScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Log In",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 8.h),

                          // SIGN UP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF6C7278),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SignUpScreen(),
                                    ),
                                  );
                                },

                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),

                                child: Text(
                                  "Sign Up",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF4D81E7),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF4D81E7),
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
              ],
            ),
          ),
        ),
      ),
    );
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

      // ✅ REMOVED autovalidateMode: AutovalidateMode.onUserInteraction,
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
        helperText: " ",
        helperStyle: const TextStyle(height: 0),
        errorStyle: TextStyle(fontSize: 10.sp, height: 1.h),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFF0A0258)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
