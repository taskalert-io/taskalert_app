import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/core/features/auth/controllers/login_controller.dart';
import 'package:taskalert_app/core/features/sidebar/controllers/sidebar_controller.dart';
import 'package:taskalert_app/core/features/sidebar/data/models/sidebar_config_model.dart';
import 'package:taskalert_app/screens/DepartmentListScreen.dart';
import 'package:taskalert_app/screens/HomeScreen.dart';
import 'package:taskalert_app/screens/InvitationScreen.dart';
import 'package:taskalert_app/screens/LocationListScreen.dart';
import 'package:taskalert_app/screens/MoreScreen.dart';
import 'package:taskalert_app/screens/MyTaskScreen.dart';
import 'package:taskalert_app/screens/OrganizationListScreen.dart';
import 'package:taskalert_app/screens/ProfileSetting.dart';
import 'package:taskalert_app/screens/SignInScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart';

import '../screens/EmployeesScreen.dart';

/// Maps a known drawer destination (icon + real screen, both local-only —
/// the sidebar API has neither) to whichever `key`/`label` the backend
/// might use to refer to it, so the fixed set of built screens can be
/// filtered down to whatever the logged-in user's sidebar config actually
/// grants. `screenBuilder` is nullable for entries whose screen isn't built
/// yet (Dashboard/Work Flow currently) — those still get their own
/// icon/title but fall back to the same "under development" snackbar as an
/// unmapped API item.
class _DrawerEntryDef {
  final List<String> matchKeys;
  final String title;
  final IconData icon;
  final Widget Function()? screenBuilder;

  const _DrawerEntryDef({
    required this.matchKeys,
    required this.title,
    required this.icon,
    this.screenBuilder,
  });

  bool matches(SidebarItemModel item) {
    final key = item.key.toLowerCase();
    final label = item.label.toLowerCase();
    return matchKeys.any((m) => m == key || m == label);
  }
}

/// Always shown, first in the drawer — the app's own landing screen, not
/// part of the organization permission model the sidebar API governs.
final _homeEntry = _DrawerEntryDef(
  matchKeys: const ['home'],
  title: 'Home',
  icon: Icons.home_outlined,
  screenBuilder: () => HomeScreen(userId: ''),
);

/// Driven by `GET /sidebar/...` — only shown when the logged-in user's
/// config includes a matching `key`/`label`. Order here doubles as the
/// fallback order shown before the config has loaded.
final List<_DrawerEntryDef> _apiGatedDrawerEntries = [
  _DrawerEntryDef(
    matchKeys: const ['dashboard'],
    title: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
  ),
  _DrawerEntryDef(
    matchKeys: const ['workflow', 'work flow', 'work_flow'],
    title: 'Work Flow',
    icon: Icons.account_tree_outlined,
  ),
  _DrawerEntryDef(
    matchKeys: const ['tasks'],
    title: 'Tasks',
    icon: Icons.checklist_outlined,
    screenBuilder: () => MyTaskScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['users', 'employees', 'employee'],
    title: 'Employees',
    icon: Icons.supervised_user_circle_outlined,
    screenBuilder: () => EmployeesScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['invitations', 'invitation'],
    title: 'Invitations',
    icon: Icons.mail_outline,
    screenBuilder: () => InvitationScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['organizations', 'organization'],
    title: 'Organizations',
    icon: Icons.business_outlined,
    screenBuilder: () => OrganizationListScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['department', 'departments'],
    title: 'Department',
    icon: Icons.layers,
    screenBuilder: () => DepartmentListScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['location', 'locations'],
    title: 'Location',
    icon: Icons.location_on,
    screenBuilder: () => LocationListScreen(userId: ''),
  ),
  _DrawerEntryDef(
    matchKeys: const ['settings'],
    title: 'Settings',
    icon: Icons.settings_outlined,
    screenBuilder: () => MoreScreen(userId: ''),
  ),
];

/// Always shown, last in the drawer (before Logout) — account-level
/// screens, not part of the organization permission model either.
final List<_DrawerEntryDef> _accountDrawerEntries = [
  _DrawerEntryDef(
    matchKeys: const ['user', 'profile'],
    title: 'User',
    icon: Icons.person_outline,
    screenBuilder: () => ProfileSetting(userId: ''),
  ),
];

class CustomDrawer extends StatefulWidget {
  final String activeTile;
  final Function(String) onTileTap;

  const CustomDrawer({
    super.key,
    required this.activeTile,
    required this.onTileTap,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  String activeTile = '';
  String userName = "User";
  String userEmail = "";
  String userThumbnail = "";

  final _loginController = sl<LoginController>();
  final _sidebarController = sl<SidebarController>();

  @override
  void initState() {
    super.initState();
    // Set synchronously so the correct tile is already highlighted on the
    // very first frame, instead of relying on a later setState (e.g. from
    // loadUserData) to incidentally pick up the value.
    activeTile = widget.activeTile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loginController.handleGetProfile();
        loadUserData();
        _loadSidebarConfig();
      }
    });
    // _loginController.addListener(_onControllerChanged);
  }

  Future<void> _loadSidebarConfig() async {
    await _sidebarController.handleGetSidebarConfiguration();
    // Not listening to the controller reactively (this file manages its own
    // state via setState everywhere else) — just rebuild once the fetch
    // settles so the menu can switch from the full fallback list to
    // whatever the user's config actually grants.
    if (mounted) setState(() {});
  }

  /// Builds the actual list of drawer menu widgets. Falls back to the full
  /// fixed menu (the exact same list this drawer always showed) whenever
  /// the sidebar config hasn't loaded yet or failed to load, so nothing
  /// regresses if the API is slow or unavailable. Once loaded, only shows
  /// the known screens the config actually grants, plus any sidebar items
  /// the backend returns that don't map to a screen here yet (using the
  /// existing "under development" fallback already built into
  /// buildDrawerItem for those).
  Widget _drawerItemFor(_DrawerEntryDef entry) => buildDrawerItem(
    title: entry.title,
    icon: entry.icon,
    destinationScreen: entry.screenBuilder?.call(),
  );

  List<Widget> _buildMenuItems() {
    final apiItems = _sidebarController.config?.sidebar;
    final homeItem = _drawerItemFor(_homeEntry);
    final accountItems = _accountDrawerEntries.map(_drawerItemFor).toList();

    if (apiItems == null) {
      // Sidebar config not loaded yet (or failed) — show the full fixed
      // menu, in the same shape this drawer always showed, so nothing
      // regresses while the API is unavailable.
      final fallbackGated = _apiGatedDrawerEntries.map(_drawerItemFor).toList();
      return [homeItem, ...fallbackGated, ...accountItems];
    }

    final matched = <Widget>[];
    final usedApiItems = <SidebarItemModel>{};

    for (final entry in _apiGatedDrawerEntries) {
      SidebarItemModel? match;
      for (final item in apiItems) {
        if (entry.matches(item)) {
          match = item;
          break;
        }
      }
      if (match != null) {
        matched.add(_drawerItemFor(entry));
        usedApiItems.add(match);
      }
    }

    // Any API-granted item that doesn't map to a known entry yet — still
    // show it (using the API's own label) so the menu stays truthful to
    // what the backend says this user can access, via the same "under
    // development" fallback buildDrawerItem already has for a null
    // destinationScreen.
    final extraFromApi = apiItems
        .where((item) => !usedApiItems.contains(item))
        .map(
          (item) =>
              buildDrawerItem(title: item.label, icon: Icons.circle_outlined),
        )
        .toList();

    return [homeItem, ...matched, ...extraFromApi, ...accountItems];
  }

  Future<void> loadUserData() async {
    String? storedFirstName = await storage.read(key: "user_first_name");
    String? storedLastName = await storage.read(key: "user_last_name");
    String? storedName = (storedFirstName != null && storedLastName != null)
        ? "$storedFirstName $storedLastName"
        : null;
    String? storedEmail = await storage.read(key: "user_email");

    String? storedThumbnail = await storage.read(key: "user_avatar_thumbnail");

    setState(() {
      userName = storedName ?? "User";
      userEmail = storedEmail ?? "";
      userThumbnail = storedThumbnail ?? "assets/images/profile.png";
    });
  }

  Widget buildDrawerItem({
    required String title,
    required IconData icon,
    Widget? destinationScreen,
  }) {
    bool isSelected = activeTile == title;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            // Already on this tile's screen — just close the drawer instead
            // of pushing a duplicate instance of the same screen.
            if (title == widget.activeTile) {
              Navigator.pop(context);
              return;
            }

            setState(() {
              activeTile = title;
            });

            widget.onTileTap(title);

            // Resolve the messenger before popping the drawer so it's safe
            // to use even after this widget's context is torn down.
            final messenger = ScaffoldMessenger.of(context);

            Navigator.pop(context);

            if (destinationScreen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinationScreen),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('$title is under development'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF1F4F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: isSelected
                      ? const Color(0xFF0A0258)
                      : const Color(0xFF7B8AA0),
                ),

                SizedBox(width: 10.w),

                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF0A0258)
                          : const Color(0xFF344054),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Get the bottom system padding (navigation bar height) from MediaQuery.
    // This ensures the user info footer is always above the system navigation bar.
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Drawer(
      width: 280.w,
      backgroundColor: Colors.white,
      // FIX: Remove SafeArea from here. We handle insets manually below
      // so the footer padding is precise and doesn't double-apply.
      child: Column(
        children: [
          /// TOP SAFE AREA — only top inset needed here
          SizedBox(height: MediaQuery.of(context).padding.top),

          /// HEADER
          Container(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              top: 20.h,
              bottom: 16.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// LOGO
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(userId: ''),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/prologoadd.png",
                          width: 45.w,
                          height: 34.h,
                          fit: BoxFit.contain,
                        ),

                        SizedBox(width: 8.w),

                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                /// TASK
                                Text(
                                  "task",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0B045A),
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                /// ALERT
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF7B61FF),
                                        Color(0xFF4FE0C5),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "alert",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                /// .IO
                                Text(
                                  ".io",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0B045A),
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                /// CLOSE BUTTON
<<<<<<< Updated upstream
                // InkWell(
                //   onTap: () {
                //     Navigator.pop(context);
                //   },
                //   borderRadius: BorderRadius.circular(100.r),
                //   child: Container(
                //     width: 26.w,
                //     height: 26.h,
                //     decoration: const BoxDecoration(
                //       shape: BoxShape.circle,
                //       color: Color(0xFFF4F4F4),
                //     ),
                //     child: Icon(
                //       Icons.close,
                //       size: 15.sp,
                //       color: const Color(0xFF0A0258),
                //     ),
                //   ),
                // ),
=======
>>>>>>> Stashed changes
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24.r,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
                  icon: Container(
                    width: 26.w,
                    height: 26.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF4F4F4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      size: 15.sp,
                      color: const Color(0xFF0A0258),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// MENU LIST
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._buildMenuItems(),
                SizedBox(height: 10.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    // 🌟 CHANGED: Call the confirmation dialog instead of a direct logout
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible:
                            false, // User must explicitly tap a choice button
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            title: Text(
                              "Logout Account",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                                color: const Color(0xFF1E1E24),
                              ),
                            ),
                            content: Text(
                              "Are you sure you want to sign out? You will need to verify your phone number again to access your account.",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            actions: [
                              // Cancel option
                              TextButton(
                                onPressed: () => Navigator.pop(
                                  dialogContext,
                                ), // Close popup safely
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              // Destructive confirm logout action
                              TextButton(
                                onPressed: () async {
                                  // 1. Pop the open dialog context box layer out immediately
                                  Navigator.pop(dialogContext);

                                  // 2. Clear out local secure storage variables via your controller workflow
                                  await _loginController.handleLogout();
                                  // Clear the cached sidebar config too — it's
                                  // an app-wide singleton, so it'd otherwise
                                  // still hold this user's menu the next
                                  // time someone signs in this session.
                                  _sidebarController.reset();

                                  if (!context.mounted) return;

                                  // 3. Purge historical routes and push clean back to the original sign in interface
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInScreen(), // Adjust to match your exact Sign In widget class name
                                    ),
                                    (Route<dynamic> route) =>
                                        false, // Erases the backward view stack array history completely
                                  );
                                },
                                child: Text(
                                  "Logout",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                        top: 10.h,
                        bottom: 10.h,
                        left: 14.w,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.logout,
                            color: const Color(0xFFB71C1C),
                            size: 15.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            "Logout",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB71C1C),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),

          /// USER INFO
          /// FIX: bottomPadding is added to the container's bottom padding
          /// so the user info section always sits above the system nav bar.
          Container(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              top: 16.h,
              // Add the system navigation bar height here so the content
              // never gets hidden behind the gesture bar / nav buttons.
              bottom: 16.h + bottomPadding,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundImage: userThumbnail.isNotEmpty
                      ? NetworkImage(userThumbnail)
                      : const AssetImage("assets/images/profile.png")
                            as ImageProvider,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF324054),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        userEmail,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF71839B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
