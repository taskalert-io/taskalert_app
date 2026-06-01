import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomDrawer.dart';

class ProfileSetting extends StatefulWidget {
  final String userId;
  const ProfileSetting({super.key, required this.userId});
  @override
  State<StatefulWidget> createState() => ProfileSettingState();
}

class ProfileSettingState extends State<ProfileSetting>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTab(String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? const Color(0xFF0A0258)
                  : const Color(0xFF8B8C8E),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          width: double.infinity,
          height: 3.h,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [
                Color(0xFFE040FB),
                Color(0xFF40C4FF),
                Color(0xFF64FFDA),
              ],
            )
                : null,
            color: isSelected ? null : const Color(0xFFE5E5E5),
          ),
        ),
      ],
    );
  }

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

    final Uri gmailUri = Uri.parse(
      'googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
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
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(                              // 👈 Column instead of LayoutBuilder + SingleChildScrollView
          children: [
            /// ── Scrollable top section ──────────────────────────
            SingleChildScrollView(                 // 👈 only the header scrolls
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
                    Center(
                      child: SizedBox(
                        width: 100.w,
                        height: 100.h,
                        child: const CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/profile.png',
                          ),
                        ),
                      ),
                    ),

                    /// Name
                    Center(
                      child: Text(
                        "Mr. Michel Smith",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),

                    /// Phone
                    Center(
                      child: TextButton(
                        onPressed: () async => await _callPhone(),
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
                    ),

                    /// Email
                    Center(
                      child: TextButton(
                        onPressed: () async => await _sendEmail(),
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
                    ),

                    SizedBox(height: 20.h),

                    /// Tab Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTab = 0;
                            });
                          },
                          child: SizedBox(
                            width: 140.w,
                            child: _buildTab(
                              "My Profile",
                              selectedTab == 0,
                            ),
                          ),
                        ),

                        SizedBox(width: 20.w),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTab = 1;
                            });
                          },
                          child: SizedBox(
                            width: 140.w,
                            child: _buildTab(
                              "Account Settings",
                              selectedTab == 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            /// ── TabBarView takes all remaining screen space ──────
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FB),
                child: selectedTab == 0
                    ? Center(
                  child: Text(
                    "My Profile Content",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                    ),
                  ),
                )
                    : Center(
                  child: Text(
                    "Account Settings Content",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}