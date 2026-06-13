// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< .merge_file_YH5caY
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../extras/MyTaskDetails.dart';
import '../screens/HomeScreen.dart';
import '../screens/MoreScreen.dart';
import '../screens/NotificationScreen.dart';
=======
import 'package:shared_preferences/shared_preferences.dart';

import '../extras/MoreScreen.dart';
import '../extras/MyTaskScreen.dart';
import '../extras/NotificationScreen.dart';
import '../screens/HomeScreen.dart';
>>>>>>> .merge_file_pgYbtp

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;

<<<<<<< .merge_file_YH5caY
  const CustomBottomNavBar({super.key, required this.selectedIndex});
=======
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });
>>>>>>> .merge_file_pgYbtp

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
<<<<<<< .merge_file_YH5caY
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String memberName = '';
  int? hoverIndex;

  late final List<Map<String, dynamic>> items;
=======
  String memberName = '';
>>>>>>> .merge_file_pgYbtp

  @override
  void initState() {
    super.initState();
<<<<<<< .merge_file_YH5caY

    items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},

      {'icon': Icons.fact_check_outlined, 'label': 'My Task'},

      {'icon': Icons.notifications_none_rounded, 'label': 'Notification'},

      {'icon': Icons.more_horiz_rounded, 'label': 'More'},
    ];

=======
>>>>>>> .merge_file_pgYbtp
    _loadMemberName();
  }

  Future<void> _loadMemberName() async {
<<<<<<< .merge_file_YH5caY
    final storedName = await secureStorage.read(key: 'user_name');

    if (!mounted) return;

    setState(() {
      memberName = storedName ?? 'Guest';
=======
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      memberName = prefs.getString('user_name') ?? 'Guest';
>>>>>>> .merge_file_pgYbtp
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

<<<<<<< .merge_file_YH5caY
    return Container(
      width: double.infinity,

      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 6.h + bottomPadding),

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
          bool isSelected = widget.selectedIndex == index;

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
                    screen = TaskDetailScreen(userId: '');
                    break;

                  case 2:
                    screen = NotificationSetting(userId: '');
                    break;

                  case 3:
                    screen = MoreScreen(userId: '');
                    break;

                  default:
                    screen = HomeScreen(userId: '');
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
              },

              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),

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
                            shaderCallback: (bounds) => const LinearGradient(
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
                                fontWeight: FontWeight.w600,
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
    );
  }
}
=======
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
>>>>>>> .merge_file_pgYbtp
