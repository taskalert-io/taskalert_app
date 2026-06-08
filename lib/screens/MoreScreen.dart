import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/screens/ProfileSetting.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

class MoreScreen extends StatefulWidget {
  final String userId;
  const MoreScreen({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => MoreScreenState();
}

class MoreScreenState extends State<MoreScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _primaryColor = Color(0xFF0A0258);
  static const _textColor = Color(0xFF3F3F3F);
  static const _shadowBlack05 = Color(0x0D000000); // black.withOpacity(.05)
  static const _shadowBlack11 = Color(0x1C000000); // black.withOpacity(.11)
  static const _dividerColor = Color(0xFFE2E5EC);

  // ── Phone launcher ─────────────────────────────────────────────────────────
  Future<void> _callPhone() async {
    try {
      await launchUrl(Uri.parse('tel:+14547260592'));
    } catch (e) {
      debugPrint('Phone error: $e');
    }
  }

  // ── Email launcher ─────────────────────────────────────────────────────────
  Future<void> _sendEmail() async {
    const email = 'michaelsmith@gmail.com';
    const subject = 'Hello';
    final gmailUri = Uri.parse(
      'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=',
    );
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': ''},
    );
    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse(
            'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            color: const Color(0xFFF5F7FB),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          size: 20.r,
                          color: _primaryColor,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 100.w,
                      height: 100.h,
                      child: const CircleAvatar(
                        backgroundImage: AssetImage(
                          'assets/images/profile.png',
                        ),
                      ),
                    ),

                    Text(
                      "Mr. Michel Smith",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    TextButton(
                      onPressed: _callPhone,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        "(454) 726-0592",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: _sendEmail,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        "michaelsmith@gmail.com",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // ── Menu cards ────────────────────────────────────────
                _buildMenuCard(
                  icon: CupertinoIcons.cube_box,
                  title: "My Workspace",
                  subtitle: "No new updates",
                ),
                SizedBox(height: 12.h),
                _buildMenuCard(
                  icon: CupertinoIcons.chart_bar,
                  title: "My Workflow",
                  subtitle: "No new updates",
                ),
                SizedBox(height: 12.h),
                _buildMenuCard(
                  icon: CupertinoIcons.square_list,
                  title: "Create a Task",
                  subtitle: "Create a new task",
                ),

                SizedBox(height: 12.h),

                // ── Settings card ──────────────────────────────────────
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: const [
                      BoxShadow(
                        color: _shadowBlack05,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Settings",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      _buildSettingItem(
                        icon: CupertinoIcons.gear,
                        title: "Profile settings",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileSetting(userId: widget.userId),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: _dividerColor),
                      _buildSettingItem(
                        icon: CupertinoIcons.bell,
                        title: "Notification settings",
                      ),
                      const Divider(height: 1, color: _dividerColor),
                      _buildSettingItem(
                        icon: CupertinoIcons.globe,
                        title: "Language settings",
                      ),
                      const Divider(height: 1, color: _dividerColor),
                      _buildSettingItem(
                        icon: CupertinoIcons.lock,
                        title: "Privacy policy",
                      ),
                      const Divider(height: 1, color: _dividerColor),
                      _buildSettingItem(
                        icon: CupertinoIcons.doc_text,
                        title: "Terms of services",
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // ── Support card ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: const [
                      BoxShadow(
                        color: _shadowBlack05,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Support & Feedback",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSupportItem(
                            icon: CupertinoIcons.question_circle,
                            title: "Ask a Question",
                            onTap: () {},
                          ),
                          _buildSupportItem(
                            icon: CupertinoIcons.phone,
                            title: "Call Us",
                            onTap: () {},
                          ),
                          _buildSupportItem(
                            icon: CupertinoIcons.chat_bubble_2,
                            title: "Report a Problem",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // ── Logout ─────────────────────────────────────────────
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF1F0),
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 20.w,
                      ),
                      side: const BorderSide(
                        color: Color(0xFFEC2222),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Log out from taskalert.io',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD0080B),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  // ── Reusable widgets (static — no instance state needed) ──────────────────

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: const [
            BoxShadow(
              color: _shadowBlack05,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: _primaryColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20.r, color: _primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 18.r, color: _primaryColor),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    IconData? icon,
    String? imagePath,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 46.h,
            width: 46.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: _shadowBlack11,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: imagePath != null
                  ? Image.asset(
                      imagePath,
                      width: 24.w,
                      height: 24.h,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, color: const Color(0xFF312A73), size: 24.r),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
