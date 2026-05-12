import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'SignInScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  bool obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Color(0xFFEDF1F3),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: 402,
                height: 83,
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
                    width: 254,
                  ),
                  SizedBox(height: 35),
                  Container(
                    width: double.infinity,
                    child: Text(
                      "Sign up to your account",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0258),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    width: double.infinity,
                    child: Text(
                      "Create an account or log in to explore about our app",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2E353A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20,),
                  // FORM CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: EdgeInsets.symmetric(horizontal: 35),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
      
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
      
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
      
                        // FIRST + LAST NAME
                        Row(
                          children: [
      
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
      
                                  Text(
                                    "First Name",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: const Color(0xFF6C7278),
                                    ),
                                  ),
      
                                  const SizedBox(height: 5),
      
                                  buildTextField(
                                    hint: "",
                                  ),
                                ],
                              ),
                            ),
      
                            const SizedBox(width: 10),
      
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
      
                                  Text(
                                    "Last Name",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: const Color(0xFF6C7278),
                                    ),
                                  ),
      
                                  const SizedBox(height: 5),
      
                                  buildTextField(
                                    hint: "",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
      
                        const SizedBox(height: 8),
      
                        // EMAIL
                        Text(
                          "Email Address",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
      
                        const SizedBox(height: 5),
      
                        buildTextField(
                          hint: "",
                          keyboardType: TextInputType.emailAddress,
                        ),
      
                        const SizedBox(height: 8),
      
                        // PHONE
                        Text(
                          "Phone Number",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
      
                        const SizedBox(height: 5),
      
                        buildTextField(
                          hint: "Phone Number",
      
                          keyboardType: TextInputType.phone,
      
                          prefix: IntrinsicWidth(
                            child: CountryCodePicker(
                              onChanged: (country) {
                                print(country.dialCode);
                              },
      
                              initialSelection: 'IN',
      
                              favorite: const ['+91', 'IN'],
      
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
      
                              padding: EdgeInsets.zero,
      
                              searchDecoration: InputDecoration(
                                hintText: "Search country",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
      
                              textStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C7278),
                              ),
                            ),
                          ),
                        ),
      
                        const SizedBox(height: 8),
      
                        // COMPANY
                        Text(
                          "Company Name",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
      
                        const SizedBox(height: 5),
      
                        buildTextField(
                          hint: "",
                          suffix: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
      
                        const SizedBox(height: 8),
      
                        // PASSWORD
                        Text(
                          "Password",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
      
                        const SizedBox(height: 5),
      
                        buildTextField(
                          hint: "********",
                          obscure: obscurePassword,
      
                          suffix: GestureDetector(
                            onTap: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
      
                            child: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
      
                        const SizedBox(height: 8),
      
                        // REGISTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(),
                                ),
                              );
                            },
      
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
      
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0A0258),
                                  width: 1,
                                ),
                              ),
      
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                alignment: Alignment.center,
      
                                child: Text(
                                  "Register",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0A0258),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
      
                        const SizedBox(height: 8),
      
                        // LOGIN TEXT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:  [
      
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Color(0xFF6C7278),
                                fontWeight: FontWeight.w400
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignInScreen(),
                                  ),
                                );
                              },

                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),

                              child: Text(
                                "Sign In",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF4D81E7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    EdgeInsetsGeometry? contentPadding,
  }) {
    return SizedBox(
      height: 42, // 👈 CONTROL ALL TEXTFIELD HEIGHT HERE

      child: TextField(
        obscureText: obscure,
        keyboardType: keyboardType,

        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),

        textAlignVertical: TextAlignVertical.center,

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),

          filled: true,
          fillColor: const Color(0xFFF9FAFC),

          // 👇 SAME PADDING FOR ALL
          contentPadding:
          contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),

          // 👇 REMOVE EXTRA ICON SPACE
          prefixIcon: prefix,
          suffixIcon: suffix,

          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),

          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),

          isDense: true,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),

            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),

            borderSide: const BorderSide(
              color: Color(0xFF0A0258),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
