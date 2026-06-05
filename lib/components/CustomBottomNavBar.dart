// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../extras/MyTaskScreen.dart';
import '../extras/NotificationScreen.dart';
import '../screens/HomeScreen.dart';
import '../screens/MoreScreen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final FlutterSecureStorage secureStorage =
  const FlutterSecureStorage();

  String memberName = '';
  int? hoverIndex;

  late final List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();

    items = [
      {
        'icon': Icons.home_rounded,
        'label': 'Home',
      },

      {
        'icon': Icons.fact_check_outlined,
        'label': 'My Task',
      },

      {
        'icon': Icons.notifications_none_rounded,
        'label': 'Notification',
      },

      {
        'icon': Icons.more_horiz_rounded,
        'label': 'More',
      },
    ];

    _loadMemberName();
  }

  Future<void> _loadMemberName() async {
    final storedName = await secureStorage.read(
      key: 'user_name',
    );

    if (!mounted) return;

    setState(() {
      memberName = storedName ?? 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding =
        MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,

      padding: EdgeInsets.fromLTRB(
        8.w,
        8.h,
        8.w,
        6.h + bottomPadding,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15.r,
            offset: const Offset(0, -2),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: List.generate(items.length, (index) {
          bool isSelected =
              widget.selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),

              onTap: () {
                if (isSelected) return;

                Widget screen;

                switch (index) {
                  case 0:
                    screen = HomeScreen(userId: '');
                    break;

                  case 1:
                    screen = MyTaskScreen();
                    break;

                  case 2:
                    screen = NotificationScreen();
                    break;

                  case 3:
                    screen = MoreScreen(userId: '',);
                    break;

                  default:
                    screen = HomeScreen(userId: '');
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => screen,
                  ),
                );
              },

              child: Padding(
                padding:
                EdgeInsets.symmetric(vertical: 4.h),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    isSelected
                        ? ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                            colors: [
                              Color(0xFF52EBB9),
                              Color(0xFF42A8FF),
                              Color(0xFFF15EFF),
                            ],
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

                    SizedBox(height: 3.h),

                    isSelected
                        ? ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                            colors: [
                              Color(0xFF52EBB9),
                              Color(0xFF42A8FF),
                              Color(0xFFF15EFF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),

                      child: Text(
                        items[index]['label'],

                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight:
                          FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      items[index]['label'],

                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight:
                        FontWeight.w500,
                        color:
                        const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
