import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
    viewportFraction: .50,
    initialPage: 1,
  );

  final PageController _todoController = PageController();

  int todoCurrentPage = 0;

  int currentPage = 1;
  String selectedSort = "All";
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
                      SizedBox(
                        height: 105.h,

                        child: PageView(
                          controller: _pageController,

                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },

                          children: [
                            /// CARD 1
                            GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );

                                setState(() {
                                  currentPage = 0;
                                });
                              },

                              child: _buildCard(
                                number: "01",
                                title: "Pending\nWork List",
                                isActive: currentPage == 0,
                              ),
                            ),

                            /// CARD 2
                            GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );

                                setState(() {
                                  currentPage = 1;
                                });
                              },

                              child: _buildCard(
                                number: "02",
                                title: "High Priority\nWork List",
                                isActive: currentPage == 1,
                              ),
                            ),

                            /// CARD 3
                            GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  2,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );

                                setState(() {
                                  currentPage = 2;
                                });
                              },

                              child: _buildCard(
                                number: "03",
                                title: "Scheduled\nWork List",
                                isActive: currentPage == 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15.h),

                      /// DOT INDICATOR
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: List.generate(
                            3,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),

                              child: _dot(currentPage == index),
                            ),
                          ),
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
                                )
                              ],
                            )
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
                            setState(() {
                              todoCurrentPage = index;
                            });
                          },

                          children: [
                            /// PAGE 1
                            GestureDetector(
                              // onTap: ,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),

                                child: Column(
                                  children: [
                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=12",

                                      title: "Retail Market",

                                      status: "Pending",

                                      statusColor: Colors.red,

                                      requestedBy: "Assign to Guadalupe Miró",

                                      priority: "Low",

                                      priorityColor: Colors.green,
                                    ),

                                    SizedBox(height: 14.h),

                                    Divider(color: Colors.grey.shade200),

                                    SizedBox(height: 14.h),

                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=18",

                                      title: "Yearly Food Service",

                                      status: "In progress",

                                      statusColor: Colors.orange,

                                      requestedBy: "Requested by John Kyte",

                                      priority: "High",

                                      priorityColor: Colors.red,
                                    ),

                                    SizedBox(height: 14.h),

                                    Divider(color: Colors.grey.shade200),

                                    SizedBox(height: 14.h),

                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=22",

                                      title: "Manufacture PM",

                                      status: "Done",

                                      statusColor: Colors.green,

                                      requestedBy: "Requested by Guadalupe Miró",

                                      priority: "Low",

                                      priorityColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// PAGE 2
                            GestureDetector(
                              // onTap: ,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),

                                child: Column(
                                  children: [
                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=30",

                                      title: "Office Cleaning",

                                      status: "Pending",

                                      statusColor: Colors.red,

                                      requestedBy: "Requested by Alex",

                                      priority: "Low",

                                      priorityColor: Colors.green,
                                    ),

                                    SizedBox(height: 14.h),

                                    Divider(color: Colors.grey.shade200),

                                    SizedBox(height: 14.h),

                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=35",

                                      title: "Electrical Repair",

                                      status: "In progress",

                                      statusColor: Colors.orange,

                                      requestedBy: "Requested by Smith",

                                      priority: "High",

                                      priorityColor: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// PAGE 3
                            GestureDetector(
                              // onTap: ,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),

                                child: Column(
                                  children: [
                                    _buildTodoItem(
                                      image: "https://i.pravatar.cc/150?img=40",

                                      title: "Water Supply",

                                      status: "Done",

                                      statusColor: Colors.green,

                                      requestedBy: "Requested by Jacob",

                                      priority: "Low",

                                      priorityColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// DOTS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),

                            child: _dot(todoCurrentPage == index),
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
      ),
      floatingActionButton: SizedBox(
        width: 56.w,
        height: 56.h,

        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0A0258),
          shape: CircleBorder(),
          onPressed: () {},

          child: Icon(Icons.add, color: Colors.white, size: 34.r),
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

                  Icon(
                    Icons.access_time,
                    size: 14.r,
                    color: Color(0xFF324054),
                  ),

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
}
