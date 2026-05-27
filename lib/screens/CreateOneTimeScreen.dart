import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

class CreateOneTimeScreen extends StatefulWidget {
  const CreateOneTimeScreen({super.key, required this.userId});
  final String userId;
  @override
  State<StatefulWidget> createState() => CreateOneTimeScreenState();
}

class CreateOneTimeScreenState extends State<CreateOneTimeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  String selectedDepartment = "Retail";
  String selectedPriority = "High";
  String SelectedReporting = "Select Users";
  bool isAssignmentEnabled = false;
  bool isProofEnabled = false;
  bool isReportEnabled = false;

  /// FIRST DATE & TIME
  final TextEditingController assignDateController = TextEditingController();

  final TextEditingController assignTimeController = TextEditingController();

  DateTime? assignSelectedDate;

  String assignSelectedAmPm = "AM";

  /// SECOND DATE & TIME
  final TextEditingController dueDateController = TextEditingController();

  final TextEditingController dueTimeController = TextEditingController();

  DateTime? dueSelectedDate;

  String dueSelectedAmPm = "AM";

  ///Third Date
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  DateTime? startSelectedDate;
  DateTime? endSelectedDate;

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
  List<String> selectedFiles = [];

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'gif',
        'mp4',
      ],
    );

    // if (result != null) {
    //   setState(() {
    //     selectedFiles = result.paths.map((e) => e ?? "").toList();
    //   });
    // }
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles = result.files.map((file) => file.name).toList();
      });
    }
  }

  final titleNameController = TextEditingController();
  String selectedRepeatType = "Daily";
  String selectedEndType = "End by :";
  String selectedProofType = "";
  String selectedProofRadioType = "";

  int selectedEveryNumber = 1;

  String selectedWeekDay = "Monday";
  int occurrencesCount = 1;
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    /// FIRST
    assignSelectedDate = now;

    assignDateController.text =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";

    assignTimeController.text = "10:00";

    /// SECOND
    dueSelectedDate = now;

    dueDateController.text =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";

    dueTimeController.text = "12:00";
  }

  /// SYNCFUSION DATE PICKER
  /// COMMON SYNCFUSION DATE PICKER
  void showCustomDatePicker({
    required BuildContext context,
    required TextEditingController controller,
    required DateTime? initialDate,
    required Function(DateTime pickedDate) onDateSelected,
  }) {
    DateTime tempSelectedDate = initialDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,
      useRootNavigator: true,

      builder: (BuildContext builder) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return SafeArea(
              child: Container(
                height: 420,

                padding: const EdgeInsets.fromLTRB(15, 15, 15, 25),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10.r,
                      spreadRadius: 1.r,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),

                child: Column(
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

                        selectionColor: const Color(0xFF0A0258),

                        todayHighlightColor: const Color(0xFF0A0258),

                        startRangeSelectionColor: Colors.white,

                        endRangeSelectionColor: Colors.white,

                        rangeSelectionColor: Colors.white,

                        headerStyle: DateRangePickerHeaderStyle(
                          backgroundColor: Colors.transparent,

                          textStyle: GoogleFonts.inter(
                            color: const Color(0xFF3F4B4B),

                            fontSize: 16.sp,

                            fontWeight: FontWeight.w600,
                          ),
                        ),

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

                    SizedBox(height: 10.h),

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

                            style: GoogleFonts.inter(
                              color: Colors.red,

                              fontSize: 14.sp,
                            ),
                          ),
                        ),

                        /// OK
                        TextButton(
                          onPressed: () {
                            controller.text =
                                "${tempSelectedDate.day.toString().padLeft(2, '0')}-"
                                "${tempSelectedDate.month.toString().padLeft(2, '0')}-"
                                "${tempSelectedDate.year}";

                            onDateSelected(tempSelectedDate);

                            Navigator.pop(context);
                          },

                          child: Text(
                            "OK",

                            style: GoogleFonts.inter(
                              color: const Color(0xFF0DA99E),

                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showCustomTimePicker({
    required BuildContext context,
    required TextEditingController controller,
    required Function(String value) onAmPmChanged,
  }) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final hour = pickedTime.hourOfPeriod.toString().padLeft(2, '0');

      final minute = pickedTime.minute.toString().padLeft(2, '0');

      controller.text = "$hour:$minute";

      onAmPmChanged(pickedTime.period == DayPeriod.am ? "AM" : "PM");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId, // ✅ Pass the correct userId
        onBackPressed: () {
          Navigator.pop(context); // Optional: customize back behavior if needed
        },
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),

                child: Container(
                  color: const Color(0xFFF5F7FB),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// BACK BUTTON + TITLE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.h,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },

                            child: Icon(
                              Icons.arrow_back,
                              size: 17.r,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          Text(
                            "Core Identity & Media",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      /// Main Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            _buildLabel("Title"),

                            SizedBox(height: 3.h),

                            buildTextField(
                              suffixIcon: Icon(
                                CupertinoIcons.pencil,
                                size: 18.r,
                                color: Colors.black54,
                              ),

                              hint: "Clean Production Floor",
                              controller: titleNameController,

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter title";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 8.h),

                            _buildLabel("Department"),

                            SizedBox(height: 3.h),

                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.white,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                              ),

                              child: ButtonTheme(
                                alignedDropdown: true,
                                child: DropdownButtonFormField<String>(
                                  value: selectedDepartment,

                                  isExpanded: true,
                                  isDense: true,

                                  alignment: AlignmentDirectional.centerStart,

                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6C7278),
                                  ),

                                  icon: Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 11.r,
                                    color: const Color(0xFF6C7278),
                                  ),

                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFC),

                                    isDense: true,

                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 8.h,
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),

                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFF0A0258),
                                      ),
                                    ),
                                  ),

                                  items: ["Retail", "Marketing", "Sales"]
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,

                                          alignment: Alignment.centerLeft,

                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: 12.w,
                                            ),

                                            child: Text(
                                              e,

                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF6C7278),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),

                                  onChanged: (value) {
                                    setState(() {
                                      selectedDepartment = value!;
                                    });
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 8.h),

                            _buildLabel("Priority"),

                            SizedBox(height: 3.h),

                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.white,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                              ),

                              child: ButtonTheme(
                                alignedDropdown: true,
                                child: DropdownButtonFormField<String>(
                                  value: selectedPriority,

                                  isExpanded: true,
                                  isDense: true,

                                  alignment: AlignmentDirectional.centerStart,

                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6C7278),
                                  ),

                                  icon: Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 11.r,
                                    color: const Color(0xFF6C7278),
                                  ),

                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFC),

                                    isDense: true,

                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 8.h,
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFFD9DEE5),
                                      ),
                                    ),

                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),

                                      borderSide: const BorderSide(
                                        color: Color(0xFF0A0258),
                                      ),
                                    ),
                                  ),

                                  items: ["High", "Medium", "Low"]
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,

                                          alignment: Alignment.centerLeft,

                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: 12.w,
                                            ),

                                            child: Text(
                                              e,

                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF6C7278),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),

                                  onChanged: (value) {
                                    setState(() {
                                      selectedPriority = value!;
                                    });
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 8.h),

                            /// ASSIGN DATE & TIME
                            Row(
                              children: [
                                /// ASSIGN DATE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      _buildLabel("Assign Date"),

                                      SizedBox(height: 4.h),

                                      GestureDetector(
                                        onTap: () {
                                          showCustomDatePicker(
                                            context: context,

                                            controller: assignDateController,

                                            initialDate: assignSelectedDate,

                                            onDateSelected: (date) {
                                              setState(() {
                                                assignSelectedDate = date;
                                              });
                                            },
                                          );
                                        },

                                        child: AbsorbPointer(
                                          child: TextFormField(
                                            controller: assignDateController,

                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF6C7278),
                                            ),

                                            decoration: InputDecoration(
                                              hintText: "mm/dd/yyyy",

                                              hintStyle: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                color: const Color(0xFFB8BEC5),
                                              ),

                                              isDense: true,

                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF9FAFC,
                                              ),

                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 10.h,
                                                  ),

                                              suffixIcon: Padding(
                                                padding: EdgeInsets.only(
                                                  right: 10.w,
                                                ),

                                                child: Icon(
                                                  CupertinoIcons.calendar,
                                                  size: 18.r,
                                                  color: const Color(
                                                    0xFF4338CA,
                                                  ),
                                                ),
                                              ),

                                              suffixIconConstraints:
                                                  BoxConstraints(
                                                    minWidth: 30.w,
                                                  ),

                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),

                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9DEE5),
                                                ),
                                              ),

                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),

                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9DEE5),
                                                ),
                                              ),

                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),

                                                borderSide: const BorderSide(
                                                  color: Color(0xFF0A0258),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 12.w),

                                /// ASSIGN TIME
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      _buildLabel("Assign Time"),

                                      SizedBox(height: 4.h),

                                      Row(
                                        children: [
                                          /// TIME FIELD
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                TimeOfDay?
                                                pickedTime = await showTimePicker(
                                                  context: context,

                                                  initialTime: TimeOfDay.now(),

                                                  builder: (context, child) {
                                                    return Theme(
                                                      data: Theme.of(context)
                                                          .copyWith(
                                                            colorScheme:
                                                                const ColorScheme.light(
                                                                  primary: Color(
                                                                    0xFF0A0258,
                                                                  ),
                                                                ),
                                                          ),

                                                      child: child!,
                                                    );
                                                  },
                                                );

                                                if (pickedTime != null) {
                                                  final hour = pickedTime
                                                      .hourOfPeriod
                                                      .toString()
                                                      .padLeft(2, '0');

                                                  final minute = pickedTime
                                                      .minute
                                                      .toString()
                                                      .padLeft(2, '0');

                                                  setState(() {
                                                    /// ONLY THIS FIELD VALUE CHANGE
                                                    assignTimeController.text =
                                                        "$hour:$minute";

                                                    /// ONLY THIS AM PM CHANGE
                                                    assignSelectedAmPm =
                                                        pickedTime.period ==
                                                            DayPeriod.am
                                                        ? "AM"
                                                        : "PM";
                                                  });
                                                }
                                              },

                                              child: AbsorbPointer(
                                                child: TextFormField(
                                                  controller:
                                                      assignTimeController,

                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w400,
                                                    color: const Color(
                                                      0xFF6C7278,
                                                    ),
                                                  ),

                                                  decoration: InputDecoration(
                                                    hintText: "00:00",

                                                    hintStyle:
                                                        GoogleFonts.inter(
                                                          fontSize: 12.sp,
                                                          color: const Color(
                                                            0xFFB8BEC5,
                                                          ),
                                                        ),

                                                    isDense: true,

                                                    filled: true,
                                                    fillColor: const Color(
                                                      0xFFF9FAFC,
                                                    ),

                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 10.w,
                                                          vertical: 10.h,
                                                        ),

                                                    suffixIcon: Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 10.w,
                                                      ),

                                                      child: Icon(
                                                        CupertinoIcons.clock,
                                                        size: 17.r,
                                                        color: const Color(
                                                          0xFF4338CA,
                                                        ),
                                                      ),
                                                    ),

                                                    suffixIconConstraints:
                                                        BoxConstraints(
                                                          minWidth: 30.w,
                                                        ),

                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10.r,
                                                          ),

                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFD9DEE5,
                                                            ),
                                                          ),
                                                    ),

                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.r,
                                                              ),

                                                          borderSide:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFFD9DEE5,
                                                                ),
                                                              ),
                                                        ),

                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.r,
                                                              ),

                                                          borderSide:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFF0A0258,
                                                                ),
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(width: 6.w),

                                          /// AM PM DROPDOWN
      

                                             Flexible(
                                               child: ConstrainedBox(
                                                 constraints: BoxConstraints(maxWidth: 65.w, minWidth: 45.w),
                                                 child: Theme(
                                                  data: Theme.of(context).copyWith(
                                                    canvasColor: Colors.white,
                                                  ),
                                                 
                                                  child: DropdownButtonFormField<String>(
                                                    value: assignSelectedAmPm,
                                                 
                                                    isDense: true,
                                                    isExpanded: true,

                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.sp,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(
                                                        0xFF6C7278,
                                                      ),
                                                    ),
                                                 
                                                    icon: Icon(
                                                      CupertinoIcons.chevron_down,
                                                      size: 10.r,
                                                      color: const Color(
                                                        0xFF6C7278,
                                                      ),
                                                    ),
                                                 
                                                    decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: const Color(
                                                        0xFFF9FAFC,
                                                      ),
                                                 
                                                      isDense: true,
                                                 
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8.w,
                                                            vertical: 10.h,
                                                          ),
                                                 
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.r,
                                                            ),
                                                 
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFFD9DEE5,
                                                              ),
                                                            ),
                                                      ),
                                                 
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10.r,
                                                                ),
                                                 
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFFD9DEE5,
                                                                  ),
                                                                ),
                                                          ),
                                                 
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10.r,
                                                                ),
                                                 
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF0A0258,
                                                                  ),
                                                                ),
                                                          ),
                                                    ),
                                                 
                                                    items: ["AM", "PM"]
                                                        .map(
                                                          (
                                                            e,
                                                          ) => DropdownMenuItem<String>(
                                                            value: e,
                                                 
                                                            child: Text(
                                                              e,
                                                 
                                                              style:
                                                                  GoogleFonts.inter(
                                                                    fontSize: 12.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    color:
                                                                        const Color(
                                                                          0xFF6C7278,
                                                                        ),
                                                                  ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                 
                                                    onChanged: (value) {
                                                      setState(() {
                                                        assignSelectedAmPm = value!;
                                                      });
                                                    },
                                                  ),
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

                            SizedBox(height: 8.h),

                            _buildLabel("Description"),

                            SizedBox(height: 3.h),

                            TextFormField(
                              maxLines: 3,

                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6C7278),
                              ),

                              decoration: InputDecoration(
                                isDense: true,

                                hintText: "Write a description....",

                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFB8BEC5),
                                ),

                                contentPadding: EdgeInsets.all(14.w),

                                filled: true,
                                fillColor: const Color(0xFFF9FAFC),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),

                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9DEE5),
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),

                                  borderSide: const BorderSide(
                                    color: Color(0xFFD9DEE5),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),

                                  borderSide: const BorderSide(
                                    color: Color(0xFF0A0258),
                                  ),
                                ),

                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),

                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),

                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),

                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 8.h),

                            Text(
                              "Add Attachments",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: Color(0xFF3F3F3F),
                              ),
                            ),

                            Text(
                              "File must be in pdf, doc, png, jpg, gif or mp4 format\nand upto 5 file(s) at a time.",

                              style: GoogleFonts.inter(
                                color: Color(0xFF797979),
                                fontSize: 11.sp,
                              ),
                            ),

                            SizedBox(height: 3.h),

                            GestureDetector(
                              onTap: pickFiles,

                              child: Container(
                                width: double.infinity,

                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFF),

                                  borderRadius: BorderRadius.circular(8.r),

                                  border: Border.all(
                                    color: const Color(0xFFB9C3FF),
                                  ),
                                ),

                                child: Column(
                                  children: [
                                    Text(
                                      "Drag & drop your file(s) here or",

                                      style: GoogleFonts.inter(
                                        color: Color(0xFF797979),
                                        fontSize: 11.sp,
                                      ),
                                    ),

                                    SizedBox(height: 3.h),

                                    Text(
                                      "Browse",

                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF304DDB),

                                        fontWeight: FontWeight.w600,

                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(top: 14.h),

                              child: Column(
                                children: [
                                  /// FILE LIST
                                  if (selectedFiles.isNotEmpty)
                                    Column(
                                      children: List.generate(selectedFiles.length, (
                                        index,
                                      ) {
                                        final fileName = selectedFiles[index];

                                        final progress = index == 0
                                            ? 0.30
                                            : 0.82;

                                        return Container(
                                          margin: EdgeInsets.only(bottom: 10.h),

                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 10.h,
                                          ),

                                          decoration: BoxDecoration(
                                            color: Colors.white,

                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),

                                            border: Border.all(
                                              color: const Color(0xFFE4E7EC),
                                            ),
                                          ),

                                          child: Column(
                                            children: [
                                              /// TOP ROW
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .insert_drive_file_outlined,
                                                    size: 18.r,
                                                    color: const Color(
                                                      0xFF667085,
                                                    ),
                                                  ),

                                                  SizedBox(width: 8.w),

                                                  Expanded(
                                                    child: Text(
                                                      fileName,

                                                      overflow:
                                                          TextOverflow.ellipsis,

                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color(
                                                          0xFF475467,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(width: 10.w),

                                                  Text(
                                                    "${(progress * 100).toInt()}%",

                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                        0xFF667085,
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(width: 6.w),

                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedFiles.removeAt(
                                                          index,
                                                        );
                                                      });
                                                    },

                                                    child: Icon(
                                                      Icons.close,
                                                      size: 15.r,
                                                      color: const Color(
                                                        0xFF98A2B3,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(height: 8.h),

                                              /// PROGRESS BAR
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20.r),

                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 2.5.h,

                                                  backgroundColor: const Color(
                                                    0xFFE4E7EC,
                                                  ),

                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
                                                        Color(0xFF4F6EF7),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      /// BUTTONS ALWAYS VISIBLE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,

                        children: [
                          /// SAVE BUTTON
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),

                              gradient: const LinearGradient(
                                colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                              ),
                            ),

                            child: ElevatedButton(
                              onPressed: () {
                                /// SUBMIT FORM HERE
                              },

                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,

                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.w,
                                  vertical: 8.h,
                                ),

                                minimumSize: Size.zero,

                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),

                              child: Text(
                                "Save Changes",

                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: Color(0xFF3F3F3F),
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),

        children: [
          TextSpan(
            text: " *",
            style: TextStyle(color: Colors.red),
          ),
        ],
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
    required Icon suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,

      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6C7278),
      ),

      decoration: InputDecoration(
        isDense: true,

        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        hintText: hint,

        hintStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFB8BEC5),
        ),

        // REMOVE THESE
        // helperText: " ",
        // helperStyle: TextStyle(height: 0.h),
        errorStyle: TextStyle(fontSize: 10.sp),

        prefixIcon: prefix,
        suffixIcon: suffix,

        filled: true,
        fillColor: const Color(0xFFF9FAFC),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF0A0258)),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
