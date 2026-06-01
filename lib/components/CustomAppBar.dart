import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback? onBackPressed;
  final VoidCallback? onTitleTapped;
  final String userId;
  final bool showLeading;
  final bool isOnProfilePage;

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.userId,
    this.onBackPressed,
    this.onTitleTapped,
    this.showLeading = true,
    this.isOnProfilePage = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F7FB),

      leading: Padding(
        padding: const EdgeInsets.only(left: 12),

        child: showLeading
            ? IconButton(
          icon:  Icon(
            Icons.menu_rounded,
            color: Color(0xFF0A0258),
            size: 24.r,
          ),

          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        )
            : IconButton(
          icon:  Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0A0258),
            size: 20.r,
          ),

          onPressed:
          onBackPressed ??
                  () {
                Navigator.pop(context);
              },
        ),
      ),

      titleSpacing: 0,

      title: SizedBox(
        width: 120.w,

        child: Image.asset(
          'assets/images/main_logo.png',
          fit: BoxFit.contain,
        ),
      ),

      actions: [
        Container(
          width: 28.w,
          height: 28.h,

          margin: const EdgeInsets.only(right: 10),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: const Color(0xFFE4E7EC),
            ),
          ),

          child: IconButton(
            padding: EdgeInsets.zero,

            onPressed: () {},

            icon:  Icon(
              Icons.search_rounded,
              size: 15.r,
              color: Color(0xFF17134A),
            ),
          ),
        ),

        Container(
          width: 28.w,
          height: 28.h,

          margin: const EdgeInsets.only(right: 16),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: const Color(0xFFE4E7EC),
            ),
          ),

          child: IconButton(
            padding: EdgeInsets.zero,

            onPressed: () {},

            icon:  Icon(
              Icons.person_add_alt_1_rounded,
              size: 15.r,
              color: Color(0xFF17134A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
