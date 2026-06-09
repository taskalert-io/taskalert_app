import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

// ── Data models ──────────────────────────────────────────────────────────────

class NotifItem {
  final String title;
  final String desc;
  bool isOn;
  NotifItem({required this.title, required this.desc, required this.isOn});
}

class NotifTab {
  final String label;
  final List<NotifItem> items;
  NotifTab({required this.label, required this.items});
}

// ── Screen ───────────────────────────────────────────────────────────────────

class NotificationSetting extends StatefulWidget {
  final String userId;
  const NotificationSetting({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  // ── Constants — same as ProfileSetting ────────────────────────────────────
  static const _primaryColor  = Color(0xFF0A0258);
  static const _dividerColor  = Color(0xFFE4E7EC);
  static const _textColor     = Color(0xFF6C7278);
  static const _labelColor    = Color(0xFF303030);
  static const _shadowBlack08 = Color(0x14000000);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  int _selectedTab = 0;

  // ── Tab data ───────────────────────────────────────────────────────────────
  late final List<NotifTab> _tabs = [
    NotifTab(label: 'Communications', items: [
      NotifItem(title: 'Mentioned me',    desc: 'in an update or reply',                    isOn: false),
      NotifItem(title: 'Wrote an update', desc: 'on an item I own',                         isOn: true),
      NotifItem(title: 'Wrote an update', desc: "on an item I'm subscribed to",             isOn: false),
      NotifItem(title: 'Replied',         desc: 'to a thread I commented on or reached to', isOn: true),
      NotifItem(title: 'Replied',         desc: 'to an update I wrote',                     isOn: false),
      NotifItem(title: 'Reactions',       desc: 'to my update',                             isOn: false),
    ]),
    NotifTab(label: 'Automation', items: [
      NotifItem(title: 'Automations with a "notify" step', desc: 'this does not include "send an email" automations', isOn: false),
      NotifItem(title: 'Automation failures',              desc: "when automations don't run as expected",            isOn: false),
      NotifItem(title: 'Platform API',                     desc: 'Custom notifications using the GraphQL API',        isOn: true),
    ]),
    NotifTab(label: 'Collaboration', items: [
      NotifItem(title: 'Assigned me',      desc: 'to an item',                             isOn: false),
      NotifItem(title: 'Invitations',      desc: 'to workspace, board, doc, item or team', isOn: true),
      NotifItem(title: 'Template changes', desc: 'by the template owner',                  isOn: false),
    ]),
    NotifTab(label: 'Requests', items: [
      NotifItem(title: 'Requests access',       desc: 'to boards & dashboards',     isOn: false),
      NotifItem(title: 'Requests installation', desc: 'to install & purchase apps', isOn: false),
    ]),
    NotifTab(label: 'Admin', items: [
      NotifItem(title: 'New member joined', desc: 'added to your account', isOn: true),
      NotifItem(title: 'Member removed',    desc: 'from your account',     isOn: false),
    ]),
    NotifTab(label: 'Sign-ups', items: [
      NotifItem(title: 'New sign-up', desc: 'someone signed up via your invite link', isOn: true),
    ]),
    NotifTab(label: 'Security', items: [
      NotifItem(title: 'Login from new device', desc: 'when your account is accessed from a new browser or device', isOn: true),
      NotifItem(title: 'Password changed',      desc: 'when your password is updated',                             isOn: true),
    ]),
  ];

  // ── _buildToggle — verbatim from ProfileSetting ───────────────────────────
  Widget _buildToggle({required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 30.w,
        height: 15.h,
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: value ? const Color(0xFF1DC230) : const Color(0xFF676299),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14.w,
            height: 14.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF1DC230) : const Color(0xFF676299),
            ),
          ),
        ),
      ),
    );
  }

  // ── _buildTab — verbatim from ProfileSetting ──────────────────────────────
  // Wrapped in IntrinsicWidth so the underline Container fills exactly the
  // text width — same visual as ProfileSetting's fixed SizedBox(width:140.w).
  Widget _buildTab(String label, bool isSelected) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? _primaryColor : const Color(0xFF8B8C8E),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // width: double.infinity works here because IntrinsicWidth
          // gives this Column a concrete width equal to the text width.
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
      ),
    );
  }

  // ── Single notification row ────────────────────────────────────────────────
  Widget _buildNotifRow(NotifItem item, int tabIdx, int itemIdx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (itemIdx != 0)
          const Divider(height: 1, color: _dividerColor),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 20.r,
                color: _textColor,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.desc,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _buildToggle(
                value: item.isOn,
                onTap: () => setState(() {
                  _tabs[tabIdx].items[itemIdx].isOn =
                  !_tabs[tabIdx].items[itemIdx].isOn;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Notification card ─────────────────────────────────────────────────────
  Widget _buildNotifCard() {
    final tab = _tabs[_selectedTab];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: _shadowBlack08,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
            child: Text(
              tab.label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
          ...List.generate(
            tab.items.length,
                (i) => _buildNotifRow(tab.items[i], _selectedTab, i),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back arrow + title ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 16.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Notification Settings',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),

            // ── Tab row ────────────────────────────────────────────────────
            // SizedBox gives a bounded height so the horizontal scroll view
            // never gets infinite vertical constraint.
            // IntrinsicWidth inside each tab item makes the underline fill
            // exactly the text width — matching ProfileSetting visually.
            SizedBox(
              height: 36.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_tabs.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < _tabs.length - 1 ? 20.w : 0,
                        ),
                        child: _buildTab(_tabs[i].label, _selectedTab == i),
                      ),
                    );
                  }),
                ),
              ),
            ),

            SizedBox(height: 14.h),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 15.w,
                  right: 15.w,
                  bottom: 16.h,
                ),
                child: Column(
                  children: [
                    _buildNotifCard(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }
}