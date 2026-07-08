// ignore_for_file: deprecated_member_use, file_names
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// MODEL
/// Swap this for your real LocationModel (mirrors DepartmentModel pattern)
/// once you wire this screen up to a LocationController / LocationRepository.
/// ─────────────────────────────────────────────────────────────────────────
class LocationModel {
  final String id;
  String name;
  String phone;
  String? street;
  String city;
  String? state;
  String? country;
  String? pincode;

  LocationModel({
    required this.id,
    required this.name,
    required this.phone,
    this.street,
    required this.city,
    this.state,
    this.country,
    this.pincode,
  });
}

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
  // ── Autocomplete plumbing ────────────────────────────────────────────────
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;
  List<LocationModel> _suggestions = [];

  // ── Mock data source — replace with LocationController.locations ────────
  int _nextId = 3;
  List<LocationModel> _locations = [
    LocationModel(
      id: "1",
      name: "Second Office",
      phone: "+91-9876543210",
      city: "Kolkata",
    ),
    LocationModel(
      id: "2",
      name: "Head Office",
      phone: "+91-9876543210",
      city: "Kolkata",
    ),
  ];

  List<LocationModel> _filtered = [];
  final Set<String> _selectedIds = {};
  bool get _allSelected =>
      _filtered.isNotEmpty && _selectedIds.length == _filtered.length;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_locations);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
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
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_locations)
          : _locations
                .where(
                  (l) =>
                      l.name.toLowerCase().contains(q) ||
                      l.city.toLowerCase().contains(q) ||
                      l.phone.toLowerCase().contains(q),
                )
                .toList();
    });
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

    _suggestions = _locations
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q) ||
              l.phone.toLowerCase().contains(q),
        )
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
                                  "${s.city} • ${s.phone}",
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

    setState(() {
      _filtered = [location];
    });

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
    final phoneCtrl = TextEditingController(text: existing?.phone ?? "");
    final streetCtrl = TextEditingController(text: existing?.street ?? "");
    final cityCtrl = TextEditingController(text: existing?.city ?? "");
    final stateCtrl = TextEditingController(text: existing?.state ?? "");
    final countryCtrl = TextEditingController(text: existing?.country ?? "");
    final pincodeCtrl = TextEditingController(text: existing?.pincode ?? "");
    bool autoValidate = false;

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
                              onPressed: () {
                                ss(() => autoValidate = true);
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }

                                setState(() {
                                  if (existing == null) {
                                    // CREATE — id assigned here, flows straight
                                    // into the list + Actions menu below.
                                    _locations.add(
                                      LocationModel(
                                        id: (_nextId++).toString(),
                                        name: nameCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        street: streetCtrl.text.trim(),
                                        city: cityCtrl.text.trim(),
                                        state: stateCtrl.text.trim(),
                                        country: countryCtrl.text.trim(),
                                        pincode: pincodeCtrl.text.trim(),
                                      ),
                                    );
                                  } else {
                                    // EDIT — mutate in place by id, id is never
                                    // regenerated so Actions stay stable.
                                    existing
                                      ..name = nameCtrl.text.trim()
                                      ..phone = phoneCtrl.text.trim()
                                      ..street = streetCtrl.text.trim()
                                      ..city = cityCtrl.text.trim()
                                      ..state = stateCtrl.text.trim()
                                      ..country = countryCtrl.text.trim()
                                      ..pincode = pincodeCtrl.text.trim();
                                  }
                                  _onSearchChanged();
                                });

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing == null
                                          ? "Location created successfully!"
                                          : "Location updated successfully!",
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0DA99E),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                );
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
                              child: Text(
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
      setState(() {
        _locations.removeWhere((l) => l.id == location.id);
        _selectedIds.remove(location.id);
        _onSearchChanged();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Location deleted",
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
      body: GestureDetector(
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
                  SizedBox(width: 8.w,),
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
                      icon: Icon(Icons.add, size: 16.r, color: Colors.white),
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
                        child: _filtered.isEmpty
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
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE4E7EC),
                                ),
                                itemBuilder: (context, index) {
                                  final location = _filtered[index];
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
                                          activeColor: const Color(0xFF0A0258),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (v) => setState(() {
                                            if (v == true) {
                                              _selectedIds.add(location.id);
                                            } else {
                                              _selectedIds.remove(location.id);
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
                                                  fontWeight: FontWeight.w600,
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
                                                    WrapCrossAlignment.center,
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
                                                        location.phone,
                                                        style:
                                                            GoogleFonts.inter(
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
                                                        location.city,
                                                        style:
                                                            GoogleFonts.inter(
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
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
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
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Icon(
                                                CupertinoIcons.chevron_down,
                                                size: 13.r,
                                                color: const Color(0xFF344054),
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
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                    style: GoogleFonts.inter(
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
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}
