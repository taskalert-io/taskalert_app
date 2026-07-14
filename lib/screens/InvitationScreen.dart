// ignore_for_file: deprecated_member_use, file_names
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/invitation/controllers/invitation_controller.dart';
import '../core/features/invitation/data/models/invitation_model.dart';
import '../core/features/organization/controllers/organization_controller.dart';
import '../core/features/organization/data/models/organization_model.dart';
import '../utils/injection_container.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key, required this.userId});
  final String userId;

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);

  late final InvitationController invitationController =
      sl<InvitationController>();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      invitationController.handleGetInvitations();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Search hits the backend (InvitationRepository.getInvitations(search:)),
  // not a local filter — debounce so it doesn't fire on every keystroke.
  void _onSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      invitationController.handleGetInvitations(
        search: _searchController.text.trim(),
      );
    });
  }

  // Backend timestamps are UTC — convert to a fixed IST (UTC+5:30) offset
  // for display rather than `.toLocal()`, which would instead follow
  // whatever timezone the device happens to be set to.
  DateTime _toIst(DateTime dt) =>
      dt.toUtc().add(const Duration(hours: 5, minutes: 30));

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF0DA99E);
      case 'expired':
      case 'revoked':
        return Colors.red;
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmRevoke(Invitation invitation) async {
    final label = invitation.invitedTo?.fullName.isNotEmpty ?? false
        ? invitation.invitedTo!.fullName
        : (invitation.invitedTo?.email ?? 'this invitation');

    final bool? shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Revoke Invitation",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to revoke the invitation for \"$label\"?",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF324054),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Revoke",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldRevoke != true) return;

    final success = await invitationController.handleRevokeInvitation(
      invitation.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Invitation revoked"
              : (invitationController.errorMessage ??
                    "Failed to revoke invitation"),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF0DA99E) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  // ── CREATE ───────────────────────────────────────────────────────────────
  void _openInviteForm() {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool autoValidate = false;
    bool isSubmitting = false;
    String? formErrorMessage;
    OrganizationModel? selectedOrganization;

    // Fresh controller per form-open, matching the pattern used by the
    // other create/edit dialogs in this app — fetch starts immediately,
    // the dropdown below reacts to it via AnimatedBuilder.
    final organizationController = sl<OrganizationController>();
    organizationController.handleGetOrganizations();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10.r,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
                child: Form(
                  key: formKey,
                  autovalidateMode: autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36.w,
                          height: 4.h,
                          margin: EdgeInsets.only(bottom: 14.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9DEE5),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Send Invitation",
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close,
                              size: 20.r,
                              color: const Color(0xFF6C7278),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      if (formErrorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEC),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFFF5B5B5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 15.r,
                                color: Colors.red,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  formErrorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      // Organization — mandatory, sent as organizationId
                      // First Name / Last Name — optional
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              label: "First Name",
                              controller: firstNameCtrl,
                              hint: "First Name",
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _formField(
                              label: "Last Name",
                              controller: lastNameCtrl,
                              hint: "Last Name",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Email
                      _formField(
                        label: "Email",
                        required: true,
                        controller: emailCtrl,
                        hint: "Email",
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final val = (v ?? "").trim();
                          if (val.isEmpty) return "Enter an email";
                          if (!val.contains("@") || !val.contains(".")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 22.h),

                      AnimatedBuilder(
                        animation: organizationController,
                        builder: (context, _) {
                          final organizations =
                              organizationController.organizations;
                          final isLoadingOrgs =
                              organizationController.isLoading &&
                              organizations.isEmpty;
                          // Guard against a stale selection if the list
                          // reloads and that org is no longer present.
                          final dropdownValue =
                              (selectedOrganization != null &&
                                  organizations.any(
                                    (o) => o.id == selectedOrganization!.id,
                                  ))
                              ? selectedOrganization!.id
                              : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: "Organization",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3F3F3F),
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: " *",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              DropdownButtonFormField<String>(
                                initialValue: dropdownValue,
                                isExpanded: true,
                                hint: Text(
                                  isLoadingOrgs
                                      ? "Loading organizations..."
                                      : "Select organization",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFFB8BEC5),
                                  ),
                                ),
                                icon: isLoadingOrgs
                                    ? SizedBox(
                                        width: 14.r,
                                        height: 14.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.keyboard_arrow_down),
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6C7278),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFC),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 10.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD9DEE5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD9DEE5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0A0258),
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                items: organizations
                                    .map(
                                      (org) => DropdownMenuItem<String>(
                                        value: org.id,
                                        child: Text(
                                          org.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isLoadingOrgs
                                    ? null
                                    : (id) => ss(() {
                                        selectedOrganization = organizations
                                            .where((o) => o.id == id)
                                            .firstOrNull;
                                      }),
                                validator: (_) => selectedOrganization == null
                                    ? "Select an organization"
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 12.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      ss(() {
                                        autoValidate = true;
                                        formErrorMessage = null;
                                      });
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }

                                      ss(() => isSubmitting = true);

                                      // Guaranteed non-null here — the
                                      // dropdown's own validator (checked
                                      // above by formKey.validate()) blocks
                                      // submission otherwise.
                                      final organizationId =
                                          selectedOrganization!.id;

                                      final success = await invitationController
                                          .handleCreateInvitation(
                                            firstName: firstNameCtrl.text
                                                .trim(),
                                            lastName: lastNameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            organizationId: organizationId,
                                          );

                                      if (!context.mounted) return;
                                      ss(() => isSubmitting = false);

                                      if (success) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Invitation sent successfully!",
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF0DA99E,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                          ),
                                        );
                                      } else {
                                        ss(
                                          () => formErrorMessage =
                                              invitationController
                                                  .errorMessage ??
                                              "Something went wrong",
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 22.w,
                                  vertical: 12.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: isSubmitting
                                  ? SizedBox(
                                      width: 16.r,
                                      height: 16.r,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Send Invite",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
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
      body: ListenableBuilder(
        listenable: invitationController,
        builder: (context, _) {
          final invitations = invitationController.invitations;
          final isInitialLoading =
              invitationController.isLoading && invitations.isEmpty;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
              color: const Color(0xFFF5F7FB),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      SizedBox(width: 8.w),
                      Text(
                        "Invitations",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search + Invite
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF344054),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Search invitations",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFFB8BEC5),
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: 14.r,
                              color: const Color(0xFF9AA0AB),
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                    },
                                    child: Icon(
                                      CupertinoIcons.clear_circled_solid,
                                      size: 14.r,
                                      color: const Color(0xFF9AA0AB),
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9DEE5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9DEE5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A0258),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2FD5C8), Color(0xFFB16CFF)],
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openInviteForm,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.add,
                            size: 16.r,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Invite",
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // List — card layout
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: 14.w,
                              right: 12.w,
                              top: 10.h,
                              bottom: 10.h,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Invitations",
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D2939),
                                    ),
                                  ),
                                ),
                                Text(
                                  "Actions",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB8BEC5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE4E7EC)),

                          Expanded(
                            child: isInitialLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : invitations.isEmpty
                                ? Center(
                                    child: Text(
                                      "No invitations found",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF9AA0AB),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => invitationController
                                        .handleGetInvitations(
                                          search: _searchController.text.trim(),
                                        ),
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: invitations.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFE4E7EC),
                                          ),
                                      itemBuilder: (context, index) {
                                        final invitation = invitations[index];
                                        final guestName =
                                            invitation.invitedTo?.fullName ??
                                            '';
                                        final guestEmail =
                                            invitation.invitedTo?.email ?? '';
                                        final displayName = guestName.isNotEmpty
                                            ? guestName
                                            : (guestEmail.isNotEmpty
                                                  ? guestEmail
                                                  : 'Unknown');
                                        // Only show the email as its own
                                        // line when it isn't already the
                                        // thing being shown as the name.
                                        final showEmailSeparately =
                                            guestName.isNotEmpty &&
                                            guestEmail.isNotEmpty;
                                        final invitedByName =
                                            invitation.invitedBy?.fullName ??
                                            '';
                                        final isRevoked =
                                            invitation.status.toLowerCase() ==
                                            'revoked';

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                            vertical: 10.h,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 18.r,
                                                backgroundColor: const Color(
                                                  0xFFEFF0FF,
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF4338CA,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      displayName,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF1D2939,
                                                        ),
                                                      ),
                                                    ),
                                                    if (showEmailSeparately) ...[
                                                      SizedBox(height: 2.h),
                                                      Text(
                                                        guestEmail,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 11.5.sp,
                                                              color:
                                                                  const Color(
                                                                    0xFF667085,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                    if (invitedByName
                                                        .isNotEmpty) ...[
                                                      SizedBox(height: 2.h),
                                                      Text(
                                                        "Invited by $invitedByName",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 11.sp,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color:
                                                                  const Color(
                                                                    0xFF9AA0AB,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                    SizedBox(height: 4.h),
                                                    Wrap(
                                                      spacing: 6.w,
                                                      runSpacing: 4.h,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 7.w,
                                                                vertical: 2.h,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: _statusColor(
                                                              invitation.status,
                                                            ).withOpacity(0.12),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10.r,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            invitation
                                                                    .status
                                                                    .isNotEmpty
                                                                ? invitation
                                                                          .status[0]
                                                                          .toUpperCase() +
                                                                      invitation
                                                                          .status
                                                                          .substring(
                                                                            1,
                                                                          )
                                                                : 'Pending',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 10.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  _statusColor(
                                                                    invitation
                                                                        .status,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          invitation.role,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 11.sp,
                                                                color:
                                                                    const Color(
                                                                      0xFF667085,
                                                                    ),
                                                              ),
                                                        ),
                                                        if (invitation
                                                                .expiresAt !=
                                                            null)
                                                          Text(
                                                            "Expires: ${DateFormat('hh:mm a - MMM d, yyyy').format(_toIst(invitation.expiresAt!))}",
                                                            style: GoogleFonts.inter(
                                                              fontSize: 11.sp,
                                                              color:
                                                                  const Color(
                                                                    0xFF9AA0AB,
                                                                  ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!isRevoked)
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: Icon(
                                                    CupertinoIcons.delete,
                                                    size: 17.r,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _confirmRevoke(
                                                        invitation,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}

Widget _formField({
  required String label,
  required TextEditingController controller,
  required String hint,
  bool required = false,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
          children: required
              ? const [
                  TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : null,
        ),
      ),
      SizedBox(height: 4.h),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6C7278),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            color: const Color(0xFFB8BEC5),
          ),
          errorStyle: TextStyle(fontSize: 10.sp),
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 10.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFF0A0258)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    ],
  );
}
