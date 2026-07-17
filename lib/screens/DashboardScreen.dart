import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/dashboard/controllers/dashboard_controller.dart';
import '../core/features/dashboard/data/models/dashboard_task_model.dart';
import '../core/features/organization/controllers/organization_controller.dart';
import '../core/features/subTasks/data/models/sub_task_instance_model.dart'
    show SubTaskTime, LocationRef;
import '../utils/injection_container.dart';
import 'MyTaskDetails.dart';

/// One organization's task list, ready for display — a group of
/// [DashboardTaskModel]s bucketed by `organization.id`, in the order the
/// screen should render them (active organization's group first).
class _OrgGroup {
  final String id;
  final String name;
  final bool isActive;
  final List<DashboardTaskModel> tasks;
  // Set when this organization's own fetch failed — distinct from a
  // genuinely empty (successfully-fetched, zero-task) organization, which
  // has `error == null`.
  final String? error;

  _OrgGroup({
    required this.id,
    required this.name,
    required this.isActive,
    required this.tasks,
    this.error,
  });
}

/// Lists every task the logged-in user can see across every organization
/// they belong to (`GET /tasks/all-tasks`, unfiltered by organization),
/// grouped by organization — the currently active organization's group is
/// always shown first.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.userId});
  final String userId;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardController _dashboardController =
      sl<DashboardController>();
  late final OrganizationController _organizationController =
      sl<OrganizationController>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _primaryColor = Color(0xFF0A0258);
  static const _labelColor = Color(0xFF667085);
  static const _accentColor = Color(0xFF1D2939);

  String? _activeOrganizationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    _activeOrganizationId = await _secureStorage.read(
      key: 'user_active_organization_id',
    );

    // Organizations first — the tasks fetch below needs every org's id,
    // since calling the tasks endpoint with no `organization` filter only
    // ever returns the currently *active* organization's tasks, not every
    // organization the user belongs to.
    await _organizationController.handleGetOrganizations();
    if (!mounted) return;

    final orgIds = _organizationController.organizations
        .map((org) => org.id)
        .where((id) => id.isNotEmpty)
        .toList();
    await _dashboardController.handleGetAllTasksForOrganizations(orgIds);

    if (mounted) setState(() {});
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF0DA99E);
      case 'inprogress':
        return Colors.orange;
      case 'todo':
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'inprogress':
        return 'In Progress';
      case 'todo':
      default:
        return 'Todo';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return const Color(0xFF0DA99E);
    }
  }

  String _formatScheduledTime(SubTaskTime? time) {
    if (time == null || (time.time ?? '').isEmpty) return '';
    return '${time.time}${time.period != null ? ' ${time.period}' : ''}';
  }

  String _formatScheduledDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Every organization the user belongs to gets its own section — even
  /// ones with zero tasks right now, since `GET /tasks/all-tasks` alone
  /// only ever surfaces organizations that already have at least one.
  /// Sorted so the active organization's group always comes first, the
  /// rest alphabetically.
  List<_OrgGroup> _groupedByOrganization(List<DashboardTaskModel> tasks) {
    final tasksByOrgId = <String, List<DashboardTaskModel>>{};
    for (final task in tasks) {
      final id = task.organization?.id ?? '';
      tasksByOrgId.putIfAbsent(id, () => []).add(task);
    }

    final groups = <_OrgGroup>[];
    final seenOrgIds = <String>{};

    final orgErrors = _dashboardController.orgErrors;

    for (final org in _organizationController.organizations) {
      groups.add(
        _OrgGroup(
          id: org.id,
          name: org.name,
          isActive: org.id.isNotEmpty && org.id == _activeOrganizationId,
          tasks: tasksByOrgId[org.id] ?? const [],
          error: orgErrors[org.id],
        ),
      );
      seenOrgIds.add(org.id);
    }

    // An organization referenced by a task but missing from the
    // organizations list (e.g. one the user has since left) still gets a
    // section rather than silently dropping its tasks.
    for (final entry in tasksByOrgId.entries) {
      if (seenOrgIds.contains(entry.key)) continue;
      final LocationRef? org = entry.value.first.organization;
      final name = (org?.name ?? '').isNotEmpty
          ? org!.name!
          : 'Unknown Organization';
      groups.add(
        _OrgGroup(
          id: entry.key,
          name: name,
          isActive: entry.key.isNotEmpty && entry.key == _activeOrganizationId,
          tasks: entry.value,
          error: orgErrors[entry.key],
        ),
      );
    }

    groups.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return groups;
  }

  Future<void> _openTask(DashboardTaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          userId: widget.userId,
          taskId: task.instanceId,
          mainTaskId: task.id,
        ),
      ),
    );
    if (mounted) _load();
  }

  Widget _taskCard(DashboardTaskModel task) {
    final assigneeNames = task.assignees
        .map((a) => a.fullName)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final scheduledDate = _formatScheduledDate(task.scheduledDate);
    final scheduledTime = _formatScheduledTime(task.scheduledTime);

    return InkWell(
      onTap: () => _openTask(task),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title.isNotEmpty ? task.title : 'Untitled',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusColor(task.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _statusLabel(task.status),
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            if (scheduledDate.isNotEmpty || scheduledTime.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13.r, color: _labelColor),
                  SizedBox(width: 4.w),
                  Text(
                    [
                      scheduledDate,
                      scheduledTime,
                    ].where((s) => s.isNotEmpty).join(' • '),
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: _labelColor,
                    ),
                  ),
                ],
              ),
            ],
            if (assigneeNames.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                assigneeNames,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11.5.sp, color: _labelColor),
              ),
            ],
            if (task.priority.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _priorityColor(task.priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  task.priority,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor(task.priority),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orgGroupSection(_OrgGroup group) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, size: 15.r, color: _primaryColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  group.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
              if (group.isActive) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DA99E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0DA99E),
                    ),
                  ),
                ),
              ],
              SizedBox(width: 6.w),
              Text(
                '${group.tasks.length}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (group.error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    'Could not load tasks for this organization',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    onTap: _load,
                    child: Text(
                      'Tap to retry',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (group.tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Center(
                child: Text(
                  'No tasks yet',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF9AA0AB),
                  ),
                ),
              ),
            )
          else
            for (final task in group.tasks) _taskCard(task),
        ],
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
      drawer: CustomDrawer(activeTile: 'Dashboard', onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _dashboardController,
          _organizationController,
        ]),
        builder: (context, _) {
          final tasks = _dashboardController.tasks;
          final organizations = _organizationController.organizations;
          final isInitialLoading =
              (_dashboardController.isLoading ||
                  _organizationController.isLoading) &&
              organizations.isEmpty;
          final groups = _groupedByOrganization(tasks);

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
                    Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: isInitialLoading
                      ? const Center(child: CircularProgressIndicator())
                      : groups.isEmpty
                      ? Center(
                          child: Text(
                            'No organizations found',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF9AA0AB),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              for (final group in groups)
                                _orgGroupSection(group),
                            ],
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
