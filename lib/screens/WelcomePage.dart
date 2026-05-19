import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/SignInScreen.dart';
import 'package:taskalert_app/screens/SignUpScreen.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<StatefulWidget> createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF1F3),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: 402.w,
              height: 83.h,
              child: Image.asset(
                "assets/images/procrvup.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/prologo.png",
                  fit: BoxFit.cover,
                  width: 254.w,
                ),
                SizedBox(height: 35.h),
                SizedBox(
                  width: 300.w,
                  child: Text(
                    "Welcome to the taskalert.io",
                    style: GoogleFonts.inter(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A0258),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 130.h,
            left: 0.w,
            right: 0.w,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SignInScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDD6BFF), Color(0xFF4FE0C5)],
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign In",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Color(0xFF0A0258),
                            width: 1.w,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Register",
                            style: GoogleFonts.inter(
                              color: Color(0xFF0A0258),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0.h,
            left: 0.w,
            right: 0.w,
            child: SizedBox(
              width: 402.w,
              height: 83.h,
              child: Image.asset(
                "assets/images/procrvdn.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
