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

/// Detail view for a single workflow — the parent task instance plus its
/// subtask timeline, from `GET /workflow/:workflowId`. View-only.
class WorkflowDetailScreen extends StatefulWidget {
  const WorkflowDetailScreen({
    super.key,
    required this.taskInstanceId,
    this.title,
  });

  /// `WorkflowModel.instanceId` from the list screen, not that item's own
  /// `_id` — see `WorkflowController.handleGetWorkflowById`.
  final String taskInstanceId;
  final String? title;

  @override
  State<WorkflowDetailScreen> createState() => _WorkflowDetailScreenState();
}

class _WorkflowDetailScreenState extends State<WorkflowDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WorkflowController _workflowController = sl<WorkflowController>();

  static const _primaryColor = Color(0xFF0A0258);
  static const _labelColor = Color(0xFF667085);
  static const _accentColor = Color(0xFF1D2939);
  static const _shadowColor = Color(0x14000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workflowController.handleGetWorkflowById(
        taskInstanceId: widget.taskInstanceId,
      );
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      boxShadow: const [
        BoxShadow(color: _shadowColor, blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    padding: padding ?? EdgeInsets.all(14.w),
    child: child,
  );

  Widget _statusPill(String status) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: _statusColor(status).withOpacity(0.12),
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Text(
      _statusLabel(status),
      style: GoogleFonts.inter(
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w600,
        color: _statusColor(status),
      ),
    ),
  );

  Widget _priorityPill(String priority) {
    if (priority.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _priorityColor(priority).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        priority,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: _priorityColor(priority),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _primaryColor,
      ),
    ),
  );

  Widget _instanceCard(WorkflowDetailInstance instance) {
    final scheduledDate = _formatScheduledDate(instance.scheduledDate);
    final scheduledTime = _formatScheduledTime(instance.scheduledTime);
    final assigneeNames = instance.assignees
        .map((a) => a.fullName)
        .where((n) => n.isNotEmpty)
        .join(', ');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.title.isNotEmpty
                          ? instance.title
                          : 'Untitled',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                      ),
                    ),
                    if (instance.taskCode != null &&
                        instance.taskCode!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        instance.taskCode!,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: _labelColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _statusPill(instance.status),
            ],
          ),
          if ((instance.description ?? '').isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              instance.description!,
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: _accentColor),
            ),
          ],
          if (scheduledDate.isNotEmpty || scheduledTime.isNotEmpty) ...[
            SizedBox(height: 10.h),
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
          if (instance.department.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.layers_outlined, size: 13.r, color: _labelColor),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    instance.department.join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: _labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (assigneeNames.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline, size: 13.r, color: _labelColor),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    assigneeNames,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: _labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (instance.priority.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _priorityPill(instance.priority),
          ],
        ],
      ),
    );
  }

  Widget _timelineItemCard(WorkflowTimelineItem item) {
    final reportingTime = _formatScheduledTime(item.reportingTime);
    final assigneeNames = item.assignees
        .map((a) => a.fullName)
        .where((n) => n.isNotEmpty)
        .join(', ');

    return Container(
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
                  item.title.isNotEmpty ? item.title : 'Untitled subtask',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _statusPill(item.status),
            ],
          ),
          if ((item.description ?? '').isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              item.description!,
              style: GoogleFonts.inter(fontSize: 11.5.sp, color: _labelColor),
            ),
          ],
          if (reportingTime.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 12.r, color: _labelColor),
                SizedBox(width: 4.w),
                Text(
                  reportingTime,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
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
              style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
            ),
          ],
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
        userId: '',
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: '', onTileTap: (value) {}),
      body: ListenableBuilder(
        listenable: _workflowController,
        builder: (context, _) {
          final isLoading =
              _workflowController.isLoading &&
              _workflowController.selectedWorkflow == null;
          final detail = _workflowController.selectedWorkflow;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (detail == null) {
            return Center(
              child: Text(
                _workflowController.errorMessage ?? 'Workflow not found',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF9AA0AB),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(15.w),
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
                        widget.title?.isNotEmpty == true
                            ? widget.title!
                            : 'Workflow Details',
                        overflow: TextOverflow.ellipsis,
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
                _instanceCard(detail.instance),
                SizedBox(height: 20.h),
                _sectionLabel('Timeline'),
                if (detail.timeline.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Center(
                      child: Text(
                        'No subtasks in this workflow yet',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF9AA0AB),
                        ),
                      ),
                    ),
                  )
                else
                  for (final item in detail.timeline) _timelineItemCard(item),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}
