import 'package:flutter/material.dart';
import 'LoginPage.dart';

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
    _circleAnimation = Tween<double>(
      begin: 0,
      end: 900,
    ).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: Curves.easeInOutCubic,
      ),
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
      builder: (context, child) {

        return Scaffold(
          backgroundColor: _backgroundAnimation.value,
          body: Stack(
            children: [

              // TOP CURVE EFFECT
              Positioned(
                top: -60,
                left: -40,
                right: -40,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.purple.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

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
                          width: 65,
                          height: 54,
                        ),

                        const SizedBox(width: 10),

                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: -1.0, end: 2.0),
                          duration: const Duration(seconds: 3),
                          curve: Curves.linear,
                          builder: (context, value, child) {

                            bool darkBackground = _circleController.value > 0.55;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                // TASK ANIMATION
                                ShaderMask(
                                  shaderCallback: (bounds) {

                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: darkBackground
                                          ? [
                                        Colors.white,
                                        const Color(0xFF4FE0C5),
                                        Colors.white,
                                      ]
                                          : [
                                        const Color(0xFF0B045A),
                                        const Color(0xFF4FE0C5),
                                        const Color(0xFF0B045A),
                                      ],
                                      stops: [
                                        (value - 0.3).clamp(0.0, 1.0),
                                        value.clamp(0.0, 1.0),
                                        (value + 0.3).clamp(0.0, 1.0),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "task",
                                    style: TextStyle(
                                      color: darkBackground
                                          ? Colors.white
                                          : const Color(0xFF0B045A),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // ALERT STATIC LINEAR GRADIENT
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
                                  child: const Text(
                                    "alert",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // .IO
                                Text(
                                  ".io",
                                  style: TextStyle(
                                    color: darkBackground
                                        ? Colors.white
                                        : const Color(0xFF0B045A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // BUTTON
              if (showButton)
                Positioned(
                  bottom: 80,
                  left: 40,
                  right: 40,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(),
                            ),
                          );

                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFDD6BFF),
                                Color(0xFF4FE0C5),
                              ],
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
        );
      },
    );
  }
}