// ignore_for_file: avoid_unnecessary_containers, file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/WelcomePage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _contentController;

  late Animation<double> _circleAnimation;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _buttonOpacity;

  bool showButton = false;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Circle grows behind logo
    _circleAnimation = Tween<double>(begin: 0, end: 900).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOutCubic),
    );

    // Background color transition
    _backgroundAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFF14005E),
    ).animate(_circleController);

    // Button fade
    _buttonOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_contentController);

    startAnimation();
  }

  Future<void> startAnimation() async {
    // Start expanding circle
    await _circleController.forward();

    // Show button after animation
    setState(() {
      showButton = true;
    });

    await _contentController.forward();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _circleController,
        _contentController,
      ]),

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // TOP PURPLE CURVE
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

          // BUTTON
          if (showButton)
            Positioned(
              bottom: 80.h,
              left: 50.w,
              right: 50.w,
              child: FadeTransition(
                opacity: _buttonOpacity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WelcomePage(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
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
                        colors: [
                          Color(0xFFDD6BFF),
                          Color(0xFF4FE0C5),
                        ],
                      ),
                    ),

                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),

                      alignment: Alignment.center,

                      child: Text(
                        "Continue",
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
            ),
        ],
      ),

      builder: (context, child) {
        bool darkBackground = _circleController.value > 0.55;

        return Scaffold(
          backgroundColor: _backgroundAnimation.value,

          body: Stack(
            children: [
              child!,

              // CENTER AREA
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // EXPANDING CIRCLE
                    Container(
                      width: _circleAnimation.value,
                      height: _circleAnimation.value,

                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF14005E),
                      ),
                    ),

                    // LOGO + TEXT
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/prologoadd.png",
                          width: 65.w,
                          height: 54.h,
                        ),

                        SizedBox(width: 10.w),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// TASK
                            Text(
                              "task",
                              style: TextStyle(
                                color: darkBackground
                                    ? Colors.white
                                    : const Color(0xFF0B045A),
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            /// ALERT
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF7B61FF),
                                    Color(0xFF4FE0C5),
                                  ],
                                ).createShader(bounds);
                              },

                              child: Text(
                                "alert",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            /// .IO
                            Text(
                              ".io",
                              style: TextStyle(
                                color: darkBackground
                                    ? Colors.white
                                    : const Color(0xFF0B045A),
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
