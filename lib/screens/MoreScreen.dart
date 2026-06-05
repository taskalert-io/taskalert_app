import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Future<void> _callPhone() async {
    final Uri uri = Uri.parse('tel:+14547260592');

    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Phone error: $e');
    }
  }

  Future<void> _sendEmail() async {
    final String email = 'michaelsmith@gmail.com';
    final String subject = 'Hello';
    final String body = '';

    // Try Gmail app first
    final Uri gmailUri = Uri.parse(
      'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    // Fallback to mailto
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        // Final fallback: open Gmail in browser
        final Uri webGmail = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}',
        );
        await launchUrl(webGmail, mode: LaunchMode.externalApplication);
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  color: const Color(0xFFF5F7FB),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 20.r,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),

                            /// Profile Image
                            SizedBox(
                              width: 100.w,
                              height: 100.h,
                              child: CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/images/profile.png',
                                ),
                              ),
                            ),

                            /// Name
                            Text(
                              "Mr. Michel Smith",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                              ),
                            ),

                            /// Phone
                            TextButton(
                              onPressed: () async {
                                debugPrint('Phone tapped');
                                await _callPhone();
                              },
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
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),

                            /// Email
                            TextButton(
                              onPressed: () async {
                                debugPrint('Email tapped');
                                await _sendEmail();
                              },
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
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Column(
                        children: [
                          buildMenuCard(
                            icon: CupertinoIcons.cube_box,
                            title: "My Workspace",
                            subtitle: "No new updates",
                            // onTap: () {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => CreateTaskScreen(),
                            //     ),
                            //   );
                            // },
                          ),

                          SizedBox(height: 12.h),
                          buildMenuCard(
                            icon: CupertinoIcons.chart_bar,
                            title: "My Workflow",
                            subtitle: "No new updates",
                            // onTap: () {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => CreateTaskScreen(),
                            //     ),
                            //   );
                            // },
                          ),

                          SizedBox(height: 12.h),

                          buildMenuCard(
                            icon: CupertinoIcons.square_list,
                            title: "Create a Task",
                            subtitle: "Create a new task",
                            // onTap: () {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => CreateTaskScreen(),
                            //     ),
                            //   );
                            // },
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 16.h,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Settings",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),

                            SizedBox(height: 12.h),

                            buildSettingItem(
                              icon: CupertinoIcons.gear,
                              title: "Profile settings",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileSetting(userId: ''),
                                  ),
                                );
                              },
                            ),

                            Divider(height: 1, color: Color(0xFFE2E5EC)),

                            buildSettingItem(
                              icon: CupertinoIcons.bell,
                              title: "Notification settings",
                            ),

                            Divider(height: 1, color: Color(0xFFE2E5EC)),

                            buildSettingItem(
                              icon: CupertinoIcons.globe,
                              title: "Language settings",
                            ),

                            Divider(height: 1, color: Color(0xFFE2E5EC)),

                            buildSettingItem(
                              icon: CupertinoIcons.lock,
                              title: "Privacy policy",
                            ),

                            Divider(height: 1, color: Color(0xFFE2E5EC)),

                            buildSettingItem(
                              icon: CupertinoIcons.doc_text,
                              title: "Terms of services",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 16.h,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Support & Feedback",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),

                            SizedBox(height: 12.h),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildSupportItem(
                                  icon: CupertinoIcons.question_circle,
                                  title: "Ask a Question",
                                  onTap: () {},
                                ),

                                buildSupportItem(
                                  icon: CupertinoIcons.phone,
                                  title: "Call Us",
                                  onTap: () {},
                                ),

                                buildSupportItem(
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
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFF1F0,
                                ), // light red background
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
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
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

  Widget buildMenuCard({
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
            Icon(icon, size: 20.r, color: const Color(0xFF0A0258)),
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
                      color: const Color(0xFF0A0258),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3F3F3F),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.r,
              color: const Color(0xFF0A0258),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSettingItem({
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
            Icon(icon, size: 18.r, color: const Color(0xFF0A0258)),

            SizedBox(width: 14.w),

            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3F3F3F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSupportItem({
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.11),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
              color: const Color(0xFF3F3F3F),
            ),
          ),
        ],
      ),
    );
  }
}
