// ignore_for_file: deprecated_member_use, file_names
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/departments/controllers/department_controller.dart';
import '../core/features/departments/data/models/department_model.dart';
import '../core/features/location/controllers/location_controller.dart';
import '../core/features/location/data/models/location_model.dart';
import '../utils/injection_container.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key, required this.userId});
  final String userId;

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);

  late final DepartmentController departmentController;
  late final LocationController locationController;

  // ── Autocomplete plumbing (matches LocationListScreen pattern) ──────────
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;
  List<DepartmentModel> _suggestions = [];

  bool _matchesQuery(DepartmentModel d, String q) =>
      (d.name ?? "").toLowerCase().contains(q) ||
      (d.location?.name?.toLowerCase().contains(q) ?? false);

  List<DepartmentModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final departments = departmentController.departments;
    if (q.isEmpty) return departments;
    return departments.where((d) => _matchesQuery(d, q)).toList();
  }

  @override
  void initState() {
    super.initState();
    departmentController = sl<DepartmentController>();
    locationController = sl<LocationController>();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      departmentController.handleGetDepartments();
      locationController.handleGetLocations();
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

    _suggestions = departmentController.departments
        .where((d) => _matchesQuery(d, q))
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
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.square_grid_2x2,
                            size: 14.r,
                            color: const Color(0xFF4338CA),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              s.name ?? "",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D2939),
                              ),
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

  void _selectSuggestion(DepartmentModel department) {
    _searchController.removeListener(_onSearchChanged);
    _searchController.text = department.name ?? "";
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchController.addListener(_onSearchChanged);

    setState(() {});

    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
  }

  double get _searchBoxHeight => 42.h;
  double get _searchBoxWidth =>
      MediaQuery.of(context).size.width - 15.w * 2 - 10.w - 150.w;

  // ── CREATE / EDIT ─────────────────────────────────────────────────────────
  void _openDepartmentForm({DepartmentModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? "");

    // ── Location autocomplete plumbing (scoped to this dialog) ────────────
    final locationCtrl = TextEditingController(
      text: existing?.location?.name ?? "",
    );
    String? selectedLocationId = existing?.location?.id;
    final locationFocusNode = FocusNode();
    final LayerLink locationLayerLink = LayerLink();
    OverlayEntry? locationOverlay;
    List<LocationModel> locationSuggestions = [];
    bool autoValidate = false;
    bool isSubmitting = false;

    // Holds the StatefulBuilder's setState so overlay item taps (which live
    // outside the builder's rebuild scope) can still trigger a rebuild.
    StateSetter? dialogSetState;
    final GlobalKey locationFieldKey = GlobalKey();

    double measuredFieldWidth() {
      final box =
          locationFieldKey.currentContext?.findRenderObject() as RenderBox?;
      return box?.size.width ?? (420.w - 40.w);
    }

    void removeLocationOverlay() {
      locationOverlay?.remove();
      locationOverlay = null;
    }

    void showLocationOverlay(BuildContext overlayContext, double fieldWidth) {
      removeLocationOverlay();
      final overlay = Overlay.of(overlayContext);
      locationOverlay = OverlayEntry(
        builder: (context) => Positioned(
          width: fieldWidth,
          child: CompositedTransformFollower(
            link: locationLayerLink,
            showWhenUnlinked: false,
            offset: Offset(0, 46.h),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              child: ConstrainedBox(
                // Caps the dropdown's height — once the suggestion list is
                // taller than this, ListView scrolls internally instead of
                // overflowing or growing the overlay indefinitely.
                constraints: BoxConstraints(maxHeight: 240.h),
                child: locationSuggestions.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        child: Text(
                          "No locations found",
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: locationSuggestions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE4E7EC)),
                        itemBuilder: (context, index) {
                          final s = locationSuggestions[index];
                          return InkWell(
                            onTap: () {
                              locationCtrl.text = s.name;
                              selectedLocationId = s.id;
                              locationCtrl
                                  .selection = TextSelection.fromPosition(
                                TextPosition(offset: locationCtrl.text.length),
                              );
                              removeLocationOverlay();
                              locationFocusNode.unfocus();
                              dialogSetState?.call(() {});
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    size: 14.r,
                                    color: const Color(0xFF4338CA),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1D2939),
                                      ),
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
      overlay.insert(locationOverlay!);
    }

    void updateLocationSuggestions(
      String query,
      BuildContext overlayContext,
      double fieldWidth,
    ) {
      final q = query.trim().toLowerCase();
      locationSuggestions = q.isEmpty
          ? List.from(locationController.locations)
          : locationController.locations
                .where((l) => l.name.toLowerCase().contains(q))
                .toList();

      showLocationOverlay(overlayContext, fieldWidth);
    }

    locationFocusNode.addListener(() {
      if (!locationFocusNode.hasFocus) {
        // Small delay so a tap on a suggestion registers before the
        // overlay is torn down.
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!locationFocusNode.hasFocus) removeLocationOverlay();
        });
      }
    });

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) {
          dialogSetState = ss;

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 24.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
              side: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420.w,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
                child: Form(
                  key: formKey,
                  autovalidateMode: autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Department Details",
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D2939),
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
                      SizedBox(height: 18.h),

                      // Department Name
                      Text(
                        "Department Name",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: nameCtrl,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF344054),
                        ),
                        validator: (v) {
                          final trimmed = v?.trim() ?? "";
                          if (trimmed.isEmpty) {
                            return "Enter department name";
                          }
                          if (trimmed.length < 2) {
                            return "Name must be at least 2 characters";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Department Name",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0xFFB8BEC5),
                          ),
                          errorStyle: TextStyle(fontSize: 10.sp),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 13.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E7EC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E7EC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF4338CA),
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // Location — search box with live autocomplete
                      Text(
                        "Location",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      CompositedTransformTarget(
                        link: locationLayerLink,
                        child: TextFormField(
                          key: locationFieldKey,
                          controller: locationCtrl,
                          focusNode: locationFocusNode,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF344054),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Enter location";
                            }
                            if (selectedLocationId == null) {
                              return "Select a location from the list";
                            }
                            return null;
                          },
                          onChanged: (val) {
                            selectedLocationId = null;
                            ss(() {});
                            updateLocationSuggestions(
                              val,
                              ctx,
                              measuredFieldWidth(),
                            );
                          },
                          onTap: () => updateLocationSuggestions(
                            locationCtrl.text,
                            ctx,
                            measuredFieldWidth(),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Search location",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFFB8BEC5),
                            ),
                            errorStyle: TextStyle(fontSize: 10.sp),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: 14.r,
                              color: const Color(0xFF9AA0AB),
                            ),
                            suffixIcon: locationCtrl.text.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () {
                                      locationCtrl.clear();
                                      selectedLocationId = null;
                                      removeLocationOverlay();
                                      ss(() {});
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
                              horizontal: 12.w,
                              vertical: 13.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFE4E7EC),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFE4E7EC),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF4338CA),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 26.h),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD9DEE5)),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF344054),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    ss(() => autoValidate = true);
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }

                                    removeLocationOverlay();
                                    ss(() => isSubmitting = true);

                                    final bool success;
                                    if (existing == null) {
                                      success = await departmentController
                                          .handleCreateDepartment(
                                            name: nameCtrl.text.trim(),
                                            location: selectedLocationId,
                                          );
                                    } else {
                                      success = await departmentController
                                          .handleUpdateDepartment(
                                            id: existing.id ?? "",
                                            name: nameCtrl.text.trim(),
                                            location: selectedLocationId,
                                          );
                                    }

                                    if (!mounted) return;
                                    ss(() => isSubmitting = false);

                                    if (success) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            departmentController
                                                    .successMessage ??
                                                (existing == null
                                                    ? "Department created successfully!"
                                                    : "Department updated successfully!"),
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

                                      // The create/update response only
                                      // returns the location as a bare ID
                                      // (unpopulated), so the row's location
                                      // name would show blank until the next
                                      // fetch. Refresh now so it reflects the
                                      // fully populated data immediately.
                                      departmentController
                                          .handleGetDepartments();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            departmentController.errorMessage ??
                                                "Something went wrong",
                                            style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF3B82F6),
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
                                    "Confirm",
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
          );
        },
      ),
    ).then((_) {
      // Dialog closed by any path (Cancel, X, Confirm, or barrier tap).
      // Remove the overlay immediately — it's not part of the dialog's
      // widget tree, so it's safe to tear down right away.
      removeLocationOverlay();

      // Delay disposing the FocusNode/controllers: the dialog route's exit
      // transition keeps rebuilding the TextFormField for a few more frames
      // after this Future resolves, and disposing too early causes
      // "A FocusNode was used after being disposed." Waiting past Material's
      // default dialog transition (~150ms) avoids that race.
      Future.delayed(const Duration(milliseconds: 300), () {
        locationFocusNode.dispose();
        locationCtrl.dispose();
        nameCtrl.dispose();
      });
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(DepartmentModel department) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Delete Department",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"${department.name}\"?",
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
      final success = await departmentController.handleDeleteDepartment(
        id: department.id ?? "",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (departmentController.successMessage ?? "Department deleted")
                : (departmentController.errorMessage ??
                      "Failed to delete department"),
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
      drawer: CustomDrawer(activeTile: "Department", onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: departmentController,
        builder: (context, _) {
          final filtered = _filtered;
          final isInitialLoading =
              departmentController.isLoading &&
              departmentController.departments.isEmpty;

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
                        "Department List",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search + Add Department
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
                              hintText: "Search departments",
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
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E7EC),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E7EC),
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
                      SizedBox(width: 10.w),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2FD5C8), Color(0xFFB16CFF)],
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _openDepartmentForm(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
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
                            "Add Department",
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
                  SizedBox(height: 16.h),

                  // List — flat, striped rows on a white card (matches reference)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: isInitialLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filtered.isEmpty
                          ? Center(
                              child: Text(
                                "No departments found",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF9AA0AB),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final department = filtered[index];
                                final isEven = index % 2 == 0;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 6.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isEven
                                        ? const Color(0xFFF5F7FB)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              department.name ?? "",
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1D2939),
                                              ),
                                            ),
                                            if (department.location?.name !=
                                                null) ...[
                                              SizedBox(height: 4.h),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons
                                                        .location_solid,
                                                    size: 11.r,
                                                    color: const Color(
                                                      0xFF9AA0AB,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    department.location?.name ??
                                                        "",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5.sp,
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
                                      ),
                                      GestureDetector(
                                        onTap: () => _openDepartmentForm(
                                          existing: department,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.pencil,
                                          size: 16.r,
                                          color: const Color(0xFF344054),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      GestureDetector(
                                        onTap: () => _confirmDelete(department),
                                        child: Icon(
                                          CupertinoIcons.delete,
                                          size: 16.r,
                                          color: Colors.red,
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
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}
