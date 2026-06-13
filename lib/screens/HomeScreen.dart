import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/CreateOneTimeScreen.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

import '../extras/MyTaskDetails.dart';
import 'CreateRepetitiveScreen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  /// PAGE CONTROLLER
  final PageController _pageController = PageController(
    viewportFraction: .62,
    initialPage: 1000,
  );

  final PageController _todoController = PageController();

  /// DATA LIST
  final List<Map<String, String>> workList = [
    {
      "number": "01",
      "title": "Pending\nWork List",
    },

    {
      "number": "02",
      "title": "High Priority\nWork List",
    },

    {
      "number": "03",
      "title": "Scheduled\nWork List",
    },
  ];

  final ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(1000);

  final ValueNotifier<int> todoCurrentPageNotifier = ValueNotifier<int>(0);
  String selectedSort = "All";
  String selectedWorkspaceType = "";
  @override
  void dispose() {
    _pageController.dispose();
    _todoController.dispose();

    currentPageNotifier.dispose();
    todoCurrentPageNotifier.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId, // ✅ Pass the correct userId
        showLeading: true, // ✅ Set to true to show the back button
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

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Container(
            color: const Color(0xFFF5F7FB),
            width: double.infinity,

            child: Column(
              children: [
                /// TOP SLIDER SECTION
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 15,
                    right: 15,
                    bottom: 15,
                  ),

                  height: 185.h,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),

                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8D9FF), Color(0xFFF3ECFF)],
                    ),
                  ),

                  child: Column(
                    children: [
                      /// HEADER
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 14,
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              "Work List",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),

                      /// PAGEVIEW
                      /// PAGEVIEW
                      SizedBox(
                        height: 105.h,

                        child: ValueListenableBuilder<int>(
                          valueListenable: currentPageNotifier,

                          builder: (context, currentPage, child) {
                            return PageView.builder(
                              controller: _pageController,

                              itemCount: null,

                              onPageChanged: (index) {
                                currentPageNotifier.value = index;
                              },

                              itemBuilder: (context, index) {
                                final realIndex = index % workList.length;

                                final item = workList[realIndex];

                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );

                                    currentPageNotifier.value = index;
                                  },

                                  child: Center(
                                    child: _buildCard(
                                      number: item["number"]!,
                                      title: item["title"]!,
                                      isActive:
                                      currentPage % workList.length == realIndex,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 15.h),

                      /// DOT INDICATOR
                      /// DOT INDICATOR
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: ValueListenableBuilder<int>(
                          valueListenable: currentPageNotifier,

                          builder: (context, currentPage, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: List.generate(
                                workList.length,
                                    (index) => GestureDetector(
                                  onTap: () {
                                    final targetPage =
                                        currentPage -
                                            (currentPage % workList.length) +
                                            index;

                                    _pageController.animateToPage(
                                      targetPage,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );

                                    currentPageNotifier.value = targetPage;
                                  },

                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),

                                    child: _dot(
                                      currentPage % workList.length == index,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),

                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 18,
                    bottom: 14,
                  ),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      /// TOP HEADER
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              "To-do List",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D095B),
                              ),
                            ),

                            Row(
                              children: [
                                Text(
                                  "Sort By : ",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF324054),
                                  ),
                                ),

                                DropdownButtonHideUnderline(
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,

                                    onSelected: (value) {
                                      setState(() {
                                        selectedSort = value;
                                      });
                                    },

                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: "All",
                                        child: Text("All"),
                                      ),

                                      const PopupMenuItem(
                                        value: "Pending",
                                        child: Text("Pending"),
                                      ),

                                      const PopupMenuItem(
                                        value: "Done",
                                        child: Text("Done"),
                                      ),

                                      const PopupMenuItem(
                                        value: "High",
                                        child: Text("High"),
                                      ),
                                    ],

                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        Text(
                                          selectedSort,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0A0258),
                                          ),
                                        ),

                                        Transform.translate(
                                          offset: const Offset(-2, 0),

                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16.r,
                                            color: const Color(0xFF16105D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      /// SLIDER
                      SizedBox(
                        height: 300.h,

                        child: PageView(
                          controller: _todoController,

                          onPageChanged: (index) {
                            todoCurrentPageNotifier.value = index;
                          },

                          children: [
                            /// PAGE 1
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),

                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '1',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=12",
                                      title: "Retail Market",
                                      status: "Pending",
                                      statusColor: Colors.red,
                                      requestedBy: "Assign to Guadalupe Miró",
                                      priority: "Low",
                                      priorityColor: Colors.green,
                                    ),
                                  ),

                                  SizedBox(height: 14.h),
                                  Divider(color: Colors.grey.shade200),
                                  SizedBox(height: 14.h),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '2',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=18",
                                      title: "Yearly Food Service",
                                      status: "In progress",
                                      statusColor: Colors.orange,
                                      requestedBy: "Requested by John Kyte",
                                      priority: "High",
                                      priorityColor: Colors.red,
                                    ),
                                  ),

                                  SizedBox(height: 14.h),
                                  Divider(color: Colors.grey.shade200),
                                  SizedBox(height: 14.h),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '3',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=22",
                                      title: "Manufacture PM",
                                      status: "Done",
                                      statusColor: Colors.green,
                                      requestedBy: "Requested by Guadalupe Miró",
                                      priority: "Low",
                                      priorityColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// PAGE 2
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),

                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '4',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=30",
                                      title: "Office Cleaning",
                                      status: "Pending",
                                      statusColor: Colors.red,
                                      requestedBy: "Requested by Alex",
                                      priority: "Low",
                                      priorityColor: Colors.green,
                                    ),
                                  ),

                                  SizedBox(height: 14.h),
                                  Divider(color: Colors.grey.shade200),
                                  SizedBox(height: 14.h),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '5',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=35",
                                      title: "Electrical Repair",
                                      status: "In progress",
                                      statusColor: Colors.orange,
                                      requestedBy: "Requested by Smith",
                                      priority: "High",
                                      priorityColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// PAGE 3
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),

                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailScreen(
                                            userId: widget.userId,
                                            taskId: '6',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=40",
                                      title: "Water Supply",
                                      status: "Done",
                                      statusColor: Colors.green,
                                      requestedBy: "Requested by Jacob",
                                      priority: "Low",
                                      priorityColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// DOTS
                      ValueListenableBuilder<int>(
                        valueListenable: todoCurrentPageNotifier,

                        builder: (context, todoCurrentPage, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: List.generate(
                              3,
                                  (index) => GestureDetector(
                                onTap: () {
                                  _todoController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );

                                  todoCurrentPageNotifier.value = index;
                                },

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),

                                  child: _dot(todoCurrentPage == index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Your action here

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => WorkspaceScreen(),
                    //   ),
                    // );
                  },
                  child: Container(
                    margin:  EdgeInsets.only(left: 15,right:15,bottom: 15),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(15.r),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        /// LEFT ICON
                        Container(
                          height: 27.h,
                          width: 30.w,

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.r),

                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0F0C8B),
                                Color(0xFF5B46F4),
                              ],
                            ),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(6),

                            child: Image.asset(
                              width: 20.w,
                              height: 20.h,
                              "assets/images/wrksp3d.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(width: 10.w),

                        /// TITLE
                        Expanded(
                          child: Text(
                            "Workspaces",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color:  Color(0xFF0D095B),
                            ),
                          ),
                        ),

                        /// RIGHT BUTTON
                        Container(
                          height: 22.h,
                          width: 26.w,

                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5FA),
                            borderRadius: BorderRadius.circular(5.r),
                          ),

                          child:  Icon(
                            Icons.arrow_forward,
                            size: 15.r,
                            color: Color(0xFF0A0258),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  margin:  EdgeInsets.only(left: 15,right: 15,bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),

                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A0F7A),
                        Color(0xFF1B1F9E),
                      ],
                    ),
                  ),

                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      /// BACKGROUND SHAPE
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,

                        child: Image.asset(
                          width: 146.w,
                          height: 135.h,
                          "assets/images/wrksprm.png",
                          fit: BoxFit.contain,
                        ),
                      ),

                      /// CONTENT
                      Padding(
                        padding: EdgeInsets.only(top: 15,bottom: 15,left: 15,right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Need Help?",
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF46BAEB),
                              ),
                            ),

                            SizedBox(height: 6.h),

                            Text(
                              "Smarter Solutions.\nBetter Results.",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 10.h),

                            GestureDetector(
                              onTap: () {},

                              child: Container(
                                padding:  EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),

                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB26BFF),
                                      Color(0xFF57D5FF),
                                    ],
                                  ),
                                ),

                                child: Text(
                                  "Connect With Us",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56.w,
        height: 56.h,

        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0A0258),
          shape: const CircleBorder(),

          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,

              builder: (context) {
                String selectedWorkspaceType = "";

                return StatefulBuilder(
                  builder: (context, modalSetState) {
                    final bottomInset = MediaQuery.of(context).padding.bottom;

                    return Container(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 18.h,
                        bottom: bottomInset > 0 ? bottomInset : 25.h,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28.r),
                          topRight: Radius.circular(28.r),
                        ),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// HEADER
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),

                                child: Icon(
                                  Icons.close,
                                  size: 16.r,
                                  color: const Color(0xFF101828),
                                ),
                              ),

                              Expanded(
                                child: Center(
                                  child: Text(
                                    "Create New Workspace",

                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0A0258),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 15.h),

                          Divider(
                            color: const Color(0xFFE4E7EC),
                            height: 1,
                          ),

                          SizedBox(height: 15.h),

                          /// SELECT TEXT
                          Align(
                            alignment: Alignment.centerLeft,

                            child: Text(
                              "Select one",

                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF324054),
                              ),
                            ),
                          ),

                          SizedBox(height: 10.h),

                          /// =========================
                          /// REPETITIVE
                          /// =========================

                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      if (selectedWorkspaceType == "Repetitive") {
                                        selectedWorkspaceType = "";
                                      } else {
                                        selectedWorkspaceType = "Repetitive";
                                      }
                                    });
                                  },

                                  child: Row(
                                    children: [
                                      /// RADIO
                                      Container(
                                        width: 16.w,
                                        height: 16.w,

                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFF0A0258,
                                            ),
                                            width: 1.3,
                                          ),
                                        ),

                                        child: Center(
                                          child: Container(
                                            width: 10.w,
                                            height: 10.w,

                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                              selectedWorkspaceType ==
                                                  "Repetitive"
                                                  ? const Color(
                                                0xFF24116A,
                                              )
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 10.w),

                                      /// TITLE
                                      Text(
                                        "Repetitive",

                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight:
                                          FontWeight.w500,
                                          color: const Color(
                                            0xFF3F3F3F,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// ARROW BUTTON
                              GestureDetector(
                                onTap:
                                selectedWorkspaceType ==
                                    "Repetitive"
                                    ? () {
                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateRepetitiveScreen(
                                            userId: '',
                                          ),
                                    ),
                                  );
                                }
                                    : null,

                                child: Container(
                                  width: 27.w,
                                  height: 27.w,

                                  decoration: BoxDecoration(
                                    color:
                                    selectedWorkspaceType ==
                                        "Repetitive"
                                        ? const Color(
                                      0xFFE4E7EC,
                                    )
                                        : const Color(
                                      0xFFF2F4F7,
                                    ),

                                    borderRadius:
                                    BorderRadius.circular(5.r),
                                  ),

                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 15.r,

                                    color:
                                    selectedWorkspaceType ==
                                        "Repetitive"
                                        ? const Color(
                                      0xFF667085,
                                    )
                                        : const Color(
                                      0xFF98A2B3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          /// =========================
                          /// ONE TIME
                          /// =========================

                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      if (selectedWorkspaceType == "One-time") {
                                        selectedWorkspaceType = "";
                                      } else {
                                        selectedWorkspaceType = "One-time";
                                      }
                                    });
                                  },

                                  child: Row(
                                    children: [
                                      /// RADIO
                                      Container(
                                        width: 16.w,
                                        height: 16.w,

                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFF0A0258,
                                            ),
                                            width: 1.3,
                                          ),
                                        ),

                                        child: Center(
                                          child: Container(
                                            width: 10.w,
                                            height: 10.w,

                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                              selectedWorkspaceType ==
                                                  "One-time"
                                                  ? const Color(
                                                0xFF24116A,
                                              )
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 10.w),

                                      /// TITLE
                                      Text(
                                        "One-time",

                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight:
                                          FontWeight.w500,
                                          color: const Color(
                                            0xFF3F3F3F,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// ARROW BUTTON
                              GestureDetector(
                                onTap:
                                selectedWorkspaceType ==
                                    "One-time"
                                    ? () {
                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateOneTimeScreen(
                                            userId: '',
                                          ),
                                    ),
                                  );
                                }
                                    : null,

                                child: Container(
                                  width: 27.w,
                                  height: 27.w,

                                  decoration: BoxDecoration(
                                    color:
                                    selectedWorkspaceType ==
                                        "One-time"
                                        ? const Color(
                                      0xFFE4E7EC,
                                    )
                                        : const Color(
                                      0xFFF2F4F7,
                                    ),

                                    borderRadius:
                                    BorderRadius.circular(5.r),
                                  ),

                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 15.r,

                                    color:
                                    selectedWorkspaceType ==
                                        "One-time"
                                        ? const Color(
                                      0xFF667085,
                                    )
                                        : const Color(
                                      0xFF98A2B3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                        ],
                      ),
                    );

                  },
                );
              },
            );
          },

          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 34.r,
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildTodoItem({
    required String image,
    required String title,
    required String status,
    required Color statusColor,
    required String requestedBy,
    required String priority,
    required Color priorityColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        /// PROFILE IMAGE
        Stack(
          children: [
            CircleAvatar(radius: 18.r, backgroundImage: NetworkImage(image)),

            Positioned(
              right: 0,
              top: 0,

              child: Container(
                height: 8.h,
                width: 8.w,

                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5.w),
                ),
              ),
            ),
          ],
        ),

        SizedBox(width: 10.w),

        /// CONTENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// TITLE + STATUS
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0258),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(30.r),
                    ),

                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 4.h),

              /// SUBTITLE
              Text(
                requestedBy,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF324054),
                ),
              ),

              SizedBox(height: 10.h),

              /// DATE TIME PRIORITY
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.r,
                    color: Color(0xFF324054),
                  ),

                  SizedBox(width: 4.w),

                  Text(
                    "12.05.2026",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,

                      color: Color(0xFF324054),
                    ),
                  ),

                  SizedBox(width: 14.w),

                  Icon(Icons.access_time, size: 14.r, color: Color(0xFF324054)),

                  SizedBox(width: 4.w),

                  Text(
                    "09:30 AM",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Color(0xFF324054),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    height: 7.h,
                    width: 7.w,

                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),

                  SizedBox(width: 5.w),

                  Text(
                    priority,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Color(0xFF324054),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CARD WIDGET
  Widget _buildCard({
    required String number,
    required String title,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(.40),

        borderRadius: BorderRadius.circular(15.r),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xFF000000) : Colors.grey,
                ),
              ),

              if (isActive)
                Container(
                  height: 20.h,
                  width: 20.w,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),

                  child: Icon(
                    Icons.arrow_upward,
                    size: 12.r,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          /// TITLE
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.inter(
              fontSize: 14.sp,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF0A0258) : Colors.grey,
            ),
          ),

          /// BOTTOM ICON
          Align(
            alignment: Alignment.bottomRight,

            child: Icon(
              Icons.arrow_forward_ios,
              size: 12.r,
              color: isActive ? const Color(0xFF16105D) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// DOT INDICATOR
  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      width: active ? 18 : 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5B46F4) : const Color(0xFFC9C5D6),
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }

  Widget _buildWorkspaceOption({
    required String title,
    required String value,
    required String selectedValue,
    required VoidCallback onSelect,
    required VoidCallback onArrowTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSelect,

            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4338CA),
                      width: 1.3,
                    ),
                  ),

                  child: Center(
                    child: Container(
                      width: 10.w,
                      height: 10.w,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedValue == value
                            ? const Color(0xFF24116A)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                Text(
                  title,

                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF344054),
                  ),
                ),
              ],
            ),
          ),
        ),

        GestureDetector(
          onTap: onArrowTap,

          child: Container(
            width: 30.w,
            height: 30.w,

            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8.r),
            ),

            child: Icon(
              Icons.arrow_forward,
              size: 18.r,
              color: const Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }
}