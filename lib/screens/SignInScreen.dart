import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final phoneController = TextEditingController();
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

                  decoration: const BoxDecoration(
                    color: Color(0xFF12006C),
                  ),

                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // TOP RIGHT GLOW
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

                              // USE RADIAL GRADIENT
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

                      Padding(
                        padding:  EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 150,
                          bottom: 20
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // LOGO
                            Image.asset(
                              "assets/images/antprolgo.png",
                              fit: BoxFit.cover,
                              width: 200,
                            ),

                            SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Log in to your account",
                                style: GoogleFonts.inter(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFFFFF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Enter your phone number and password to sign in",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFFFFFF),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 45),
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
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    // IMPORTANT
                    child: Form(
                      key: _formKey,

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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/images/google.png",
                                      height: 14,
                                      width: 14,
                                    ),

                                    const SizedBox(width: 12),

                                    Text(
                                      "Continue with Email",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0A0258),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

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
                                padding: const EdgeInsets.symmetric(horizontal: 10),

                                child: Text(
                                  "Or",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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

                          const SizedBox(height: 24),

                          // PHONE LABEL
                          Align(
                            alignment: Alignment.centerLeft,

                            child: Text(
                              "Phone Number",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6C7278),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

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

                          const SizedBox(height: 10),

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

                                // VALIDATION
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // SIGN UP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
                                    fontSize: 12,
                                    color: const Color(0xFF4D81E7),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                    const Color(0xFF4D81E7),
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
      autovalidateMode: AutovalidateMode.onUserInteraction,

      validator: validator,

      style: GoogleFonts.inter(
        fontSize: 12,
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
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
        ),

        helperText: " ",
        helperStyle: const TextStyle(height: 0),

        errorStyle: const TextStyle(fontSize: 10, height: 1),

        prefixIcon: prefix,
        suffixIcon: suffix,

        filled: true,
        fillColor: const Color(0xFFF9FAFC),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0A0258)),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
