// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../extras/MoreScreen.dart';
import '../extras/MyTaskScreen.dart';
import '../extras/NotificationScreen.dart';
import '../screens/HomeScreen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  String memberName = '';

  @override
  void initState() {
    super.initState();
    _loadMemberName();
  }

  Future<void> _loadMemberName() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      memberName = prefs.getString('user_name') ?? 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    List<Map<String, dynamic>> items = [
      {
        'icon': Icons.home_rounded,
        'label': 'Home',
        'route': HomeScreen(userId: ''),
      },

      {
        'icon': Icons.fact_check_outlined,
        'label': 'My Task',
        'route':  MyTaskScreen(),
      },

      {
        'icon': Icons.notifications_none_rounded,
        'label': 'Notification',
        'route':  NotificationScreen(),
      },

      {
        'icon': Icons.more_horiz_rounded,
        'label': 'More',
        'route':  MoreScreen(),
      },
    ];

    return SafeArea(
      top: false,

      child: Container(
        width: double.infinity,

        padding: EdgeInsets.only(
          top: 8,
          bottom: bottomPadding > 0 ? 6 : 8,
        ),

        decoration:  BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),

          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 15.r,
              offset: Offset(0, -2),
            ),
          ],
        ),

        child: Row(
          children: List.generate(items.length, (index) {
            bool isSelected = widget.selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (!isSelected) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => items[index]['route'],
                      ),
                    );
                  }
                },

                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      isSelected
                          ? ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF52EBB9),
                            Color(0xFF42A8FF),
                            Color(0xFFF15EFF),
                          ],
                          stops: [0.0, 0.45, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),

                        child: Icon(
                          items[index]['icon'],
                          size: 22.r,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        items[index]['icon'],
                        size: 22.r,
                        color: const Color(0xFF667085),
                      ),

                       SizedBox(height: 2.h),

                      isSelected
                          ? ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF52EBB9),
                            Color(0xFF42A8FF),
                            Color(0xFFF15EFF),
                          ],

                          stops: [0.0, 0.45, 1.0],

                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),

                        child: Text(
                          items[index]['label'],

                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        items[index]['label'],

                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}