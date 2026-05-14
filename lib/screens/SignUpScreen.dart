import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SignInScreen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  final TextEditingController _dateController = TextEditingController();

  bool isLoading = false;

  String? nomineedobError;

  DateTime? _selectedDate;

  int? editingIndex;

  bool obscurePassword = true;
  bool obscureRePassword = true;
  String? selectedGender;
  TextEditingController dayController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  final FocusNode dayFocus = FocusNode();
  final FocusNode monthFocus = FocusNode();
  final FocusNode yearFocus = FocusNode();
  bool isDayFocused = false;
  bool isMonthFocused = false;
  bool isYearFocused = false;
  bool isTermsAccepted = false;

  final _formKey = GlobalKey<FormState>();
  bool isDobError = false;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();
  bool isGenderError = false;
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = now;

    _dateController.text =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";
  }

  /// SYNCFUSION DATE PICKER
  void _showDatePicker(BuildContext context) {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (BuildContext builder) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Container(
              height: 430,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),

                    blurRadius: 10,

                    spreadRadius: 2,

                    offset: const Offset(0, -2),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  /// DATE PICKER
                  Expanded(
                    child: SfDateRangePicker(
                      initialSelectedDate: tempSelectedDate,

                      selectionMode: DateRangePickerSelectionMode.single,

                      view: DateRangePickerView.month,

                      allowViewNavigation: true,

                      showNavigationArrow: true,

                      backgroundColor: Colors.white,

                      selectionColor: Color(0xFF0A0258),

                      todayHighlightColor: Color(0xFF0A0258),

                      startRangeSelectionColor: Colors.white,

                      endRangeSelectionColor: Colors.white,

                      rangeSelectionColor: Colors.white,

                      headerStyle: DateRangePickerHeaderStyle(
                        backgroundColor: Colors.transparent,

                        textStyle: GoogleFonts.inter(
                          color: const Color(0xFF3F4B4B),

                          fontSize: 16,

                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      /// SELECT DATE
                      onSelectionChanged:
                          (DateRangePickerSelectionChangedArgs args) {
                            if (args.value is DateTime) {
                              dialogSetState(() {
                                tempSelectedDate = args.value;
                              });
                            }
                          },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      /// CANCEL
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: Text(
                          "Cancel",

                          style: GoogleFonts.poppins(
                            color: Colors.red,

                            fontSize: 14,
                          ),
                        ),
                      ),

                      /// OK
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = tempSelectedDate;

                            _dateController.text =
                                "${tempSelectedDate.day.toString().padLeft(2, '0')}-"
                                "${tempSelectedDate.month.toString().padLeft(2, '0')}-"
                                "${tempSelectedDate.year}";
                          });

                          Navigator.pop(context);
                        },

                        child: Text(
                          "OK",

                          style: GoogleFonts.inter(
                            color: const Color(0xFF0DA99E),

                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Color(0xFFEDF1F3),
        body: Container(
          child: Stack(
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
                      width: 200,
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Sign up to your account",
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0258),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10),
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
                    SizedBox(height: 15),
                    // FORM CARD
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.67,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: EdgeInsets.symmetric(horizontal: 20),
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

                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FIRST + LAST NAME
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            controller: firstNameController,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return "Enter first name";
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                          
                                    const SizedBox(width: 10),
                          
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            controller: lastNameController,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return "Enter last name";
                                              }
                                              return null;
                                            },
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
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Enter email";
                                    }

                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return "Enter valid email";
                                    }

                                    return null;
                                  },
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
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,

                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Enter phone number";
                                    }
                                    return null;
                                  },

                                  prefix: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),

                                    child: CountryCodePicker(
                                      onChanged: (country) {},

                                      initialSelection: 'IN',
                                      favorite: const ['+91', 'IN'],

                                      showCountryOnly: false,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft: false,

                                      padding: EdgeInsets.zero,

                                      textStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6C7278),
                                      ),
                                    ),
                                  ),
                                ),
                          
                                const SizedBox(height: 8),
                          
                                // COMPANY
                                // Text(
                                //   "Company Name",
                                //   style: GoogleFonts.inter(
                                //     fontWeight: FontWeight.w400,
                                //     fontSize: 12,
                                //     color: const Color(0xFF6C7278),
                                //   ),
                                // ),
                                //
                                // const SizedBox(height: 5),
                                //
                                // buildTextField(
                                //   hint: "",
                                //   suffix: const Icon(
                                //     Icons.edit_outlined,
                                //     size: 18,
                                //     color: Colors.grey,
                                //   ),
                                // ),
                                //
                                // const SizedBox(height: 8),
                          
                                // GENDER + DOB
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // GENDER
                                    // GENDER
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Gender",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: const Color(0xFF6C7278),
                                            ),
                                          ),

                                          const SizedBox(height: 5),

                                          SizedBox(
                                            height: 42,

                                            child: DropdownButtonFormField<String>(
                                              value: selectedGender,

                                              isExpanded: true,

                                              decoration: InputDecoration(
                                                isDense: true,

                                                hintText: "Select",

                                                hintStyle: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(0xFFB8BEC5),
                                                ),

                                                errorStyle: const TextStyle(
                                                  height: 0,
                                                  fontSize: 0,
                                                ),

                                                filled: true,
                                                fillColor: const Color(0xFFF9FAFC),

                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),

                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFD9DEE5),
                                                  ),
                                                ),

                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: isGenderError
                                                        ? Colors.red
                                                        : const Color(0xFFD9DEE5),
                                                  ),
                                                ),

                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: isGenderError
                                                        ? Colors.red
                                                        : const Color(0xFF0A0258),
                                                  ),
                                                ),

                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                ),

                                                focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),

                                              icon: const Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                size: 18,
                                                color: Colors.grey,
                                              ),

                                              items: [
                                                DropdownMenuItem(
                                                  value: "Male",
                                                  child: Text(
                                                    "Male",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(0xFF6C7278),
                                                    ),
                                                  ),
                                                ),

                                                DropdownMenuItem(
                                                  value: "Female",
                                                  child: Text(
                                                    "Female",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(0xFF6C7278),
                                                    ),
                                                  ),
                                                ),

                                                DropdownMenuItem(
                                                  value: "Other",
                                                  child: Text(
                                                    "Other",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(0xFF6C7278),
                                                    ),
                                                  ),
                                                ),
                                              ],

                                              onChanged: (value) {
                                                setState(() {
                                                  selectedGender = value;
                                                  isGenderError = false;
                                                });
                                              },
                                            ),
                                          ),

                                          if (isGenderError)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 5,
                                                left: 4,
                                              ),

                                              child: Text(
                                                "Please select gender",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                          
                                    const SizedBox(width: 10),
                          
                                    // DATE OF BIRTH
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Date of Birth",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: const Color(0xFF6C7278),
                                            ),
                                          ),

                                          const SizedBox(height: 5),

                                          SizedBox(
                                            height: 42,

                                            child: Row(
                                              children: [

                                                /// DAY
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => _showDatePicker(context),

                                                    child: Container(
                                                      height: 42,

                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF9FAFC),

                                                        borderRadius: const BorderRadius.only(
                                                          topLeft: Radius.circular(10),
                                                          bottomLeft: Radius.circular(10),
                                                        ),

                                                        border: Border.all(
                                                          color: isDobError
                                                              ? Colors.red
                                                              : const Color(0xFFD9DEE5),

                                                          width: 1,
                                                        ),
                                                      ),

                                                      child: IgnorePointer(
                                                        child: TextField(
                                                          controller: dayController,
                                                          readOnly: true,

                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w400,
                                                            color: const Color(0xFF6C7278),
                                                          ),

                                                          decoration: InputDecoration(
                                                            isDense: true,

                                                            hintText: "Day",

                                                            hintStyle: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w400,
                                                              color: const Color(0xFFB8BEC5),
                                                            ),

                                                            border: InputBorder.none,

                                                            contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                /// MONTH
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => _showDatePicker(context),

                                                    child: Container(
                                                      height: 42,

                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF9FAFC),

                                                        border: Border(
                                                          top: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),

                                                          bottom: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),

                                                          right: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),
                                                        ),
                                                      ),

                                                      child: IgnorePointer(
                                                        child: TextField(
                                                          controller: monthController,
                                                          readOnly: true,

                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w400,
                                                            color: const Color(0xFF6C7278),
                                                          ),

                                                          decoration: InputDecoration(
                                                            isDense: true,

                                                            hintText: "Month",

                                                            hintStyle: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w400,
                                                              color: const Color(0xFFB8BEC5),
                                                            ),

                                                            border: InputBorder.none,

                                                            contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                /// YEAR
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => _showDatePicker(context),

                                                    child: Container(
                                                      height: 42,

                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF9FAFC),

                                                        borderRadius: const BorderRadius.only(
                                                          topRight: Radius.circular(10),
                                                          bottomRight: Radius.circular(10),
                                                        ),

                                                        border: Border(
                                                          top: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),

                                                          bottom: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),

                                                          right: BorderSide(
                                                            color: isDobError
                                                                ? Colors.red
                                                                : const Color(0xFFD9DEE5),
                                                          ),
                                                        ),
                                                      ),

                                                      child: IgnorePointer(
                                                        child: TextField(
                                                          controller: yearController,
                                                          readOnly: true,

                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w400,
                                                            color: const Color(0xFF6C7278),
                                                          ),

                                                          decoration: InputDecoration(
                                                            isDense: true,

                                                            hintText: "Year",

                                                            hintStyle: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w400,
                                                              color: const Color(0xFFB8BEC5),
                                                            ),

                                                            border: InputBorder.none,

                                                            contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 12,
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

                                          if (isDobError)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 5,
                                                left: 4,
                                              ),

                                              child: Text(
                                                "Please select date of birth",

                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedGender == "Select")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 4),

                                    child: Align(
                                      alignment: Alignment.centerLeft,

                                      child: Text(
                                        "Please select gender",
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.red,
                                        ),
                                      ),
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
                                  controller: passwordController,
                                  obscure: obscurePassword,

                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Enter password";
                                    }

                                    if (value.length < 6) {
                                      return "Password must be 6 characters";
                                    }

                                    return null;
                                  },

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
                                    ),
                                  ),
                                ),
                          
                                const SizedBox(height: 8),
                          
                                // RE-ENTER PASSWORD
                                Text(
                                  "Re-Enter Password",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: const Color(0xFF6C7278),
                                  ),
                                ),
                          
                                const SizedBox(height: 5),

                                buildTextField(
                                  hint: "********",
                                  controller: rePasswordController,
                                  obscure: obscureRePassword,

                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Re-enter password";
                                    }

                                    if (value != passwordController.text) {
                                      return "Password not match";
                                    }

                                    return null;
                                  },

                                  suffix: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        obscureRePassword = !obscureRePassword;
                                      });
                                    },
                                    child: Icon(
                                      obscureRePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                          
                                const SizedBox(height: 8),
                          
                                /// TERMS & CONDITIONS
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Checkbox(
                                        value: isTermsAccepted,
                                        onChanged: (value) {
                                          setState(() {
                                            isTermsAccepted = value ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF0A0258),
                                        side: BorderSide(
                                          color: Color(0xFFD0D5DD),
                                          width: 1.2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                          
                                    const SizedBox(width: 10),
                          
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF98A2B3),
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "Agree with ",
                                          ),
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: TextButton(
                                              onPressed: () {
                                                // Navigate to Terms & Conditions
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                "Term & Conditions",
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0A0258),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                          
                                const SizedBox(height: 8),
                          
                                /// CREATE ACCOUNT BUTTON
                                Container(
                                  child: ElevatedButton(
                                    onPressed: () {

                                      if (!isTermsAccepted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Accept Terms & Conditions"),
                                          ),
                                        );
                                        return;
                                      }

                                      if (_formKey.currentState!.validate()) {

                                        if (dayController.text.isEmpty ||
                                            monthController.text.isEmpty ||
                                            yearController.text.isEmpty) {

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Please select date of birth"),
                                            ),
                                          );

                                          return;
                                        }

                                        // SUCCESS
                                        print("Form Validated");
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),

                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),

                                        gradient: isTermsAccepted
                                            ? const LinearGradient(
                                          colors: [
                                            Color(0xFF98E0D5),
                                            Color(0xFFE49AEF),
                                          ],
                                        )
                                            : const LinearGradient(
                                          colors: [
                                            Color.fromARGB(179, 224, 213, 255),
                                            Color.fromARGB(179, 154, 239, 255),
                                          ],
                                        ),
                                      ),

                                      child: Container(
                                        width: double.infinity,
                                        alignment: Alignment.center,

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),

                                        child: Text(
                                          "Create An Account",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          
                                const SizedBox(height: 8),
                          
                                /// OR DIVIDER
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFFE4E7EC),
                                        thickness: 1,
                                      ),
                                    ),
                          
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "OR",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF667085),
                                        ),
                                      ),
                                    ),
                          
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFFE4E7EC),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                          
                                const SizedBox(height: 8),
                          
                                /// GOOGLE BUTTON
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: ElevatedButton(
                                    onPressed: () {

                                      final isDobEmpty =
                                          dayController.text.trim().isEmpty ||
                                              monthController.text.trim().isEmpty ||
                                              yearController.text.trim().isEmpty;

                                      setState(() {
                                        isDobError = isDobEmpty;
                                        isGenderError = selectedGender == null;
                                      });

                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }

                                      if (isDobEmpty || selectedGender == null) {
                                        return;
                                      }

                                      if (!isTermsAccepted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Accept Terms & Conditions"),
                                          ),
                                        );
                                        return;
                                      }

                                      print("Form Validated");
                                    },

                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),

                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),

                                        gradient: isTermsAccepted
                                            ? const LinearGradient(
                                          colors: [
                                            Color(0xFF98E0D5),
                                            Color(0xFFE49AEF),
                                          ],
                                        )
                                            : const LinearGradient(
                                          colors: [
                                            Color.fromARGB(179, 224, 213, 255),
                                            Color.fromARGB(179, 154, 239, 255),
                                          ],
                                        ),
                                      ),

                                      child: Container(
                                        width: double.infinity,
                                        alignment: Alignment.center,

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),

                                        child: Text(
                                          "Create An Account",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          
                                // const SizedBox(height: 18),
                          
                                // REGISTER BUTTON
                                // SizedBox(
                                //   width: double.infinity,
                                //   child: ElevatedButton(
                                //     onPressed: () {
                                //       Navigator.pushReplacement(
                                //         context,
                                //         MaterialPageRoute(
                                //           builder: (_) => SignUpScreen(),
                                //         ),
                                //       );
                                //     },
                                //
                                //     style: ElevatedButton.styleFrom(
                                //       elevation: 0,
                                //       backgroundColor: Colors.transparent,
                                //       shadowColor: Colors.transparent,
                                //       padding: EdgeInsets.zero,
                                //       shape: RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(12),
                                //       ),
                                //     ),
                                //
                                //     child: Ink(
                                //       decoration: BoxDecoration(
                                //         borderRadius: BorderRadius.circular(12),
                                //         border: Border.all(
                                //           color: const Color(0xFF0A0258),
                                //           width: 1,
                                //         ),
                                //       ),
                                //
                                //       child: Container(
                                //         padding: const EdgeInsets.symmetric(
                                //           horizontal: 10,
                                //           vertical: 10,
                                //         ),
                                //         alignment: Alignment.center,
                                //
                                //         child: Text(
                                //           "Register",
                                //           style: GoogleFonts.inter(
                                //             color: const Color(0xFF0A0258),
                                //             fontWeight: FontWeight.w600,
                                //             fontSize: 12,
                                //           ),
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ),
                          
                                // LOGIN TEXT
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Color(0xFF6C7278),
                                        fontWeight: FontWeight.w400,
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
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                          
                                      child: Text(
                                        "Sign In",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    Widget? suffix,
  }) {
    return TextFormField( // Removed SizedBox to allow error message to show
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,

      // Default validator to ensure field is not empty
      validator: validator ?? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $hint';
        }
        return null;
      },

      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6C7278),
      ),

      decoration: InputDecoration(
        isDense: true,
        hintText: hint,

        // Update error style so it is visible
        errorStyle: const TextStyle(
          fontSize: 10,
          color: Colors.red,
        ),

        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
        ),

        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FAFC),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),

        // Borders... (keep your existing border code here)
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
          borderSide: const BorderSide(color: Color(0xFF0A0258), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}
