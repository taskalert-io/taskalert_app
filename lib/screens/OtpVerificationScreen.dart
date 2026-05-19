import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/LoginConfirmationScreen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<StatefulWidget> createState() => OtpVerificationScreenState();
}

class OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

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
                                "Sign in to your account",
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
                        // TITLE
                        Text(
                          "OTP Verification",

                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF000000),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // DESCRIPTION
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

                                child: TextFormField(
                                  controller: otpControllers[index],

                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,

                                  keyboardType: TextInputType.number,

                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      1,
                                    ), // ONLY 1 NUMBER
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
                                      borderRadius: BorderRadius.circular(6.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFFD8DCE3),
                                      ),
                                    ),

                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r),

                                      borderSide: BorderSide(
                                        color: Color(0xFF0A0258),
                                        width: 1.2.w,
                                      ),
                                    ),
                                  ),

                                  onChanged: (value) {
                                    // NEXT BOX
                                    if (value.isNotEmpty && index < 5) {
                                      FocusScope.of(context).nextFocus();
                                    }

                                    // BACK TO PREVIOUS
                                    if (value.isEmpty && index > 0) {
                                      FocusScope.of(context).previousFocus();
                                    }
                                  },
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
                            "00:60 sec",

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
                            onPressed: () {
                              // CHECK EMPTY OTP
                              bool isOtpComplete = otpControllers.every(
                                (controller) =>
                                    controller.text.trim().isNotEmpty,
                              );

                              if (!isOtpComplete) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please enter complete OTP"),
                                  ),
                                );

                                return;
                              }

                              // SUCCESS
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginConfirmationScreen(),
                                ),
                              );
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

                                child: Text(
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

                        // RESEND
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn’t receive the code? ",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF6C7278),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                // Navigator.pushReplacement(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (_) => SignUpScreen(),
                                //   ),
                                // );
                              },

                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),

                              child: Text(
                                "Resend",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
