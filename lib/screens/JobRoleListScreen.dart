import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/jobRoles/controllers/job_role_controller.dart';
import '../core/features/jobRoles/data/models/job_role_model.dart';
import '../utils/injection_container.dart';

/// Lists job roles (`GET /job-roles`) with client-side search, create
/// (`POST /job-roles`), edit (`PUT /job-roles/:id`), and delete
/// (`DELETE /job-roles/:id`).
class JobRoleListScreen extends StatefulWidget {
  const JobRoleListScreen({super.key, required this.userId});
  final String userId;

  @override
  State<JobRoleListScreen> createState() => _JobRoleListScreenState();
}

class _JobRoleListScreenState extends State<JobRoleListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final JobRoleController _jobRoleController = sl<JobRoleController>();
  final TextEditingController _searchController = TextEditingController();

  static const _primaryColor = Color(0xFF0A0258);
  static const _accentColor = Color(0xFF1D2939);
  static const _labelColor = Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jobRoleController.handleGetJobRoles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JobRoleModel> get _filteredJobRoles {
    final query = _searchController.text.trim().toLowerCase();
    final roles = _jobRoleController.jobRoles;
    if (query.isEmpty) return roles;
    return roles
        .where((role) => role.title.toLowerCase().contains(query))
        .toList();
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 12.sp,
      color: const Color(0xFFB8BEC5),
    ),
    filled: true,
    fillColor: const Color(0xFFF9FAFC),
    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
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
  );

  /// Shared create/edit form — [existing] null means "Create Job Role"
  /// (`POST`), non-null means "Edit Job Role" pre-filled from it (`PUT`).
  void _showJobRoleFormSheet({JobRoleModel? existing}) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    bool isSubmitting = false;
    String? formError;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, ss) => Container(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Job Role' : 'Create Job Role',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 20.r, color: _labelColor),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                if (formError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      formError!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                Text(
                  'Title',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: _fieldDecoration('Enter job role title'),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) {
                                  ss(() => formError = 'Please enter a title.');
                                  return;
                                }
                                ss(() {
                                  formError = null;
                                  isSubmitting = true;
                                });

                                final success = isEdit
                                    ? await _jobRoleController
                                          .handleUpdateJobRole(
                                            id: existing.id,
                                            title: title,
                                          )
                                    : await _jobRoleController
                                          .handleCreateJobRole(title: title);

                                if (!ctx.mounted) return;

                                if (success) {
                                  Navigator.pop(ctx);
                                  if (!mounted) return;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _jobRoleController.successMessage ??
                                            (isEdit
                                                ? 'Job role updated successfully'
                                                : 'Job role created successfully'),
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF1DC230),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ss(() {
                                    isSubmitting = false;
                                    formError =
                                        _jobRoleController.errorMessage ??
                                        (isEdit
                                            ? 'Failed to update job role.'
                                            : 'Failed to create job role.');
                                  });
                                }
                              },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: isSubmitting
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Save Changes' : 'Create',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
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

  Widget _jobRoleRow(JobRoleModel role) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF0FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              CupertinoIcons.person_badge_plus,
              size: 16.r,
              color: _primaryColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              role.title.isNotEmpty ? role.title : 'Untitled',
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 17.r, color: _primaryColor),
            onPressed: () => _showJobRoleFormSheet(existing: role),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, size: 17.r, color: Colors.red),
            onPressed: () => _confirmDeleteJobRole(role),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteJobRole(JobRoleModel role) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Delete Job Role',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${role.title.isNotEmpty ? role.title : 'this job role'}"?',
          style: GoogleFonts.inter(fontSize: 13.sp, color: _accentColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    final success = await _jobRoleController.handleDeleteJobRole(id: role.id);

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_jobRoleController.successMessage ?? 'Job role deleted')
              : (_jobRoleController.errorMessage ??
                    'Could not delete job role'),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF1DC230) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
      drawer: CustomDrawer(activeTile: '', onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: _jobRoleController,
        builder: (context, _) {
          final roles = _filteredJobRoles;
          final isInitialLoading =
              _jobRoleController.isLoading &&
              _jobRoleController.jobRoles.isEmpty;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20.r,
                        color: _primaryColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Job Role Settings',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF344054),
                        ),
                        decoration: _fieldDecoration('Search job roles')
                            .copyWith(
                              prefixIcon: Icon(
                                CupertinoIcons.search,
                                size: 16.r,
                                color: const Color(0xFF9AA0AB),
                              ),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : GestureDetector(
                                      onTap: () => _searchController.clear(),
                                      child: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 16.r,
                                        color: const Color(0xFF9AA0AB),
                                      ),
                                    ),
                            ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: () => _showJobRoleFormSheet(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 13.h,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18.r,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: isInitialLoading
                      ? const Center(child: CircularProgressIndicator())
                      : roles.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No job roles found'
                                : 'No job roles match your search',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF9AA0AB),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _jobRoleController.handleGetJobRoles,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFEAECF0),
                              ),
                            ),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: roles.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE4E7EC),
                              ),
                              itemBuilder: (context, index) =>
                                  _jobRoleRow(roles[index]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}
