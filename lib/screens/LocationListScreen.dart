// ignore_for_file: deprecated_member_use, file_names
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key, required this.userId});
  final String userId;

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);

  late final LocationController locationController;

  // ── Autocomplete plumbing ────────────────────────────────────────────────
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;
  List<LocationModel> _suggestions = [];

  final Set<String> _selectedIds = {};

  bool _matchesQuery(LocationModel l, String q) =>
      l.name.toLowerCase().contains(q) ||
      l.phoneNumber.toLowerCase().contains(q) ||
      (l.address?.city.toLowerCase().contains(q) ?? false);

  List<LocationModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final locations = locationController.locations;
    if (q.isEmpty) return locations;
    return locations.where((l) => _matchesQuery(l, q)).toList();
  }

  bool get _allSelected =>
      _filtered.isNotEmpty && _selectedIds.length == _filtered.length;

  @override
  void initState() {
    super.initState();
    locationController = sl<LocationController>();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    _suggestions = locationController.locations
        .where((l) => _matchesQuery(l, q))
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
                            CupertinoIcons.location_solid,
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
                                  "${s.address?.city ?? '-'} • ${s.phoneNumber}",
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

  void _selectSuggestion(LocationModel location) {
    _searchController.removeListener(_onSearchChanged);
    _searchController.text = location.name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchController.addListener(_onSearchChanged);

    setState(() {});

    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
  }

  // Search box measurements used to size/position the overlay. Kept as
  // simple constants derived from the field's own padding/text style so the
  // overlay lines up under the field without needing a GlobalKey lookup.
  double get _searchBoxHeight => 40.h;
  double get _searchBoxWidth =>
      MediaQuery.of(context).size.width - 15.w * 2 - 5.w - 96.w;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds
          ..clear()
          ..addAll(_filtered.map((l) => l.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  // ── CREATE / EDIT ─────────────────────────────────────────────────────────
  void _openLocationForm({LocationModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? "");
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? "");
    final streetCtrl = TextEditingController(
      text: existing?.address?.street ?? "",
    );
    final cityCtrl = TextEditingController(text: existing?.address?.city ?? "");
    final stateCtrl = TextEditingController(
      text: existing?.address?.state ?? "",
    );
    final countryCtrl = TextEditingController(
      text: existing?.address?.country ?? "",
    );
    final pincodeCtrl = TextEditingController(
      text: existing?.address?.pinCode ?? "",
    );
    List<DepartmentModel> selectedDepartments = (existing?.department ?? [])
        .where((d) => d.id != null)
        .map((d) => DepartmentModel(id: d.id, name: d.name))
        .toList();
    bool autoValidate = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          // Tapping anywhere inside the popup (outside whichever field is
          // currently focused) should close the Departments dropdown.
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Padding(
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
                                ? "Add New Location"
                                : "Edit Location",
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

                      // Location Name + Phone
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              label: "Location Name",
                              required: true,
                              controller: nameCtrl,
                              hint: "Location Name",
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? "Enter location name"
                                  : null,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _formField(
                              label: "Phone",
                              required: true,
                              controller: phoneCtrl,
                              hint: "10-digit phone number",
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (v) {
                                final digits = (v ?? "").trim();
                                if (digits.isEmpty) {
                                  return "Enter phone number";
                                }
                                if (digits.length != 10) {
                                  return "Enter a valid 10-digit number";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Departments — multi-select, with an inline
                      // "+ Add Department" option pinned above the list.
                      _DepartmentMultiSelectField(
                        initialSelected: existing?.department ?? const [],
                        onChanged: (v) => selectedDepartments = v,
                      ),
                      SizedBox(height: 12.h),

                      // Street
                      _formField(
                        label: "Street",
                        controller: streetCtrl,
                        hint: "Street Address",
                        maxLines: 3,
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
                                      ss(() => autoValidate = true);
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }

                                      ss(() => isSubmitting = true);

                                      final departmentIds = selectedDepartments
                                          .map((d) => d.id)
                                          .whereType<String>()
                                          .toList();

                                      final bool success;
                                      if (existing == null) {
                                        success = await locationController
                                            .handleCreateLocation(
                                              name: nameCtrl.text.trim(),
                                              phoneNumber: phoneCtrl.text
                                                  .trim(),
                                              street: streetCtrl.text.trim(),
                                              city: cityCtrl.text.trim(),
                                              state: stateCtrl.text.trim(),
                                              pinCode: pincodeCtrl.text.trim(),
                                              country: countryCtrl.text.trim(),
                                              departmentIds: departmentIds,
                                            );
                                      } else {
                                        success = await locationController
                                            .handleUpdateLocation(
                                              locationId: existing.id,
                                              name: nameCtrl.text.trim(),
                                              phoneNumber: phoneCtrl.text
                                                  .trim(),
                                              street: streetCtrl.text.trim(),
                                              city: cityCtrl.text.trim(),
                                              state: stateCtrl.text.trim(),
                                              pinCode: pincodeCtrl.text.trim(),
                                              country: countryCtrl.text.trim(),
                                              departmentIds: departmentIds,
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
                                              locationController
                                                      .successMessage ??
                                                  (existing == null
                                                      ? "Location created successfully!"
                                                      : "Location updated successfully!"),
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              locationController.errorMessage ??
                                                  "Something went wrong",
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                          ),
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
                                          ? "Create Location"
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
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    int maxLines = 1,
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
          maxLines: maxLines,
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

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(LocationModel location) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          "Delete Location",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A0258),
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"${location.name}\"?",
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
      final success = await locationController.handleDeleteLocation(
        locationId: location.id,
      );

      if (!mounted) return;

      setState(() {
        _selectedIds.remove(location.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (locationController.successMessage ?? "Location deleted")
                : (locationController.errorMessage ??
                      "Failed to delete location"),
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
      drawer: CustomDrawer(activeTile: "Location", onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: locationController,
        builder: (context, _) {
          final filtered = _filtered;
          final isInitialLoading =
              locationController.isLoading &&
              locationController.locations.isEmpty;

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
                        "Location List",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A0258),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Search + Add Location
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
                              hintText: "Search Location",
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
                          onPressed: () => _openLocationForm(),
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
                            "Add Location",
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
                                  value: _allSelected,
                                  activeColor: const Color(0xFF0A0258),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: _toggleSelectAll,
                                ),
                                Expanded(
                                  child: Text(
                                    "Locations",
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
                                      "No locations found",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF9AA0AB),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE4E7EC),
                                    ),
                                    itemBuilder: (context, index) {
                                      final location = filtered[index];
                                      final isChecked = _selectedIds.contains(
                                        location.id,
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
                                                  _selectedIds.add(location.id);
                                                } else {
                                                  _selectedIds.remove(
                                                    location.id,
                                                  );
                                                }
                                              }),
                                            ),

                                            SizedBox(width: 12.w),
                                            // Name + phone + city, stacked
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    location.name,
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
                                                            color: const Color(
                                                              0xFF4338CA,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            location
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
                                                                .location_solid,
                                                            size: 11.r,
                                                            color: const Color(
                                                              0xFF9AA0AB,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            location
                                                                    .address
                                                                    ?.city ??
                                                                "-",
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  const Color(
                                                                    0xFF667085,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
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
                                                    BorderRadius.circular(8.r),
                                              ),
                                              // Using `child` (not `icon`) keeps
                                              // the tap target simple and avoids
                                              // IconButton's extra padding.
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.h,
                                                  right: 8.w,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.all(6.r),
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
                                                    CupertinoIcons.chevron_down,
                                                    size: 13.r,
                                                    color: const Color(
                                                      0xFF344054,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _openLocationForm(
                                                    existing: location,
                                                  );
                                                } else if (value == 'delete') {
                                                  _confirmDelete(location);
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
                                                              color: Colors.red,
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

// ── Department multi-select field (live data + inline "Add Department") ──
//
// Used in the Location create/edit form. Backed by real `DepartmentController`
// data (unscoped — unlike the Employee form's department field, a Location
// being created doesn't have an id yet, so there's no location to filter
// by), with a pinned "+ Add Department" row at the top of its dropdown.
class _DepartmentMultiSelectField extends StatefulWidget {
  const _DepartmentMultiSelectField({
    required this.initialSelected,
    required this.onChanged,
  });

  final List<LocationDepartmentModel> initialSelected;
  final ValueChanged<List<DepartmentModel>> onChanged;

  @override
  State<_DepartmentMultiSelectField> createState() =>
      _DepartmentMultiSelectFieldState();
}

class _DepartmentMultiSelectFieldState
    extends State<_DepartmentMultiSelectField> {
  late final DepartmentController _departmentController =
      sl<DepartmentController>();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  // id -> model, so both pre-selected refs (id + name only, from an
  // existing location's `department` list) and freshly-picked full
  // DepartmentModel entries live in the same map.
  final Map<String, DepartmentModel> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final d in widget.initialSelected) {
      if (d.id != null) {
        _selected[d.id!] = DepartmentModel(id: d.id, name: d.name);
      }
    }
    _departmentController.handleGetDepartments(search: '');
    _focusNode.addListener(_onFocusChanged);
    _departmentController.addListener(_onDepartmentsChanged);
  }

  @override
  void dispose() {
    _departmentController.removeListener(_onDepartmentsChanged);
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onDepartmentsChanged() {
    _resolveSelectedNames();
    if (_focusNode.hasFocus) _showOverlay();
  }

  // A location's own `department` refs sometimes come back as plain id
  // strings rather than populated `{_id, name}` objects, which leaves the
  // pre-selected entries seeded in `initState` with a null `name` — the
  // dropdown's checkmarks still work fine (id-only match), but the field's
  // chips would render blank. Once the real department list loads, patch
  // in the missing names by matching on id.
  void _resolveSelectedNames() {
    if (_departmentController.departments.isEmpty) return;
    var changed = false;
    for (final id in _selected.keys.toList()) {
      if ((_selected[id]?.name ?? '').isNotEmpty) continue;
      final matches = _departmentController.departments.where(
        (d) => d.id == id,
      );
      if (matches.isNotEmpty) {
        _selected[id] = matches.first;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
      widget.onChanged(_selected.values.toList());
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Small delay so a tap on a checkbox/"Add Department" registers
      // before the overlay is torn down.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _toggle(DepartmentModel dept) {
    if (dept.id == null) return;
    setState(() {
      if (_selected.containsKey(dept.id)) {
        _selected.remove(dept.id);
      } else {
        _selected[dept.id!] = dept;
      }
    });
    widget.onChanged(_selected.values.toList());
    _showOverlay();
  }

  // Removing directly from the field's chip (the "x") — distinct from
  // `_toggle` in that it doesn't need to open/refresh the dropdown; it
  // only does so if the dropdown already happens to be open, so its
  // checkboxes stay in sync.
  void _remove(DepartmentModel dept) {
    if (dept.id == null) return;
    setState(() => _selected.remove(dept.id));
    widget.onChanged(_selected.values.toList());
    if (_focusNode.hasFocus) _showOverlay();
  }

  void _openAddDepartmentDialog() {
    _removeOverlay();
    _focusNode.unfocus();

    final nameCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, dss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            "Add Department",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              color: const Color(0xFF0A0258),
            ),
          ),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Department name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Enter a department name"
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text("Cancel", style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(dialogFormKey.currentState?.validate() ??
                          false)) {
                        return;
                      }
                      dss(() => submitting = true);

                      final name = nameCtrl.text.trim();
                      final success = await _departmentController
                          .handleCreateDepartment(name: name);

                      dss(() => submitting = false);

                      if (success) {
                        final created = _departmentController.departments
                            .where((d) => d.name == name)
                            .firstOrNull;
                        if (mounted && created?.id != null) {
                          setState(() => _selected[created!.id!] = created);
                          widget.onChanged(_selected.values.toList());
                        }
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      }
                    },
              child: submitting
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("Add", style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 260.w;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (box?.size.height ?? 44.h) + 6.h),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 280.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _openAddDepartmentDialog,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.add_circled_solid,
                              size: 14.r,
                              color: const Color(0xFF0A0258),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "Add Department",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A0258),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E7EC)),
                    if (_departmentController.isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Center(
                          child: SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    else if (_departmentController.departments.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        child: Text(
                          "No departments found",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          shrinkWrap: true,
                          itemCount: _departmentController.departments.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (context, index) {
                            final dept =
                                _departmentController.departments[index];
                            final isChecked =
                                dept.id != null &&
                                _selected.containsKey(dept.id);
                            return InkWell(
                              onTap: () => _toggle(dept),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked
                                          ? CupertinoIcons
                                                .checkmark_square_fill
                                          : CupertinoIcons.square,
                                      size: 16.r,
                                      color: isChecked
                                          ? const Color(0xFF0A0258)
                                          : const Color(0xFF9AA0AB),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        dept.name ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1D2939),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _chip(DepartmentModel dept) {
    return Container(
      padding: EdgeInsets.only(left: 9.w, right: 4.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FF),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 140.w),
            child: Text(
              dept.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A0258),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          // Its own tap target — removing a chip must not also toggle the
          // dropdown open/closed the way tapping the rest of the field does.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _remove(dept),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 14.r,
              color: const Color(0xFF8B8FA8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selected.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Departments",
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F3F3F),
          ),
        ),
        SizedBox(height: 4.h),
        CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
            focusNode: _focusNode,
            child: GestureDetector(
              key: _fieldKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => _focusNode.hasFocus
                  ? _focusNode.unfocus()
                  : _focusNode.requestFocus(),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 40.h),
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: hasSelection ? 8.h : 10.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFD9DEE5)),
                ),
                child: !hasSelection
                    ? Row(
                        children: [
                          Icon(
                            CupertinoIcons.square_grid_2x2,
                            size: 14.r,
                            color: const Color(0xFF9AA0AB),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              "Select departments",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFB8BEC5),
                              ),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 12.r,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final dept in _selected.values) _chip(dept),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 12.r,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
