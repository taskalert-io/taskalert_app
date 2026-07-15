import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/core/features/organization/controllers/organization_controller.dart';
import 'package:taskalert_app/core/features/sidebar/controllers/sidebar_controller.dart';
import 'package:taskalert_app/screens/HomeScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final OrganizationController _organizationController =
      sl<OrganizationController>();

  String? _activeOrganizationId;

  @override
  void initState() {
    super.initState();
    _loadActiveOrganization();
  }

  Future<void> _loadActiveOrganization() async {
    _activeOrganizationId = await _secureStorage.read(
      key: 'user_active_organization_id',
    );
    await _organizationController.handleGetMyOrganization();
    if (mounted) setState(() {});
  }

  /// Opens the "switch organization" sheet. The full organizations list is
  /// only fetched the first time this is opened (not on every AppBar
  /// build), matching the on-demand-fetch pattern used by other filter
  /// sheets in the app.
  Future<void> _openOrganizationSwitcher() async {
    if (_organizationController.organizations.isEmpty) {
      await _organizationController.handleGetOrganizations();
    }
    if (!mounted) return;

    // Tracks which row (if any) currently has a switch call in flight, so
    // only that row shows a spinner and every row is disabled meanwhile.
    String? switchingToId;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetCtx, ss) => AnimatedBuilder(
          animation: _organizationController,
          builder: (context, _) {
            final orgs = _organizationController.organizations;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E7EC),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Text(
                        "My Organizations",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ),
                    if (_organizationController.isLoading && orgs.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (orgs.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 30.h,
                          horizontal: 20.w,
                        ),
                        child: Center(
                          child: Text(
                            "No organizations found",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF9AA0AB),
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: orgs.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (context, index) {
                            final org = orgs[index];
                            final isActive = org.id == _activeOrganizationId;
                            final isSwitching = switchingToId == org.id;
                            final thumbnailUrl = org.image?.thumbnailUrl;

                            return InkWell(
                              onTap: (isActive || switchingToId != null)
                                  ? null
                                  : () async {
                                      ss(() => switchingToId = org.id);
                                      bool success = false;
                                      try {
                                        success = await _organizationController
                                            .handleSwitchOrganization(
                                              organizationId: org.id,
                                            );
                                      } finally {
                                        ss(() => switchingToId = null);
                                      }

                                      if (!sheetCtx.mounted) return;

                                      if (success) {
                                        // The permission set is scoped to
                                        // the active organization — force a
                                        // real refetch instead of reusing
                                        // whichever org's menu was cached
                                        // before.
                                        await sl<SidebarController>()
                                            .handleGetSidebarConfiguration(
                                              forceRefresh: true,
                                            );

                                        if (sheetCtx.mounted) {
                                          Navigator.pop(sheetCtx);
                                        }
                                        if (!mounted) return;
                                        // Full app data refresh: every
                                        // screen/controller in this app
                                        // fetches its own org-scoped data
                                        // once, on mount — there's no
                                        // global cache to invalidate, so
                                        // the reliable way to refresh
                                        // everything is to tear down the
                                        // whole navigation stack and land
                                        // on a brand-new Home screen.
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                HomeScreen(userId: ''),
                                          ),
                                          (route) => false,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          sheetCtx,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _organizationController
                                                      .errorMessage ??
                                                  "Could not switch organization.",
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 10.h,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: const Color(0xFFEFF0FF),
                                      backgroundImage:
                                          (thumbnailUrl != null &&
                                              thumbnailUrl.isNotEmpty)
                                          ? NetworkImage(thumbnailUrl)
                                          : null,
                                      child:
                                          (thumbnailUrl != null &&
                                              thumbnailUrl.isNotEmpty)
                                          ? null
                                          : Icon(
                                              Icons.business_rounded,
                                              size: 14.r,
                                              color: const Color(0xFF4338CA),
                                            ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        org.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: const Color(0xFF1D2939),
                                        ),
                                      ),
                                    ),
                                    if (isSwitching)
                                      SizedBox(
                                        width: 16.r,
                                        height: 16.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else if (isActive)
                                      Icon(
                                        Icons.check_circle,
                                        size: 18.r,
                                        color: const Color(0xFF0A0258),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _organizationAvatarButton() {
    final org = _organizationController.myOrganization;
    final thumbnailUrl = org?.image?.thumbnailUrl;
    final name = org?.name;
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: _openOrganizationSwitcher,
        child: Container(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 8.w,
            top: 3.h,
            bottom: 3.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22.w,
                height: 22.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF0FF),
                ),
                child: ClipOval(
                  child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.business_rounded,
                            size: 12.r,
                            color: const Color(0xFF4338CA),
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          size: 12.r,
                          color: const Color(0xFF4338CA),
                        ),
                ),
              ),
              if (name != null && name.isNotEmpty) ...[
                SizedBox(width: 6.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 72.w),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF17134A),
                    ),
                  ),
                ),
              ],
              SizedBox(width: 2.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16.r,
                color: const Color(0xFF9AA0AB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F7FB),

      leading: Padding(
        padding: const EdgeInsets.only(left: 12),

        child: widget.showLeading
            ? IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF0A0258),
                  size: 24.r,
                ),

                onPressed: () {
                  widget.scaffoldKey.currentState?.openDrawer();
                },
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0A0258),
                  size: 20.r,
                ),

                onPressed:
                    widget.onBackPressed ??
                    () {
                      Navigator.pop(context);
                    },
              ),
      ),

      titleSpacing: 0,

      title: SizedBox(
        width: 120.w,

        child: Image.asset('assets/images/main_logo.png', fit: BoxFit.contain),
      ),

      actions: [_organizationAvatarButton()],
    );
  }
}
