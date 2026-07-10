// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/features/notifications/controllers/notification_controller.dart';
import '../screens/MyTaskDetails.dart';
import '../screens/MyTaskScreen.dart';
import '../screens/HomeScreen.dart';
import '../screens/MoreScreen.dart';
import '../screens/NotificationScreen.dart';
import '../screens/NotificationStart.dart';
import '../utils/injection_container.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late final NotificationController _notificationController =
      sl<NotificationController>();

  String memberName = '';
  int? hoverIndex;

  late final List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();

    items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},

      {'icon': Icons.fact_check_outlined, 'label': 'My Task'},

      {'icon': Icons.notifications_none_rounded, 'label': 'Notification'},

      {'icon': Icons.more_horiz_rounded, 'label': 'More'},
    ];

    _loadMemberName();
    _notificationController.addListener(_onNotificationsChanged);
    _notificationController.handleGetNotifications();
  }

  @override
  void dispose() {
    _notificationController.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadMemberName() async {
    final storedName = await secureStorage.read(key: 'user_name');

    if (!mounted) return;

    setState(() {
      memberName = storedName ?? 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

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
                    screen = MyTaskScreen(userId: '');
                    break;

                  case 2:
                    screen = NotificationStart(userId: '');
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
                    Builder(
                      builder: (_) {
                        final iconWidget = isSelected
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
                              );

                        // Unread-count badge, notification bell only —
                        // hidden entirely once the count is 0.
                        final unread = index == 2
                            ? _notificationController.unreadCount
                            : 0;
                        if (unread <= 0) return iconWidget;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            iconWidget,
                            Positioned(
                              right: -6.w,
                              top: -4.h,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16.w,
                                  minHeight: 16.w,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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