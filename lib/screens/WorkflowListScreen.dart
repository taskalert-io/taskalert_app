import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/subTasks/data/models/sub_task_instance_model.dart'
    show SubTaskTime;
import '../core/features/workflow/controllers/workflow_controller.dart';
import '../core/features/workflow/data/models/workflow_model.dart';
import '../utils/injection_container.dart';
import 'WorkflowDetailScreen.dart';

/// Lists every task instance surfaced by `GET /workflow` — tapping one
/// fetches its full workflow detail (instance + subtask timeline) and
/// opens [WorkflowDetailScreen].
class WorkflowListScreen extends StatefulWidget {
  const WorkflowListScreen({super.key, required this.userId});
  final String userId;

  @override
  State<WorkflowListScreen> createState() => _WorkflowListScreenState();
}

class _WorkflowListScreenState extends State<WorkflowListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WorkflowController _workflowController = sl<WorkflowController>();

  static const _primaryColor = Color(0xFF0A0258);
  static const _labelColor = Color(0xFF667085);
  static const _accentColor = Color(0xFF1D2939);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workflowController.handleGetAllWorkflows();
    });
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

  Future<void> _openDetail(WorkflowModel workflow) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkflowDetailScreen(
          taskInstanceId: workflow.instanceId,
          title: workflow.title,
        ),
      ),
    );
    // Covers the detail screen's own mutations (status/edit/delete on the
    // instance or its subtasks) — there's no shared state between the two
    // screens, so a plain refetch on return is the reliable way to pick
    // those up, including a deleted instance disappearing from this list.
    if (mounted) _workflowController.handleGetAllWorkflows();
  }

  Widget _workflowCard(WorkflowModel workflow) {
    final assigneeNames = workflow.assignees
        .map((a) => a.fullName)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final scheduledDate = _formatScheduledDate(workflow.scheduledDate);
    final scheduledTime = _formatScheduledTime(workflow.scheduledTime);

    return InkWell(
      onTap: () => _openDetail(workflow),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
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
                    workflow.title.isNotEmpty ? workflow.title : 'Untitled',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusColor(workflow.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _statusLabel(workflow.status),
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(workflow.status),
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
            SizedBox(height: 8.h),
            Row(
              children: [
                if (workflow.priority.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: _priorityColor(
                        workflow.priority,
                      ).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      workflow.priority,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _priorityColor(workflow.priority),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Icon(Icons.checklist, size: 13.r, color: _labelColor),
                SizedBox(width: 3.w),
                Text(
                  '${workflow.subtaskCount} subtask${workflow.subtaskCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
                ),
              ],
            ),
          ],
        ),
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
      drawer: CustomDrawer(activeTile: 'Work Flow', onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: _workflowController,
        builder: (context, _) {
          final workflows = _workflowController.workflows;
          final isInitialLoading =
              _workflowController.isLoading && workflows.isEmpty;

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
                      'Work Flow',
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
                      : workflows.isEmpty
                      ? Center(
                          child: Text(
                            'No workflows found',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF9AA0AB),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _workflowController.handleGetAllWorkflows,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: workflows.length,
                            itemBuilder: (context, index) =>
                                _workflowCard(workflows[index]),
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
