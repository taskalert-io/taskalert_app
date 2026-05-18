import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginConfirmationScreen extends StatefulWidget {
  const LoginConfirmationScreen({super.key});

  @override
  State<LoginConfirmationScreen> createState() =>
      LoginConfirmationScreenState();
}

class LoginConfirmationScreenState
    extends State<LoginConfirmationScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainController;

  late Animation<double> _logoAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;

  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // LOGO
    _logoAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.0,
          0.25,
          curve: Curves.easeOut,
        ),
      ),
    );

    // SUCCESS ICON
    _iconAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.25,
          0.55,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // TEXT
    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.45,
          0.7,
          curve: Curves.easeOut,
        ),
      ),
    );

    // BUTTON
    _buttonAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.7,
          1,
          curve: Curves.easeOut,
        ),
      ),
    );

    // GLOW
    _glowAnimation = Tween<double>(
      begin: 18,
      end: 35,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: _mainController,

      builder: (context, child) {

        return Scaffold(
          backgroundColor: const Color(0xFF14005E),

          body: Stack(
            children: [

              // TOP GLOW
              Positioned(
                top: -140,
                left: -90,
                right: -90,

                child: IgnorePointer(
                  child: Container(
                    height: 260,

                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(260),
                        bottomRight: Radius.circular(260),
                      ),

                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.35,

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

              SafeArea(
                child: Padding(
                  padding:  EdgeInsets.only(left: 20,right: 20,bottom: 40),

                  child: Column(
                    children: [

                      const SizedBox(height: 120),

                      // LOGO
                      FadeTransition(
                        opacity: _logoAnimation,

                        child: Transform.translate(
                          offset: Offset(
                            0,
                            40 - (_logoAnimation.value * 40),
                          ),

                          child: Image.asset(
                            "assets/images/antprolgo.png",
                            width: 200,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // SUCCESS ICON
                      ScaleTransition(
                        scale: _iconAnimation,

                        child: Container(
                          width: 90,
                          height: 90,

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,

                              colors: [
                                Color(0xFFE7D7FF),
                                Color(0xFFC39BFF),
                              ],
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB98BFF)
                                    .withOpacity(0.55),

                                blurRadius: _glowAnimation.value,
                                spreadRadius: 5,
                              ),
                            ],
                          ),

                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // TEXTS
                      FadeTransition(
                        opacity: _textAnimation,

                        child: Transform.translate(
                          offset: Offset(
                            0,
                            25 - (_textAnimation.value * 25),
                          ),

                          child: Column(
                            children: [

                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  "Congratulations !",

                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  "You are successfully completed our process.",

                                  textAlign: TextAlign.center,

                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // BUTTON
                      FadeTransition(
                        opacity: _buttonAnimation,

                        child: Transform.translate(
                          offset: Offset(
                            0,
                            40 - (_buttonAnimation.value * 40),
                          ),

                          child: SizedBox(
                            width: double.infinity,
                            height: 42,

                            child: ElevatedButton(
                              onPressed: () {

                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),

                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),

                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.10),
                                      Colors.white.withOpacity(0.03),
                                    ],
                                  ),
                                ),

                                child: Center(
                                  child: Text(
                                    "Start Your Journey",

                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
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
            ],
          ),
        );
      },
    );
  }
}