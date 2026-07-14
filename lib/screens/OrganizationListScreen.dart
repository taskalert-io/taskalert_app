// ignore_for_file: deprecated_member_use, file_names
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/organization/controllers/organization_controller.dart';
import '../core/features/organization/data/models/organization_model.dart';
import '../utils/injection_container.dart';

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);

  late final OrganizationController organizationController;

  // ── Autocomplete plumbing ────────────────────────────────────────────────
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;
  List<OrganizationModel> _suggestions = [];

  final Set<String> _selectedIds = {};

  bool _matchesQuery(OrganizationModel o, String q) =>
      o.name.toLowerCase().contains(q) ||
      o.email.toLowerCase().contains(q) ||
      o.phoneNumber.toLowerCase().contains(q);

  List<OrganizationModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final orgs = organizationController.organizations;
    if (q.isEmpty) return orgs;
    return orgs.where((o) => _matchesQuery(o, q)).toList();
  }

  bool _isAllSelected(List<OrganizationModel> filtered) =>
      filtered.isNotEmpty && _selectedIds.length == filtered.length;

  @override
  void initState() {
    super.initState();
    organizationController = sl<OrganizationController>();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      organizationController.handleGetOrganizations();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _removeSuggestionsOverlay();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _updateSuggestions(_searchController.text);
    } else {
      // Small delay so a tap on a suggestion registers before we tear
      // the overlay down (otherwise the overlay disappears first and
      // the tap never lands).
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _removeSuggestionsOverlay();
        }
      });
    }
  }

  void _onSearchChanged() {
    setState(() {});
    _updateSuggestions(_searchController.text);
  }

  // ── Autocomplete: build match list + show/hide overlay ──────────────────
  void _updateSuggestions(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      _suggestions = [];
      _removeSuggestionsOverlay();
      return;
    }

    _suggestions = organizationController.organizations
        .where((o) => _matchesQuery(o, q))
        .take(6)
        .toList();

    if (_suggestions.isEmpty || !_searchFocusNode.hasFocus) {
      _removeSuggestionsOverlay();
      return;
    }

    _showSuggestionsOverlay();
  }

  void _showSuggestionsOverlay() {
    _removeSuggestionsOverlay();

    final overlay = Overlay.of(context);
    _suggestionsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: _searchBoxWidth,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, _searchBoxHeight + 6.h),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.building_2_fill,
                            size: 14.r,
                            color: const Color(0xFF4338CA),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1D2939),
                                  ),
                                ),
                                Text(
                                  "${s.email} • ${s.phoneNumber}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_suggestionsOverlay!);
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  void _selectSuggestion(OrganizationModel org) {
    _searchController.removeListener(_onSearchChanged);
    _searchController.text = org.name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchController.addListener(_onSearchChanged);

    setState(() {});

    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
  }

  // Search box measurements used to size/position the overlay.
  double get _searchBoxHeight => 40.h;
  double get _searchBoxWidth =>
      MediaQuery.of(context).size.width - 15.w * 2 - 5.w - 130.w;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds
          ..clear()
          ..addAll(_filtered.map((o) => o.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(OrganizationModel organization) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Delete Organization",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"${organization.name}\"?",
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
              "Delete",
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

    if (shouldDelete == true) {
      final success = await organizationController.handleDeleteOrganization(
        id: organization.id,
      );

      if (!mounted) return;

      setState(() {
        _selectedIds.remove(organization.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (organizationController.successMessage ??
                      "Organization deleted")
                : (organizationController.errorMessage ??
                      "Failed to delete organization"),
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
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
      drawer: CustomDrawer(activeTile: "Organizations", onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: organizationController,
        builder: (context, _) {
          final filtered = _filtered;
          final isInitialLoading =
              organizationController.isLoading &&
              organizationController.organizations.isEmpty;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _searchFocusNode.unfocus(),
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
                        "Organization List",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search + Add Organization
                  Row(
                    children: [
                      Expanded(
                        child: CompositedTransformTarget(
                          link: _searchLayerLink,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF344054),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Search Organization",
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
                                        _searchFocusNode.unfocus();
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
                          onPressed: () => openOrganizationFormDialog(
                            context: context,
                            organizationController: organizationController,
                          ),
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
                            "Add Organization",
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
                          // Header row
                          Padding(
                            padding: EdgeInsets.only(
                              left: 10.w,
                              right: 0,
                              top: 10.h,
                              bottom: 10.h,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isAllSelected(filtered),
                                  activeColor: const Color(0xFF0A0258),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: _toggleSelectAll,
                                ),
                                Expanded(
                                  child: Text(
                                    "Organizations",
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
                                SizedBox(width: 12.w),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE4E7EC)),

                          // Rows
                          Expanded(
                            child: isInitialLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      "No organizations found",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF9AA0AB),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: organizationController
                                        .handleGetOrganizations,
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFE4E7EC),
                                          ),
                                      itemBuilder: (context, index) {
                                        final organization = filtered[index];
                                        final isChecked = _selectedIds.contains(
                                          organization.id,
                                        );

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 10.h,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: isChecked,
                                                activeColor: const Color(
                                                  0xFF0A0258,
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onChanged: (v) => setState(() {
                                                  if (v == true) {
                                                    _selectedIds.add(
                                                      organization.id,
                                                    );
                                                  } else {
                                                    _selectedIds.remove(
                                                      organization.id,
                                                    );
                                                  }
                                                }),
                                              ),
                                              SizedBox(width: 8.w),
                                              CircleAvatar(
                                                radius: 18.r,
                                                backgroundColor: const Color(
                                                  0xFFEFF0FF,
                                                ),
                                                backgroundImage:
                                                    (organization
                                                                .image
                                                                ?.thumbnailUrl !=
                                                            null &&
                                                        organization
                                                            .image!
                                                            .thumbnailUrl!
                                                            .isNotEmpty)
                                                    ? NetworkImage(
                                                        organization
                                                            .image!
                                                            .thumbnailUrl!,
                                                      )
                                                    : null,
                                                child:
                                                    (organization
                                                                .image
                                                                ?.thumbnailUrl ==
                                                            null ||
                                                        organization
                                                            .image!
                                                            .thumbnailUrl!
                                                            .isEmpty)
                                                    ? Icon(
                                                        CupertinoIcons
                                                            .building_2_fill,
                                                        size: 16.r,
                                                        color: const Color(
                                                          0xFF4338CA,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(width: 10.w),
                                              // Name + phone + email, stacked
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      organization.name,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF1D2939,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Wrap(
                                                      spacing: 4.w,
                                                      runSpacing: 4.h,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              CupertinoIcons
                                                                  .phone_fill,
                                                              size: 11.r,
                                                              color:
                                                                  const Color(
                                                                    0xFF4338CA,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              width: 4.w,
                                                            ),
                                                            Text(
                                                              organization
                                                                  .phoneNumber,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    const Color(
                                                                      0xFF4338CA,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(width: 6.w),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              CupertinoIcons
                                                                  .mail_solid,
                                                              size: 11.r,
                                                              color:
                                                                  const Color(
                                                                    0xFF9AA0AB,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              width: 4.w,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                organization
                                                                    .email,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: GoogleFonts.inter(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: const Color(
                                                                    0xFF667085,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if ((organization
                                                                    .address
                                                                    ?.city ??
                                                                '')
                                                            .isNotEmpty) ...[
                                                          SizedBox(width: 6.w),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .location_solid,
                                                                size: 11.r,
                                                                color:
                                                                    const Color(
                                                                      0xFF9AA0AB,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                width: 4.w,
                                                              ),
                                                              Text(
                                                                organization
                                                                    .address!
                                                                    .city,
                                                                style: GoogleFonts.inter(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: const Color(
                                                                    0xFF667085,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Actions
                                              PopupMenuButton<String>(
                                                padding: EdgeInsets.zero,
                                                offset: Offset(0, 34.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8.h,
                                                    right: 8.w,
                                                  ),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      6.r,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFD9DEE5,
                                                        ),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .chevron_down,
                                                      size: 13.r,
                                                      color: const Color(
                                                        0xFF344054,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    openOrganizationFormDialog(
                                                      context: context,
                                                      organizationController:
                                                          organizationController,
                                                      existing: organization,
                                                    );
                                                  } else if (value ==
                                                      'delete') {
                                                    _confirmDelete(
                                                      organization,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons.pencil,
                                                          size: 16.r,
                                                          color: const Color(
                                                            0xFF17C3B2,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          "Edit",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons.delete,
                                                          size: 16.r,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          "Delete",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 12.sp,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
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

// ── Reusable Organization create/edit dialog ────────────────────────────
//
// Extracted to a top-level function (not a State method), matching the
// pattern used by `openLocationFormDialog`/`openDepartmentFormDialog`, so
// other screens could reuse the exact same create/edit UI if ever needed.
void openOrganizationFormDialog({
  required BuildContext context,
  required OrganizationController organizationController,
  OrganizationModel? existing,
  ValueChanged<OrganizationModel>? onCreated,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: existing?.name ?? "");
  final emailCtrl = TextEditingController(text: existing?.email ?? "");
  final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? "");
  final streetCtrl = TextEditingController(
    text: existing?.address?.street ?? "",
  );
  final cityCtrl = TextEditingController(text: existing?.address?.city ?? "");
  final stateCtrl = TextEditingController(text: existing?.address?.state ?? "");
  final countryCtrl = TextEditingController(
    text: existing?.address?.country ?? "",
  );
  final pincodeCtrl = TextEditingController(
    text: existing?.address?.pinCode ?? "",
  );
  File? selectedImageFile;
  bool autoValidate = false;
  bool isSubmitting = false;
  // Only enforced on create — an existing organization being edited may
  // already have a logo on the server that just isn't re-picked locally.
  String? logoError;
  // Shown inline in the form instead of a SnackBar — a SnackBar anchored
  // to the page behind this modal sheet renders underneath it and is easy
  // to miss.
  String? formErrorMessage;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    // Handle bar
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
                          existing == null
                              ? "Add New Organization"
                              : "Edit Organization",
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

                    _orgImageUploadField(
                      imageFile: selectedImageFile,
                      existingImageUrl:
                          existing?.image?.thumbnailUrl ??
                          existing?.image?.originalUrl,
                      required: existing == null,
                      errorText: logoError,
                      onTap: () => _pickOrgImage(
                        context: ctx,
                        onPicked: (file) => ss(() {
                          selectedImageFile = file;
                          logoError = null;
                        }),
                      ),
                      onRemove: selectedImageFile == null
                          ? null
                          : () => ss(() => selectedImageFile = null),
                    ),
                    SizedBox(height: 12.h),

                    // Organization Name
                    _formField(
                      label: "Organization Name",
                      required: true,
                      controller: nameCtrl,
                      hint: "Organization Name",
                      validator: (v) {
                        final val = (v ?? "").trim();
                        if (val.isEmpty) return "Enter organization name";
                        if (val.length < 2) {
                          return "Name must be at least 2 characters";
                        }
                        return null;
                      },
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
                    SizedBox(height: 12.h),

                    // Phone
                    _formField(
                      label: "Phone",
                      required: true,
                      controller: phoneCtrl,
                      hint: "10-digit phone number",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          10,
                        ), // Blocks input after 10 characters
                        FilteringTextInputFormatter
                            .digitsOnly, // Optional: Ensures only numbers can be typed
                      ],
                      validator: (v) {
                        final digits = (v ?? "").trim();
                        if (digits.isEmpty) return "Enter phone number";
                        if (digits.length != 10) {
                          return "Enter a valid 10-digit number";
                        }
                        return null;
                      },
                    ),
                    // _formField(
                    //   label: "Phone",
                    //   required: true,
                    //   controller: phoneCtrl,
                    //   hint: "10-digit phone number",
                    //   keyboardType: TextInputType.number,
                    //   validator: (v) {
                    //     final digits = (v ?? "").trim();
                    //     if (digits.isEmpty) return "Enter phone number";
                    //     if (digits.length != 10) {
                    //       return "Enter a valid 10-digit number";
                    //     }
                    //     return null;
                    //   },
                    // ),
                    SizedBox(height: 12.h),

                    // Street
                    _formField(
                      label: "Street",
                      controller: streetCtrl,
                      hint: "Street Address",
                    ),
                    SizedBox(height: 12.h),

                    // City + State
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            label: "City",
                            controller: cityCtrl,
                            hint: "City",
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _formField(
                            label: "State",
                            controller: stateCtrl,
                            hint: "State",
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Country + Pincode
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            label: "Country",
                            controller: countryCtrl,
                            hint: "Country",
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _formField(
                            label: "Pincode",
                            controller: pincodeCtrl,
                            hint: "Pincode",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),

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
                                      logoError =
                                          (existing == null &&
                                              selectedImageFile == null)
                                          ? "Logo is required"
                                          : null;
                                    });
                                    final formValid =
                                        formKey.currentState?.validate() ??
                                        false;
                                    if (!formValid || logoError != null) {
                                      return;
                                    }

                                    ss(() => isSubmitting = true);

                                    final bool success;
                                    if (existing == null) {
                                      success = await organizationController
                                          .handleCreateOrganization(
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phoneNumber: phoneCtrl.text.trim(),
                                            street: streetCtrl.text.trim(),
                                            city: cityCtrl.text.trim(),
                                            state: stateCtrl.text.trim(),
                                            country: countryCtrl.text.trim(),
                                            pinCode: pincodeCtrl.text.trim(),
                                            imageFilePath:
                                                selectedImageFile?.path,
                                          );
                                    } else {
                                      success = await organizationController
                                          .handleUpdateOrganization(
                                            id: existing.id,
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phoneNumber: phoneCtrl.text.trim(),
                                            street: streetCtrl.text.trim(),
                                            city: cityCtrl.text.trim(),
                                            state: stateCtrl.text.trim(),
                                            country: countryCtrl.text.trim(),
                                            pinCode: pincodeCtrl.text.trim(),
                                            imageFilePath:
                                                selectedImageFile?.path,
                                          );
                                    }

                                    if (!context.mounted) return;
                                    ss(() => isSubmitting = false);

                                    if (success) {
                                      Navigator.pop(ctx);
                                      if (existing == null &&
                                          onCreated != null) {
                                        final created = organizationController
                                            .organizations
                                            .where(
                                              (o) =>
                                                  o.name ==
                                                  nameCtrl.text.trim(),
                                            )
                                            .firstOrNull;
                                        if (created != null) {
                                          onCreated(created);
                                        }
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            organizationController
                                                    .successMessage ??
                                                (existing == null
                                                    ? "Organization created successfully!"
                                                    : "Organization updated successfully!"),
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
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ss(
                                        () => formErrorMessage =
                                            organizationController
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
                                    existing == null
                                        ? "Create Organization"
                                        : "Save Changes",
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

Widget _orgImageUploadField({
  required File? imageFile,
  required VoidCallback onTap,
  VoidCallback? onRemove,
  bool required = false,
  String? errorText,
  // Shown when editing and no new local file has been picked yet — the
  // organization's current logo URL from the server.
  String? existingImageUrl,
}) {
  final hasExistingImage =
      imageFile == null &&
      existingImageUrl != null &&
      existingImageUrl.isNotEmpty;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          text: "Logo",
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
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFD9DEE5)),
                  ),
                  child: imageFile != null
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : hasExistingImage
                      ? Image.network(
                          existingImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image_outlined,
                            size: 20.r,
                            color: const Color(0xFF9AA0AB),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 16.r,
                              color: const Color(0xFF6C7278),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Upload",
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: const Color(0xFF6C7278),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
                if (imageFile != null && onRemove != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 11.r,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "The image format is .jpg .jpeg .png and a minimum size of 300 X 300px",
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                color: const Color(0xFF9AA0AB),
              ),
            ),
          ),
        ],
      ),
      if (errorText != null) ...[
        SizedBox(height: 4.h),
        Text(
          errorText,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.red),
        ),
      ],
    ],
  );
}

Future<void> _pickOrgImage({
  required BuildContext context,
  required ValueChanged<File> onPicked,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7EC),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 12.h),
          ListTile(
            leading: const Icon(
              CupertinoIcons.camera_fill,
              color: Color(0xFF0A0258),
            ),
            title: Text(
              "Take Photo",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(
              CupertinoIcons.photo_fill_on_rectangle_fill,
              color: Color(0xFF0A0258),
            ),
            title: Text(
              "Choose from Gallery",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    ),
  );

  if (source == null) return;

  try {
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      onPicked(File(picked.path));
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Couldn't access camera/gallery: $e",
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Widget _formField({
  required String label,
  required TextEditingController controller,
  required String hint,
  bool required = false,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  List<TextInputFormatter>? inputFormatters, // 1. Add this parameter
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
        inputFormatters: inputFormatters, // 2. Pass it down here
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
