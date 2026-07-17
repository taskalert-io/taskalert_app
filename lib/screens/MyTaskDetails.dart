// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taskalert_app/core/features/activityLogs/controllers/activity_log_controller.dart';
import 'package:taskalert_app/core/features/employees/controllers/employee_controller.dart';
import 'package:taskalert_app/core/features/employees/data/models/employee_model.dart';
import 'package:taskalert_app/core/features/subTasks/controllers/sub_task_controller.dart';
import 'package:taskalert_app/core/features/subTasks/data/models/sub_task_instance_model.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instance_model.dart';
import 'package:taskalert_app/core/features/tasks/data/models/task_model.dart'
    show AttachmentModel;
import 'package:taskalert_app/screens/panel_right_close_icon.dart';
import 'package:taskalert_app/utils/download_notification_service.dart';
import 'package:taskalert_app/utils/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../components/ToggleSwitch.dart';
import '../components/ZoomableImage.dart';
import 'activity_bottom_sheet.dart';
import 'package:taskalert_app/screens/panel_right_close_icon.dart';
import 'activity_bottom_sheet.dart';
// ═══════════════════════════════════════════════════════════════════════════
// Model — mirrors your API response shape exactly.
// Swap field names here to match your backend without touching UI code.
// ═══════════════════════════════════════════════════════════════════════════

class TaskDetail {
  final String title;
  final String description;
  final String assignTo;
  final String reportingTo;
  final String? assignDate; // "YYYY-MM-DD" or null
  final String? assignTime; // "HH:mm" 24h or null
  final int durationHours;
  final String priority;
  final String status;

  const TaskDetail({
    required this.title,
    required this.description,
    required this.assignTo,
    required this.reportingTo,
    this.assignDate,
    this.assignTime,
    required this.durationHours,
    required this.priority,
    required this.status,
  });

  // ── Deserialize from API JSON ─────────────────────────────────────────────
  factory TaskDetail.fromJson(Map<String, dynamic> json) => TaskDetail(
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    assignTo: json['assign_to'] as String? ?? '',
    reportingTo: json['reporting_to'] as String? ?? '',
    assignDate: json['assign_date'] as String?,
    assignTime: json['assign_time'] as String?,
    durationHours: (json['duration_hours'] as num?)?.toInt() ?? 5,
    priority: json['priority'] as String? ?? 'Low',
    status: json['status'] as String? ?? 'Pending',
  );

  // ── Serialize to API JSON ─────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'assign_to': assignTo,
    'reporting_to': reportingTo,
    'assign_date': assignDate,
    'assign_time': assignTime,
    'duration_hours': durationHours,
    'priority': priority,
    'status': status,
  };

  // ── Immutable copy with overrides ─────────────────────────────────────────
  TaskDetail copyWith({
    String? title,
    String? description,
    String? assignTo,
    String? reportingTo,
    String? assignDate,
    String? assignTime,
    int? durationHours,
    String? priority,
    String? status,
  }) => TaskDetail(
    title: title ?? this.title,
    description: description ?? this.description,
    assignTo: assignTo ?? this.assignTo,
    reportingTo: reportingTo ?? this.reportingTo,
    assignDate: assignDate, // allow clearing with null
    assignTime: assignTime,
    durationHours: durationHours ?? this.durationHours,
    priority: priority ?? this.priority,
    status: status ?? this.status,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════════════════

class TaskDetailScreen extends StatefulWidget {
  final String userId;
  final String? taskId; // pass null for create, an id for edit/view
  final String? mainTaskId; // optional main task ID for context

  const TaskDetailScreen({
    super.key,
    required this.userId,
    required this.mainTaskId,
    this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _primaryColor = Color(0xFF0A0258);
  static const _accentColor = Color(0xFF4A4A4A);
  static const _dividerColor = Color(0xFFE4E7EC);
  static const _textColor = Color(0xFF3F3F3F);
  static const _labelColor = Color(0xFF797979);
  static const _bgColor = Color(0xFFF5F7FB);
  static const _shadowColor = Color(0x14000000);
  static const _greenOn = Color(0xFF1DC230);
  static const _greyOff = Color(0xFF676299);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<bool> get userTaskPermission async {
    String? permission = await secureStorage.read(key: 'user_task_permission');
    return permission == 'true';
  }

  // ── Text controllers & focus nodes for editable fields ───────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  // ── Loading / error state ──────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isReadOnly = false; // New flag to control read-only state
  String? _errorMsg;

  // ── UI-only toggle visibility flags ───────────────────────────────────────
  // These are purely UI — not sent to API.
  bool _showTimePicker = false;

  // ── Toggle enable states (drive API fields) ────────────────────────────────
  bool _assignDateEnabled = false;
  bool _assignTimeEnabled = false;
  bool _selectDurationEnabled = false;
  // Read-only flags for text fields (TextEditingController has no readOnly)
  bool _titleReadOnly = false;
  bool _descReadOnly = false;

  // ── Calendar navigation state ──────────────────────────────────────────────
  int _calendarMonth = DateTime.now().month;
  int _calendarYear = DateTime.now().year;
  int? _selectedDay;

  // ── Time picker state ──────────────────────────────────────────────────────
  bool _isAM = true;
  int _hour = 2;
  int _minute = 0;
  int _durationHours = 5;

  // ── Upload proof state ─────────────────────────────────────────────────────
  // Files the user has confirmed as "proof" attachments for this task.
  final List<PlatformFile> _uploadedProofFiles = [];

  // Id of the currently logged-in user, used to gate the "uploaded proofs"
  // list to only assignees (not just anyone who happens to open the task).
  String? _currentUserId;

  bool get _isAssignedToMe =>
      _currentUserId != null &&
      _currentUserId!.isNotEmpty &&
      _assigneeIds.contains(_currentUserId);

  // The person who created/assigned this task also needs to see the
  // submitted proofs to review them — not just the assignee(s) — otherwise
  // "Assigned by Me" tasks never show the Uploaded Proofs section at all.
  bool get _isCreatedByMe =>
      _currentUserId != null &&
      _currentUserId!.isNotEmpty &&
      taskController.selectedInstance?.createdBy?.id == _currentUserId;

  /// Whether this task type collects proof at all — reused for both the
  /// "Upload Proof" button and the "Uploaded Proofs" list below.
  bool get _proofAllowed =>
      taskController.selectedInstance?.proofSubmission?.proofTypes.isNotEmpty ??
      false;

  // ── Editable fields (all API-mapped) ──────────────────────────────────────
  String _title = 'Retail Market';
  String _description =
      "Lorem Ipsum has been the industry's standard dummy "
      "text ever since the 1500s, when an unknown printer "
      "took a galley of type.";
  String _assignTo = 'Guadalupe Mró';
  List<String> _assigneeIds = []; // Raw IDs — used when saving, not display
  String _reportTo = 'Guadalupe Mró';
  String _priority = 'Low';
  String _status = 'To Do';

  final activityLogs = <ActivityItem>[];

  // ── Static option lists ────────────────────────────────────────────────────
  static const _priorityItems = ['Low', 'Medium', 'High'];
  static const _statusItems = ['To Do', 'In Progress', 'Completed'];

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  // late final TaskInstanceController taskController;
  TaskInstanceController taskController = sl<TaskInstanceController>();
  ActivityLogController activityLogController = sl<ActivityLogController>();
  final EmployeeController employeeController = sl<EmployeeController>();
  final SubTaskController _subTaskController = sl<SubTaskController>();

  // @override
  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: _title);
    _descCtrl = TextEditingController(text: _description);

    // taskController = sl<TaskInstanceController>();

    if (widget.taskId != null) {
      // Show a loader instead of the placeholder/mock field values while
      // the real instance data is being fetched.
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInstance());
    }
  }

  /// Fetches the task instance (+ employee directory) and populates all the
  /// local form fields from it. Used both for the initial load and for
  /// pull-to-refresh.
  Future<void> _loadInstance() async {
    if (widget.taskId == null) return;

    await Future.wait([
      taskController.handleGetInstanceById(instanceId: widget.taskId!),
      employeeController.handleGetEmployees(),
      _subTaskController.handleGetAllSubTaskInstances(
        instanceId: widget.taskId!,
      ),
    ]);
    final currentUserId = await secureStorage.read(key: 'user_id');

    try {
      await activityLogController.handleGetInstanceActivityLogs(
        'fetching logs',
        instanceId: widget.taskId!,
      );
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
    }

    if (mounted) {
      final instance = taskController.selectedInstance;

      final fetchedLogs = activityLogController.logs.map((log) {
        final userName = log.userSnapshot?.name ?? 'Unknown User';
        final action = log.description;
        final entityName = log.entityName;
        return ActivityItem(
          text: '$userName $action'.trim(),
          timeAgo: log.timeLabel,
        );
      }).toList();

      setState(() {
        _currentUserId = currentUserId;
        _title = instance?.title ?? '';
        _description = instance?.description ?? '';

        _titleCtrl.text = _title;
        _descCtrl.text = _description;

        _priority = _titleCase(instance?.priority ?? _priority);
        _status = _statusLabel(instance?.status ?? '');

        _assigneeIds = instance?.assignees ?? [];
        final resolvedNames = _resolvedAssigneeNames;
        _assignTo = resolvedNames.isNotEmpty
            ? resolvedNames.join(', ')
            : 'No assignees';
        _reportTo = (instance?.createdBy?.fullName.isNotEmpty ?? false)
            ? instance!.createdBy!.fullName
            : 'Unknown';

        final scheduledDate = instance?.scheduledDate;
        if (scheduledDate != null) {
          _calendarYear = scheduledDate.year;
          _calendarMonth = scheduledDate.month;
          _selectedDay = scheduledDate.day;
          _assignDateEnabled = true;
        }

        final scheduledTime = instance?.scheduledTime;
        if (scheduledTime != null && scheduledTime.time.isNotEmpty) {
          final parts = scheduledTime.time.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]) ?? _hour;
            _hour = h == 0 ? 12 : h;
            _minute = int.tryParse(parts[1]) ?? _minute;
            _isAM = scheduledTime.period.toUpperCase() != 'PM';
            // Note: the "Schedule Time" toggle itself intentionally stays
            // off by default even when a time already exists — _hour/
            // _minute/_isAM are still populated here so the toggle row's
            // subtitle shows the current value; the picker only opens (and
            // becomes editable) once someone with edit access switches it
            // on themselves.
          }
        }

        // Full edit access only when the current user is the one who
        // created/assigned this task; assignees who merely received it
        // may only update its status (see the unlocked Status card
        // below, which sits outside the AbsorbPointer this flag gates).
        final isCreatedByCurrentUser =
            currentUserId != null &&
            currentUserId.isNotEmpty &&
            instance?.createdBy?.id == currentUserId;
        _isReadOnly = !isCreatedByCurrentUser;

        activityLogs.clear();
        activityLogs.addAll(fetchedLogs);

        _isLoading = false;

        print('Activity logs for instance ${widget.taskId!}:');

        // activityLogController.handleGetInstanceActivityLogs(
        //   'fetching logs',
        //   instanceId: widget.taskId!,
        // );

        // activityLogs.addAll(
        //   activityLogController.logs.map((log) {
        //     final userName = log.userSnapshot?.name ?? 'Unknown User';
        //     final action = log.description;
        //     final entityName = log.entityName;
        //     return ActivityItem(
        //       text: '$userName $action $entityName',
        //       timeAgo: log.timeLabel,
        //     );
        //   }).toList(),
        // );

        print('Activity logs for instance ${activityLogs}:');

        //add some dummy datas in activityLogs list
        // activityLogs.addAll([
        //   const ActivityItem(
        //     text: 'John Doe created the task',
        //     timeAgo: '2 hours ago',
        //   ),
        //   const ActivityItem(
        //     text: 'Jane Smith updated the task status to In Progress',
        //     timeAgo: '1 hour ago',
        //   ),
        //   const ActivityItem(
        //     text: 'John Doe commented on the task',
        //     timeAgo: '30 minutes ago',
        //   ),
        // ]);
      });

      // print('Activity logs for instance ${activityLogs}:');

      //In a varibale fetch and save activity logs for this instance

      // Fetch activity logs for the instance
    }
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Resolves an assignee ID to a display name. Tries the instance's own
  /// populated `assigneeRefs` first (sent straight from the backend, so
  /// it's always in scope regardless of the separately-fetched employee
  /// directory's coverage), then falls back to that employee directory.
  /// Returns null if no name can be found anywhere — callers must never
  /// fall back to showing the raw ID to the user.
  String? _employeeNameById(String id) {
    for (final ref
        in taskController.selectedInstance?.assigneeRefs ?? const []) {
      if (ref.id == id && ref.fullName.isNotEmpty) {
        return ref.fullName;
      }
    }
    for (final employee in employeeController.allEmployees) {
      if (employee.id == id) {
        final name = employee.fullName;
        if (name.isNotEmpty) return name;
      }
    }
    return null;
  }

  /// The resolved, displayable names for the current `_assigneeIds` —
  /// unresolvable ids are dropped rather than ever showing a raw id.
  List<String> get _resolvedAssigneeNames =>
      _assigneeIds.map(_employeeNameById).whereType<String>().toList();

  String _statusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return _titleCase(status);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API methods — replace the body with your real http/dio/graphql calls
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET task detail from API and apply to UI state.
  // Future<void> _fetchTask() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMsg = null;
  //   });
  //   try {
  //     // TODO: replace with real API call
  //     // final response = await yourApiService.get('/tasks/${widget.taskId}');
  //     // _applyModel(TaskDetail.fromJson(response.data));

  //     // ── Simulated API response (remove when wired) ──
  //     await Future.delayed(const Duration(milliseconds: 300));
  //     // ───────────────────────────────────────────────
  //   } catch (e) {
  //     if (mounted) setState(() => _errorMsg = e.toString());
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  // /// PATCH/PUT current state back to API.
  Future<void> _saveTask() async {
    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });
    try {
      final payload = _buildModel().toJson();
      debugPrint('API payload: $payload'); // remove in production

      await Future.delayed(const Duration(milliseconds: 300)); // simulated
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp),
            ),
            backgroundColor: _greenOn,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Model ↔ State converters
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply a [TaskDetail] received from the API into all UI state variables.
  void _applyModel(TaskDetail m) {
    setState(() {
      _title = m.title;
      _description = m.description;
      _titleCtrl.text = m.title;
      _descCtrl.text = m.description;
      _assignTo = m.assignTo;
      _reportTo = m.reportingTo;
      _priority = m.priority;
      _status = m.status;
      _durationHours = m.durationHours;

      // Parse assign_date "YYYY-MM-DD"
      if (m.assignDate != null) {
        final p = m.assignDate!.split('-');
        if (p.length == 3) {
          _calendarYear = int.tryParse(p[0]) ?? _calendarYear;
          _calendarMonth = int.tryParse(p[1]) ?? _calendarMonth;
          _selectedDay = int.tryParse(p[2]);
          _assignDateEnabled = true;
        }
      }

      // Parse assign_time "HH:mm" (24h)
      if (m.assignTime != null) {
        final p = m.assignTime!.split(':');
        if (p.length == 2) {
          final h24 = int.tryParse(p[0]) ?? 0;
          _minute = int.tryParse(p[1]) ?? 0;
          _isAM = h24 < 12;
          _hour = h24 % 12 == 0 ? 12 : h24 % 12;
          _assignTimeEnabled = true;
          _showTimePicker = false;
        }
      }
    });
  }

  /// Collect current UI state into a [TaskDetail] ready to serialize.
  TaskDetail _buildModel() {
    // Convert _hour/_isAM → 24h
    int h24 = _hour % 12;
    if (!_isAM) h24 += 12;
    final startTime = _assignTimeEnabled
        ? '${h24.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}'
        : null;

    // Assign date
    String? assignDate;
    if (_assignDateEnabled && _selectedDay != null) {
      assignDate =
          '$_calendarYear-'
          '${_calendarMonth.toString().padLeft(2, '0')}-'
          '${_selectedDay.toString().padLeft(2, '0')}';
    }

    // Sync from controllers (user may have typed without setState)
    _title = _titleCtrl.text.trim();
    _description = _descCtrl.text.trim();

    return TaskDetail(
      title: _title,
      description: _description,
      assignTo: _assignTo,
      reportingTo: _reportTo,
      assignDate: assignDate,
      assignTime: startTime,
      durationHours: _durationHours,
      priority: _priority,
      status: _status,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Computed display helpers
  // ═══════════════════════════════════════════════════════════════════════════

  String get _formattedTime {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m ${_isAM ? 'AM' : 'PM'}';
  }

  /// The live picker state (`_hour`/`_minute`/`_isAM`), formatted to match
  /// what the server expects for `scheduledTime` — a separate 12-hour
  /// "hh:mm" `time` and "AM"/"PM" `period`. Used on Save instead of the
  /// stale `_scheduledTimeValue`/`_scheduledPeriodValue` (which were only
  /// ever set once, from the server, in `_loadInstance()`, and never
  /// updated when the user actually changes the picker).
  String get _scheduledTimeForSave =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  String get _scheduledPeriodForSave => _isAM ? 'AM' : 'PM';

  /// The live date-picker state (`_calendarYear`/`_calendarMonth`/
  /// `_selectedDay`), formatted "YYYY-MM-DD" for the update-instance
  /// request. The backend validates `scheduledDate` and `scheduledTime`
  /// together — omitting the date while sending a time failed validation.
  String? get _scheduledDateForSave => _selectedDay == null
      ? null
      : '$_calendarYear-'
            '${_calendarMonth.toString().padLeft(2, '0')}-'
            '${_selectedDay.toString().padLeft(2, '0')}';

  String get _endTime {
    int h24 = _hour % 12;
    if (!_isAM) h24 += 12;
    final endH24 = (h24 + _durationHours) % 24;
    final endH12 = endH24 % 12 == 0 ? 12 : endH24 % 12;
    final period = endH24 < 12 ? 'AM' : 'PM';
    return '${endH12.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $period';
  }

  String get _selectedDateLabel {
    if (_selectedDay == null) return 'Today';
    const m = [
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
    return '${m[_calendarMonth - 1]} $_selectedDay, $_calendarYear';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reusable UI components
  // ═══════════════════════════════════════════════════════════════════════════

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

  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: _accentColor,
      ),
    ),
  );

  Widget _divider() => const Divider(height: 1, color: _dividerColor);

  Widget _editIcon() =>
      Icon(Icons.edit_outlined, size: 16.r, color: _textColor);

  // ── Toggle row (Assign Date / Assign Time) ────────────────────────────────
  Widget _toggleRow({
    required String label,
    required String sub,
    required bool value,
    required VoidCallback onTap,
  }) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                sub,
                style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
              ),
            ],
          ),
        ),
        ToggleSwitch(
          value: value,
          activeColor: _greenOn,
          inactiveColor: _greyOff,
          semanticLabel: label,
          onTap: onTap,
        ),
      ],
    ),
  );

  // ── Static (non-editable) info row — e.g. Schedule Date ───────────────────
  Widget _staticInfoRow({required String label, required String value}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
            ),
          ],
        ),
      );

  // ── Dropdown row (Priority / Status / Time Zone) ──────────────────────────
  Widget _dropdownField({
    required String label,
    required String value,
    required Color valueColor,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(CupertinoIcons.chevron_down, size: 12.r, color: valueColor),
        ],
      ),
    ),
  );

  // ── Assign to (multi-select, with chips) ──────────────────────────────────
  Widget _assignToTriggerCol() {
    final selectedNames = _resolvedAssigneeNames;
    return Expanded(
      child: GestureDetector(
        onTap: () => _showAssignToBottomSheet(employeeController.allEmployees),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Assign to',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 15.r,
                  color: const Color(0xFF4A4A4A),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            selectedNames.isEmpty
                ? Text(
                    'No assignees',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _labelColor,
                    ),
                  )
                : Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: selectedNames
                        .map((name) => _assigneeChip(name))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _assigneeChip(String name) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0FF),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: const Color(0xFF4338CA)),
    ),
    child: Text(
      name.split(' ').first,
      style: GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0A0258),
      ),
    ),
  );

  /// Multi-select "Assign To" bottom sheet — lists every employee (not
  /// scoped to a department, unlike the Create*Screen forms) with search,
  /// pre-checks whoever is already assigned, and only commits back to
  /// `_assigneeIds` on "Confirm" (so search/mid-session toggles don't
  /// mutate state until the user is done picking).
  void _showAssignToBottomSheet(List<EmployeeModel> employees) {
    // Some already-assigned employees might not be present in the fetched
    // directory (e.g. a different department scope) — without this, they'd
    // silently vanish from the list even though they're still selected,
    // making the selection look broken. Splice in a placeholder row (using
    // the name from the instance's own populated `assigneeRefs` when
    // available) so they're visible and correctly checked.
    final knownIds = employees.map((e) => e.id).whereType<String>().toSet();
    final missingAssignees = _assigneeIds
        .where((id) => !knownIds.contains(id))
        .map((id) {
          final ref = taskController.selectedInstance?.assigneeRefs
              .where((r) => r.id == id)
              .firstOrNull;
          return EmployeeModel(
            id: id,
            // Never the raw id — if no name is resolvable at all, show a
            // neutral placeholder instead.
            firstName: (ref?.firstName.isNotEmpty ?? false)
                ? ref!.firstName
                : (_employeeNameById(id) ?? 'Unknown employee'),
            lastName: ref?.lastName ?? '',
          );
        });
    final allEmployeesForPicker = [...employees, ...missingAssignees];

    List<String> tempSelected = List.from(_assigneeIds);
    List<EmployeeModel> filtered = List.from(allEmployeesForPicker);
    final searchCtrl = TextEditingController();

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
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 4.h,
                      margin: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9DEE5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign To',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              '${tempSelected.length} selected',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: _labelColor,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(
                            Icons.close,
                            size: 20.r,
                            color: _labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: searchCtrl,
                      style: GoogleFonts.inter(fontSize: 12.sp),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search employees',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFB8BEC5),
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          size: 16.r,
                          color: const Color(0xFF9AA0AB),
                        ),
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
                      ),
                      onChanged: (q) => ss(() {
                        final query = q.trim().toLowerCase();
                        filtered = query.isEmpty
                            ? List.from(allEmployeesForPicker)
                            : allEmployeesForPicker
                                  .where(
                                    (e) =>
                                        e.fullName.toLowerCase().contains(
                                          query,
                                        ) ||
                                        (e.jobRole ?? '')
                                            .toLowerCase()
                                            .contains(query),
                                  )
                                  .toList();
                      }),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 30.h),
                            child: Center(
                              child: Text(
                                'No employees found',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: _labelColor,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFE4E7EC),
                            ),
                            itemBuilder: (context, index) {
                              final employee = filtered[index];
                              final empId = employee.id ?? '';
                              final name = employee.fullName.isEmpty
                                  ? 'No Name'
                                  : employee.fullName;
                              final role = (employee.jobRole?.isEmpty ?? true)
                                  ? 'No Role Assigned'
                                  : employee.jobRole!;
                              final isChecked = tempSelected.contains(empId);
                              return InkWell(
                                onTap: () => ss(() {
                                  if (isChecked) {
                                    tempSelected.remove(empId);
                                  } else {
                                    tempSelected.add(empId);
                                  }
                                }),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18.r,
                                        backgroundColor: isChecked
                                            ? _primaryColor
                                            : const Color(0xFFEFF0FF),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isChecked
                                                ? Colors.white
                                                : const Color(0xFF4338CA),
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
                                              name,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1D2939),
                                              ),
                                            ),
                                            Text(
                                              role,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                color: _labelColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        width: 20.r,
                                        height: 20.r,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? _primaryColor
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            5.r,
                                          ),
                                          border: Border.all(
                                            color: isChecked
                                                ? _primaryColor
                                                : const Color(0xFFD0D5DD),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isChecked
                                            ? Icon(
                                                Icons.check,
                                                size: 14.r,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ss(() => tempSelected.clear()),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              side: const BorderSide(color: Color(0xFFD9DEE5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _assigneeIds = List.from(tempSelected);
                                  final resolvedNames = _resolvedAssigneeNames;
                                  _assignTo = resolvedNames.isNotEmpty
                                      ? resolvedNames.join(', ')
                                      : 'No assignees';
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'Confirm (${tempSelected.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Static col (non-editable) — e.g. Assigned By ──────────────────────────
  Widget _staticCol(String label, String val) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
        ),
      ],
    ),
  );

  // ── Searchable single-select bottom sheet ─────────────────────────────────
  void _showSearchableSheet({
    required String title,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    List<String> filtered = List.from(items);
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
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
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
                SizedBox(height: 12.h),
                TextField(
                  autofocus: true,
                  onChanged: (val) => ss(() {
                    filtered = items
                        .where(
                          (e) => e.toLowerCase().contains(
                            val.toLowerCase().trim(),
                          ),
                        )
                        .toList();
                  }),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF344054),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFB8BEC5),
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      size: 16.r,
                      color: const Color(0xFF4338CA),
                    ),
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
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              'No results found',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF9AA0AB),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE4E7EC),
                          ),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final isSel = item == selected;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8.r),
                              onTap: () {
                                onSelect(item);
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: isSel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSel
                                              ? _primaryColor
                                              : const Color(0xFF344054),
                                        ),
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(
                                        Icons.check,
                                        size: 16.r,
                                        color: _primaryColor,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Upload Proof — options sheet + upload modal
  // ═══════════════════════════════════════════════════════════════════════════

  /// Button placed just above the Save Changes row.
  Widget _buildUploadProofButton() => InkWell(
    onTap: _showUploadProofOptions,
    borderRadius: BorderRadius.circular(8.r),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _primaryColor.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file_outlined, size: 18.r, color: _primaryColor),
          SizedBox(width: 8.w),
          Text(
            _uploadedProofFiles.isEmpty
                ? 'Upload Proof'
                : 'Upload Proof (${_uploadedProofFiles.length})',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Task attachments (original files attached to the task, from the
  // server) — view-only, no upload/delete here. Omitted entirely (not even
  // an empty-state placeholder) when there are none. ──────────────────────

  Widget _buildAttachmentsSection() {
    final attachments =
        taskController.selectedInstance?.attachments ??
        const <AttachmentModel>[];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Attachments'),
        _card(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          child: Column(
            children: [
              for (int i = 0; i < attachments.length; i++) ...[
                if (i != 0) _divider(),
                _attachmentFileRow(attachments[i]),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _attachmentFileRow(AttachmentModel attachment) {
    final ext = attachment.fileType.toLowerCase();
    final isImage = _viewableProofExts.contains(ext);
    final thumbnailUrl = attachment.file?.thumbnailUrl;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: (isImage && thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                ? Image.network(
                    thumbnailUrl,
                    width: 36.w,
                    height: 36.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _proofFileIcon(),
                  )
                : _proofFileIcon(),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              attachment.fileName.isNotEmpty
                  ? attachment.fileName
                  : (ext.isNotEmpty ? 'Attachment (.$ext)' : 'Attachment'),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: _accentColor,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.visibility_outlined,
              size: 18.r,
              color: _primaryColor,
            ),
            onPressed: () => _viewAttachmentFile(attachment),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.download_outlined,
              size: 18.r,
              color: _primaryColor,
            ),
            onPressed: () => _downloadAttachmentFile(attachment),
          ),
        ],
      ),
    );
  }

  /// Downloads the attachment's bytes in-app and writes them to disk — same
  /// mechanism as `_downloadProofFile`, just for the task's own attachments
  /// instead of submitted proofs.
  Future<void> _downloadAttachmentFile(AttachmentModel attachment) async {
    final url = attachment.file?.originalUrl ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This attachment is no longer available to download.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showUploadingProofDialog(message: 'Downloading...');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      Directory? saveDir;
      try {
        saveDir = await getDownloadsDirectory();
      } catch (_) {
        saveDir = null;
      }
      saveDir ??= await getApplicationDocumentsDirectory();

      final ext = attachment.fileType.toLowerCase();
      final baseName = attachment.fileName.isNotEmpty
          ? attachment.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
          : 'attachment_${DateTime.now().millisecondsSinceEpoch}'
                '${ext.isNotEmpty ? '.$ext' : ''}';

      final savedFile = File('${saveDir.path}/$baseName');
      await savedFile.writeAsBytes(response.bodyBytes);

      await DownloadNotificationService.instance.showDownloadComplete(
        fileName: baseName,
        filePath: savedFile.path,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close popup

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded to ${savedFile.path}',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: _greenOn,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close popup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not download this file.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewAttachmentFile(AttachmentModel attachment) {
    final url = attachment.file?.originalUrl ?? '';
    final ext = attachment.fileType.toLowerCase();
    final isImage = _viewableProofExts.contains(ext);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: SingleChildScrollView(
            // A tall/portrait image (or a small screen) can push this past
            // the Dialog's fixed insetPadding height — scroll instead of
            // overflowing.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        attachment.fileName.isNotEmpty
                            ? attachment.fileName
                            : 'Attachment',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Icon(Icons.close, size: 20.r, color: _labelColor),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (isImage && url.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ZoomableImage(
                        networkUrl: url,
                        loaderColor: _primaryColor,
                        errorBuilder: (_) => _previewFallback(),
                      ),
                    ),
                  )
                else
                  _previewFallback(
                    message: url.isEmpty
                        ? 'This file is no longer available.'
                        : 'Preview not available for this file type — tap Open to view it.',
                  ),
                if (!isImage && url.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(url);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: Text(
                        'Open',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Subtasks (listing + create) ───────────────────────────────────────────

  Color _subtaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return _greenOn;
      case 'inprogress':
      case 'in progress':
        return Colors.orange;
      case 'todo':
      default:
        return Colors.red;
    }
  }

  String _subtaskStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'inprogress':
      case 'in progress':
        return 'In Progress';
      case 'todo':
      default:
        return 'Todo';
    }
  }

  // Assigner (the main task's creator) can edit and delete every subtask.
  // A subtask's own assignee(s) can edit it but not delete it. Anyone else
  // (e.g. a main-task assignee not on this particular subtask) gets neither.
  bool _canEditSubtask(SubTaskInstanceModel subtask) =>
      _isCreatedByMe ||
      (_currentUserId != null &&
          _currentUserId!.isNotEmpty &&
          subtask.assignees.any((a) => a.id == _currentUserId));

  bool _canDeleteSubtask(SubTaskInstanceModel subtask) => _isCreatedByMe;

  Widget _buildSubtasksSection() {
    final subtasks = _subTaskController.subTaskInstances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Subtasks'),
            // Only the person who created/assigned this task can break it
            // down into subtasks — not the assignee(s) it was given to.
            if (_isCreatedByMe)
              TextButton.icon(
                onPressed: _showCreateSubtaskSheet,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.add, size: 16.r, color: _primaryColor),
                label: Text(
                  'Create Subtask',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
          ],
        ),
        _card(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          child: subtasks.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Center(
                    child: Text(
                      'No subtasks yet',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _labelColor,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < subtasks.length; i++) ...[
                      if (i != 0) _divider(),
                      _subtaskRow(subtasks[i]),
                    ],
                  ],
                ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _subtaskRow(SubTaskInstanceModel subtask) {
    final canEdit = _canEditSubtask(subtask);
    final canDelete = _canDeleteSubtask(subtask);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title.isNotEmpty
                      ? subtask.title
                      : 'Untitled subtask',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                    color: _accentColor,
                  ),
                ),
                if ((subtask.description ?? '').isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    subtask.description!,
                    overflow: TextOverflow.ellipsis,
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
          GestureDetector(
            onTap: canEdit
                ? () => _showUpdateSubtaskStatusSheet(subtask)
                : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _subtaskStatusColor(subtask.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _subtaskStatusLabel(subtask.status),
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _subtaskStatusColor(subtask.status),
                    ),
                  ),
                  if (canEdit) ...[
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 14.r,
                      color: _subtaskStatusColor(subtask.status),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canEdit)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.edit_outlined,
                size: 17.r,
                color: _primaryColor,
              ),
              onPressed: () => _showEditSubtaskSheet(subtask),
            ),
          if (canDelete)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.delete_outline,
                size: 17.r,
                color: Colors.red,
              ),
              onPressed: () => _confirmDeleteSubtask(subtask),
            ),
        ],
      ),
    );
  }

  // Confirmed real API values.
  static const _subtaskStatusOptions = ['todo', 'inProgress', 'completed'];

  Future<void> _showUpdateSubtaskStatusSheet(
    SubTaskInstanceModel subtask,
  ) async {
    final currentStatus = subtask.status.toLowerCase();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
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
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
                child: Text(
                  'Update Status',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
              for (final option in _subtaskStatusOptions)
                ListTile(
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    if (option.toLowerCase() == currentStatus) return;
                    await _updateSubtaskStatus(subtask, option);
                  },
                  leading: Icon(
                    Icons.circle,
                    size: 12.r,
                    color: _subtaskStatusColor(option),
                  ),
                  title: Text(
                    _subtaskStatusLabel(option),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: _accentColor,
                    ),
                  ),
                  trailing: option.toLowerCase() == currentStatus
                      ? Icon(
                          Icons.check,
                          size: 18.r,
                          color: _primaryColor,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateSubtaskStatus(
    SubTaskInstanceModel subtask,
    String newStatus,
  ) async {
    final success = await _subTaskController
        .handleUpdateSubTaskInstanceStatusAssigneePriority(
          subTaskInstanceId: subtask.id,
          status: newStatus,
        );

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_subTaskController.successMessage ?? 'Status updated')
              : (_subTaskController.errorMessage ?? 'Could not update status'),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: success ? _greenOn : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteSubtask(SubTaskInstanceModel subtask) async {
    String deleteScope = 'single';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          title: Text(
            'Choose Delete Option',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String>(
                value: 'single',
                groupValue: deleteScope,
                onChanged: (v) => ss(() => deleteScope = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeColor: _primaryColor,
                title: Text(
                  'Only this subtask',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: _accentColor,
                  ),
                ),
              ),
              RadioListTile<String>(
                value: 'following',
                groupValue: deleteScope,
                onChanged: (v) => ss(() => deleteScope = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeColor: _primaryColor,
                title: Text(
                  'This and all future subtasks',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
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
      ),
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    final success = await _subTaskController.handleDeleteSubTaskInstance(
      subTaskInstanceId: subtask.id,
      scope: deleteScope,
    );

    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_subTaskController.successMessage ?? 'Subtask deleted')
              : (_subTaskController.errorMessage ?? 'Could not delete subtask'),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: success ? _greenOn : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _subtaskFieldDecoration(String hint) => InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFB8BEC5)),
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

  /// Simple multi-select bottom sheet for the create-subtask form's
  /// assignees — self-contained (unlike `_showAssignToBottomSheet`, which
  /// is tightly coupled to the main task's own `_assigneeIds` state).
  /// Returns the confirmed selection, or null if dismissed without
  /// confirming.
  Future<List<String>?> _pickSubtaskAssignees(
    List<String> currentSelected,
  ) async {
    List<String> tempSelected = List.from(currentSelected);
    List<EmployeeModel> filtered = List.from(employeeController.allEmployees);
    final searchCtrl = TextEditingController();

    return showModalBottomSheet<List<String>>(
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
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 4.h,
                      margin: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9DEE5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Assignees',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(
                            Icons.close,
                            size: 20.r,
                            color: _labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: searchCtrl,
                      style: GoogleFonts.inter(fontSize: 12.sp),
                      decoration: _subtaskFieldDecoration('Search employees')
                          .copyWith(
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: 16.r,
                              color: const Color(0xFF9AA0AB),
                            ),
                          ),
                      onChanged: (q) => ss(() {
                        final query = q.trim().toLowerCase();
                        filtered = query.isEmpty
                            ? List.from(employeeController.allEmployees)
                            : employeeController.allEmployees
                                  .where(
                                    (e) => e.fullName.toLowerCase().contains(
                                      query,
                                    ),
                                  )
                                  .toList();
                      }),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final emp = filtered[i];
                        final id = emp.id ?? '';
                        final isSelected = tempSelected.contains(id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) => ss(() {
                            if (v == true) {
                              tempSelected.add(id);
                            } else {
                              tempSelected.remove(id);
                            }
                          }),
                          title: Text(
                            emp.fullName,
                            style: GoogleFonts.inter(fontSize: 13.sp),
                          ),
                          activeColor: _primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, tempSelected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                        ),
                        child: Text(
                          'Confirm (${tempSelected.length})',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13.sp,
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
      ),
    );
  }

  void _showCreateSubtaskSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<String> selectedAssigneeIds = [];
    TimeOfDay? selectedTime;
    String updateScope = 'single';
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Subtask',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(
                          Icons.close,
                          size: 20.r,
                          color: _labelColor,
                        ),
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
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
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
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    decoration: _subtaskFieldDecoration(
                      'Enter subtask title',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    decoration: _subtaskFieldDecoration(
                      'Enter description (optional)',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Assignees',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () async {
                      final result = await _pickSubtaskAssignees(
                        selectedAssigneeIds,
                      );
                      if (result != null) {
                        ss(() => selectedAssigneeIds = result);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFD9DEE5)),
                      ),
                      child: Text(
                        selectedAssigneeIds.isEmpty
                            ? 'Select assignees (optional)'
                            : selectedAssigneeIds
                                  .map(
                                    (id) =>
                                        _employeeNameById(id) ?? 'Unknown',
                                  )
                                  .join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: selectedAssigneeIds.isEmpty
                              ? const Color(0xFFB8BEC5)
                              : _accentColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Reporting Time',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) ss(() => selectedTime = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFD9DEE5)),
                      ),
                      child: Text(
                        selectedTime == null
                            ? 'Select time (optional)'
                            : selectedTime!.format(ctx),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: selectedTime == null
                              ? const Color(0xFFB8BEC5)
                              : _accentColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Choose Update Option',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'single',
                    groupValue: updateScope,
                    onChanged: (v) => ss(() => updateScope = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    activeColor: _primaryColor,
                    title: Text(
                      'Only this subtask',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'following',
                    groupValue: updateScope,
                    onChanged: (v) => ss(() => updateScope = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    activeColor: _primaryColor,
                    title: Text(
                      'This and all future subtasks',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
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
                                    ss(
                                      () => formError =
                                          'Please enter a title.',
                                    );
                                    return;
                                  }
                                  ss(() {
                                    formError = null;
                                    isSubmitting = true;
                                  });

                                  String? time;
                                  String? period;
                                  if (selectedTime != null) {
                                    final hour12 =
                                        selectedTime!.hourOfPeriod == 0
                                        ? 12
                                        : selectedTime!.hourOfPeriod;
                                    time =
                                        '${hour12.toString().padLeft(2, '0')}:'
                                        '${selectedTime!.minute.toString().padLeft(2, '0')}';
                                    period =
                                        selectedTime!.period == DayPeriod.am
                                        ? 'AM'
                                        : 'PM';
                                  }

                                  final success = await _subTaskController
                                      .handleCreateSubTask(
                                        instanceId: widget.taskId ?? '',
                                        title: title,
                                        description:
                                            descCtrl.text.trim().isEmpty
                                            ? null
                                            : descCtrl.text.trim(),
                                        assigneeIds:
                                            selectedAssigneeIds.isEmpty
                                            ? null
                                            : selectedAssigneeIds,
                                        time: time,
                                        period: period,
                                        scope: updateScope,
                                      );

                                  if (!ctx.mounted) return;

                                  if (success) {
                                    Navigator.pop(ctx);
                                    await _subTaskController
                                        .handleGetAllSubTaskInstances(
                                          instanceId: widget.taskId ?? '',
                                        );
                                    if (!mounted) return;
                                    setState(() {});
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _subTaskController.successMessage ??
                                              'Subtask created successfully',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: _greenOn,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ss(() {
                                      isSubmitting = false;
                                      formError =
                                          _subTaskController.errorMessage ??
                                          'Failed to create subtask.';
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
                                      'Create Subtask',
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
      ),
    );
  }

  /// Same form as `_showCreateSubtaskSheet`, pre-filled from [subtask] and
  /// submitting via the full-update endpoint (#10) instead of create.
  /// Reachable by the subtask's assigner (full edit) or its own
  /// assignee(s) (see `_canEditSubtask`) — delete stays assigner-only.
  void _showEditSubtaskSheet(SubTaskInstanceModel subtask) {
    final titleCtrl = TextEditingController(text: subtask.title);
    final descCtrl = TextEditingController(text: subtask.description ?? '');
    List<String> selectedAssigneeIds = subtask.assignees
        .map((a) => a.id)
        .toList();
    TimeOfDay? selectedTime = _parseSubtaskTime(subtask.reportingTime);
    String updateScope = 'single';
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Subtask',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(
                          Icons.close,
                          size: 20.r,
                          color: _labelColor,
                        ),
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
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
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
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    decoration: _subtaskFieldDecoration(
                      'Enter subtask title',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    decoration: _subtaskFieldDecoration(
                      'Enter description (optional)',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Assignees',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () async {
                      final result = await _pickSubtaskAssignees(
                        selectedAssigneeIds,
                      );
                      if (result != null) {
                        ss(() => selectedAssigneeIds = result);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFD9DEE5)),
                      ),
                      child: Text(
                        selectedAssigneeIds.isEmpty
                            ? 'Select assignees (optional)'
                            : selectedAssigneeIds
                                  .map(
                                    (id) =>
                                        _employeeNameById(id) ?? 'Unknown',
                                  )
                                  .join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: selectedAssigneeIds.isEmpty
                              ? const Color(0xFFB8BEC5)
                              : _accentColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Reporting Time',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) ss(() => selectedTime = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFD9DEE5)),
                      ),
                      child: Text(
                        selectedTime == null
                            ? 'Select time (optional)'
                            : selectedTime!.format(ctx),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: selectedTime == null
                              ? const Color(0xFFB8BEC5)
                              : _accentColor,
                        ),
                      ),
                    ),
                  ),
                  // Only the assigner can retarget an already-generated
                  // occurrence vs. the whole recurring series — an assignee
                  // editing their own subtask always patches just this one.
                  if (_isCreatedByMe) ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Choose Update Option',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                      ),
                    ),
                    RadioListTile<String>(
                      value: 'single',
                      groupValue: updateScope,
                      onChanged: (v) => ss(() => updateScope = v!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      activeColor: _primaryColor,
                      title: Text(
                        'Only this subtask',
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          color: _accentColor,
                        ),
                      ),
                    ),
                    RadioListTile<String>(
                      value: 'following',
                      groupValue: updateScope,
                      onChanged: (v) => ss(() => updateScope = v!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      activeColor: _primaryColor,
                      title: Text(
                        'This and all future subtasks',
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          color: _accentColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ] else
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
                                    ss(
                                      () => formError =
                                          'Please enter a title.',
                                    );
                                    return;
                                  }
                                  ss(() {
                                    formError = null;
                                    isSubmitting = true;
                                  });

                                  String? time;
                                  String? period;
                                  if (selectedTime != null) {
                                    final hour12 =
                                        selectedTime!.hourOfPeriod == 0
                                        ? 12
                                        : selectedTime!.hourOfPeriod;
                                    time =
                                        '${hour12.toString().padLeft(2, '0')}:'
                                        '${selectedTime!.minute.toString().padLeft(2, '0')}';
                                    period =
                                        selectedTime!.period == DayPeriod.am
                                        ? 'AM'
                                        : 'PM';
                                  }

                                  final success = await _subTaskController
                                      .handleUpdateSubTaskInstance(
                                        subTaskInstanceId: subtask.id,
                                        title: title,
                                        description:
                                            descCtrl.text.trim().isEmpty
                                            ? null
                                            : descCtrl.text.trim(),
                                        assigneeIds:
                                            selectedAssigneeIds.isEmpty
                                            ? null
                                            : selectedAssigneeIds,
                                        time: time,
                                        period: period,
                                        scope: updateScope,
                                      );

                                  if (!ctx.mounted) return;

                                  if (success) {
                                    Navigator.pop(ctx);
                                    await _subTaskController
                                        .handleGetAllSubTaskInstances(
                                          instanceId: widget.taskId ?? '',
                                        );
                                    if (!mounted) return;
                                    setState(() {});
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _subTaskController.successMessage ??
                                              'Subtask updated successfully',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: _greenOn,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    ss(() {
                                      isSubmitting = false;
                                      formError =
                                          _subTaskController.errorMessage ??
                                          'Failed to update subtask.';
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
                                      'Save Changes',
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
      ),
    );
  }

  /// Parses a `SubTaskTime {time: "hh:mm", period: "AM"/"PM"}` back into a
  /// `TimeOfDay` for the edit form's initial picker value.
  TimeOfDay? _parseSubtaskTime(SubTaskTime? reportingTime) {
    final time = reportingTime?.time;
    final period = reportingTime?.period;
    if (time == null || time.isEmpty) return null;

    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour12 = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour12 == null || minute == null) return null;

    var hour24 = hour12 % 12;
    if (period?.toUpperCase() == 'PM') hour24 += 12;

    return TimeOfDay(hour: hour24, minute: minute);
  }

  // ── Uploaded proofs list (already-submitted files, from the server) ──────

  static const _viewableProofExts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  String _proofFileExt(ProofFileModel proof) {
    final url = proof.file?.originalUrl ?? '';
    final dot = url.lastIndexOf('.');
    if (dot == -1 || dot == url.length - 1) return '';
    return url.substring(dot + 1).toLowerCase();
  }

  Widget _buildUploadedProofsSection() {
    final files =
        taskController.selectedInstance?.proofSubmission?.files ??
        const <ProofFileModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Uploaded Proofs'),
        _card(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          child: files.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Center(
                    child: Text(
                      'No proof uploaded yet',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _labelColor,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < files.length; i++) ...[
                      if (i != 0) _divider(),
                      _proofFileRow(files[i]),
                    ],
                  ],
                ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _proofFileRow(ProofFileModel proof) {
    final ext = _proofFileExt(proof);
    final isImage = _viewableProofExts.contains(ext);
    final thumbnailUrl = proof.file?.thumbnailUrl;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: (isImage && thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                ? Image.network(
                    thumbnailUrl,
                    width: 36.w,
                    height: 36.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _proofFileIcon(),
                  )
                : _proofFileIcon(),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              proof.fileType.isNotEmpty
                  ? proof.fileType
                  : (ext.isNotEmpty ? 'Proof file (.$ext)' : 'Proof file'),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: _accentColor,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.visibility_outlined,
              size: 18.r,
              color: _primaryColor,
            ),
            onPressed: () => _viewProofFile(proof),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.download_outlined,
              size: 18.r,
              color: _primaryColor,
            ),
            onPressed: () => _downloadProofFile(proof),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, size: 18.r, color: Colors.red),
            onPressed: () => _confirmDeleteProofFile(proof),
          ),
        ],
      ),
    );
  }

  /// Downloads the proof file's bytes in-app and writes them to disk —
  /// doesn't hand off to the browser. Saves to the platform's Downloads
  /// folder where available (Android/desktop); falls back to the app's own
  /// documents folder where it isn't (iOS has no public Downloads dir).
  Future<void> _downloadProofFile(ProofFileModel proof) async {
    final url = proof.file?.originalUrl ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This proof file is no longer available to download.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showUploadingProofDialog(message: 'Downloading...');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      Directory? saveDir;
      try {
        saveDir = await getDownloadsDirectory();
      } catch (_) {
        saveDir = null;
      }
      saveDir ??= await getApplicationDocumentsDirectory();

      final ext = _proofFileExt(proof);
      final baseName = proof.fileType.isNotEmpty
          ? proof.fileType.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
          : 'proof';
      final fileName =
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}'
          '${ext.isNotEmpty ? '.$ext' : ''}';

      final savedFile = File('${saveDir.path}/$fileName');
      await savedFile.writeAsBytes(response.bodyBytes);

      await DownloadNotificationService.instance.showDownloadComplete(
        fileName: fileName,
        filePath: savedFile.path,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close popup

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded to ${savedFile.path}',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: _greenOn,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close popup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not download this file.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _proofFileIcon() => Container(
    width: 36.w,
    height: 36.w,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF6F5FE),
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Icon(
      Icons.insert_drive_file_outlined,
      size: 18.r,
      color: _labelColor,
    ),
  );

  void _viewProofFile(ProofFileModel proof) {
    final url = proof.file?.originalUrl ?? '';
    final ext = _proofFileExt(proof);
    final isImage = _viewableProofExts.contains(ext);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: SingleChildScrollView(
            // A tall/portrait image (or a small screen) can push this past
            // the Dialog's fixed insetPadding height — scroll instead of
            // overflowing.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        proof.fileType.isNotEmpty
                            ? proof.fileType
                            : 'Proof file',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Icon(Icons.close, size: 20.r, color: _labelColor),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (isImage && url.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ZoomableImage(
                        networkUrl: url,
                        loaderColor: _primaryColor,
                        errorBuilder: (_) => _previewFallback(),
                      ),
                    ),
                  )
                else
                  _previewFallback(
                    message: url.isEmpty
                        ? 'This file is no longer available.'
                        : 'Preview not available for this file type — tap Open to view it.',
                  ),
                if (!isImage && url.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(url);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: Text(
                        'Open',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProofFile(ProofFileModel proof) async {
    final publicId = proof.file?.publicId ?? '';
    if (publicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This proof file is missing an id and cannot be deleted.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Delete Proof',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this proof file?',
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

    final success = await taskController.handleDeleteInstanceProofFile(
      taskId: widget.mainTaskId ?? '',
      instanceId: widget.taskId ?? '',
      publicId: publicId,
    );

    if (!mounted) return;
    setState(() {});

    // Once the last proof is gone, do one full reload of the whole details
    // screen (not just the proof list) — same call initState uses — so
    // everything on this screen that could depend on proof state (status,
    // completion eligibility, activity log, etc.) is back in sync with the
    // server, not just trusting the locally-pruned list.
    final remainingFiles =
        taskController.selectedInstance?.proofSubmission?.files ??
        const <ProofFileModel>[];
    if (success && remainingFiles.isEmpty) {
      await _loadInstance();
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (taskController.successMessage ?? 'Proof deleted')
              : (taskController.errorMessage ?? 'Could not delete proof'),
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF0DA99E) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Bottom sheet with the two entry points: Upload File / Use Camera.
  void _showUploadProofOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Let the sheet size itself to its content instead of grabbing the
      // full-screen modal height — that empty full-height area is what was
      // rendering as a solid black block below "Use Camera".
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        // Only pad the bottom (gesture bar / nav buttons) — top: false keeps
        // the sheet hugging its content instead of the whole screen.
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Proof',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              _proofOptionTile(
                icon: Icons.upload_file_outlined,
                label: 'Upload File',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showUploadFileModal();
                },
              ),
              Divider(height: 24.h, color: _dividerColor),
              _proofOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Use Camera',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _captureProofWithCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _proofOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8.r),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: _textColor),
          SizedBox(width: 12.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    ),
  );

  /// Non-dismissible progress popup shown for the duration of an
  /// upload/download request — dismiss it yourself via
  /// `Navigator.of(context, rootNavigator: true).pop()` once the request
  /// settles (success or failure).
  void _showUploadingProofDialog({String message = 'Uploading proof...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 22.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _primaryColor,
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Re-fetches the instance so the "Uploaded Proofs" section (and
  /// everything else on this screen) reflects the server's latest state
  /// right after a successful proof upload.
  Future<void> _reloadInstanceAfterProofUpload() async {
    await taskController.handleGetInstanceById(instanceId: widget.taskId ?? '');
    if (!mounted) return;
    setState(() {});
  }

  /// "Use Camera" flow — captures a single photo and uploads it as proof.
  Future<void> _captureProofWithCamera() async {
    final picker = ImagePicker();
    final XFile? shot = await picker.pickImage(source: ImageSource.camera);
    if (shot == null) return;

    if (!mounted) return;
    _showUploadingProofDialog();

    final success = await taskController.handleUploadInstanceProofFiles(
      taskId: widget.mainTaskId ?? '',
      instanceId: widget.taskId ?? '',
      proofFiles: [File(shot.path)],
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close uploading popup

    if (success) {
      final size = await File(shot.path).length();
      _uploadedProofFiles.add(
        PlatformFile(name: shot.name, size: size, path: shot.path),
      );
      await _reloadInstanceAfterProofUpload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proof uploaded successfully'),
          backgroundColor: _greenOn,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            taskController.errorMessage ?? 'Failed to upload proof',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Dialog matching the "Upload Proof" design — Upload / Webcam tabs,
  /// drop-zone with Browse, file-type hint, gradient Upload button.
  void _showUploadFileModal() {
    String activeTab = 'upload'; // 'upload' | 'webcam'
    List<PlatformFile> pendingFiles = [];
    String? pendingFilesError;
    bool isUploadingProof = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upload Proof',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
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
                SizedBox(height: 12.h),

                // Tabs
                Row(
                  children: [
                    _uploadTab(
                      'Upload',
                      activeTab == 'upload',
                      () => setModalState(() => activeTab = 'upload'),
                    ),
                    SizedBox(width: 24.w),
                    _uploadTab(
                      'Webcam',
                      activeTab == 'webcam',
                      () => setModalState(() => activeTab = 'webcam'),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _divider(),
                SizedBox(height: 16.h),

                if (activeTab == 'upload') ...[
                  Text(
                    'File must be in png, jpg, jpeg, webp, gif, mp4, mov, '
                    'avi or pdf format and upto 5 file(s) at a time.',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _labelColor,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: () async {
                      // TODO: swap for real proof-file types your API accepts
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: [
                          'png',
                          'jpg',
                          'jpeg',
                          'webp',
                          'gif',
                          'mp4',
                          'mov',
                          'avi',
                          'pdf',
                        ],
                      );
                      if (result != null) {
                        setModalState(() {
                          if (result.files.length > 5) {
                            // Reject the whole selection rather than
                            // silently trimming it — the person should
                            // know why files are missing.
                            pendingFilesError =
                                'You can upload a maximum of 5 files at a time. Please select 5 or fewer.';
                          } else {
                            pendingFilesError = null;
                            pendingFiles = result.files;
                          }
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 26.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F5FE),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 26.r,
                            color: _labelColor,
                          ),
                          SizedBox(height: 8.h),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: _labelColor,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Drag & drop your files here, or\n',
                                ),
                                TextSpan(
                                  text: 'Browse',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Max 10MB per file',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: _labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (pendingFilesError != null) ...[
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14.r,
                            color: Colors.red.shade700,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              pendingFilesError!,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (pendingFiles.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    ...pendingFiles.map(
                      (f) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 14.r,
                              color: _textColor,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                f.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: _textColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            GestureDetector(
                              onTap: () => _previewPickedFile(f),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 16.r,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setModalState(() {
                                pendingFiles = List.from(pendingFiles)
                                  ..remove(f);
                                // Clearing a file always makes the current
                                // selection valid again.
                                pendingFilesError = null;
                              }),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(
                                  Icons.close,
                                  size: 16.r,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Webcam tab
                  Container(
                    width: double.infinity,
                    height: 160.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F5FE),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 26.r,
                          color: _labelColor,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Live webcam capture coming soon',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: _labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 18.h),

                // Upload button
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ED9C3), Color(0xFFB13BEC)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap:
                          pendingFiles.isEmpty ||
                              pendingFilesError != null ||
                              isUploadingProof
                          ? null
                          : () async {
                              setModalState(() => isUploadingProof = true);

                              final files = pendingFiles
                                  .where((f) => f.path != null)
                                  .map((f) => File(f.path!))
                                  .toList();

                              final success = await taskController
                                  .handleUploadInstanceProofFiles(
                                    taskId: widget.mainTaskId ?? '',
                                    instanceId: widget.taskId ?? '',
                                    proofFiles: files,
                                  );

                              if (!mounted) return;

                              if (success) {
                                _uploadedProofFiles.addAll(pendingFiles);
                                await _reloadInstanceAfterProofUpload();
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Proof uploaded successfully',
                                    ),
                                    backgroundColor: _greenOn,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                setModalState(() {
                                  isUploadingProof = false;
                                  pendingFilesError =
                                      taskController.errorMessage ??
                                      'Failed to upload proof';
                                });
                              }
                            },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Center(
                          child: isUploadingProof
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Upload',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        (pendingFiles.isEmpty ||
                                            pendingFilesError != null)
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.white,
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

  static const _previewableImageExts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  /// Eye-icon action — shows the picked file full-size if it's an image,
  /// otherwise a simple file-info fallback (video/pdf preview needs a
  /// dedicated player/viewer package, left as a TODO).
  void _previewPickedFile(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final isImage = _previewableImageExts.contains(ext);
    final path = file.path;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: SingleChildScrollView(
            // A tall/portrait image (or a small screen) can push this past
            // the Dialog's fixed insetPadding height — scroll instead of
            // overflowing.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Icon(Icons.close, size: 20.r, color: _labelColor),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (isImage && path != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ZoomableImage(
                        file: File(path),
                        loaderColor: _primaryColor,
                        errorBuilder: (_) => _previewFallback(),
                      ),
                    ),
                  )
                else
                  _previewFallback(
                    // TODO: swap for a real video/PDF viewer package
                    message: ext == 'pdf'
                        ? 'PDF preview not available yet — file is attached.'
                        : ext == 'mp4' || ext == 'mov' || ext == 'avi'
                        ? 'Video preview not available yet — file is attached.'
                        : 'Preview not available for this file type.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewFallback({String message = 'Preview not available.'}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 40.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F5FE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 30.r,
              color: _labelColor,
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
              ),
            ),
          ],
        ),
      );

  Widget _uploadTab(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _primaryColor : _labelColor,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: 46.w,
              height: 2.h,
              color: active ? _primaryColor : Colors.transparent,
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // Task info card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInfoCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Expanded(
              child: Text(
                'Title',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_titleFocus),
              child: _editIcon(),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        TextField(
          controller: _titleCtrl,
          focusNode: _titleFocus,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: _labelColor,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (v) => _title = v,
        ),
        SizedBox(height: 10.h),
        _divider(),
        // Description
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _descCtrl,
                      focusNode: _descFocus,
                      maxLines: null,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: _labelColor,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (v) => _description = v,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => FocusScope.of(context).requestFocus(_descFocus),
                child: _editIcon(),
              ),
            ],
          ),
        ),
        _divider(),
        // Assign to / Reporting to
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              _assignToTriggerCol(),
              _staticCol('Assigned By', _reportTo),
            ],
          ),
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Time picker widget
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimePicker() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Select Duration & Time',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
            ),
            ToggleSwitch(
              value: _selectDurationEnabled,
              semanticLabel: 'Select Duration & Time',
              onTap: () => setState(
                () => _selectDurationEnabled = !_selectDurationEnabled,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Clock + AM/PM + duration row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Analog clock
            GestureDetector(
              onPanUpdate: (d) => _updateHourFromOffset(d.localPosition),
              onTapUp: (d) => _updateHourFromOffset(d.localPosition),
              child: SizedBox(
                width: 130.w,
                height: 130.w,
                child: CustomPaint(
                  painter: _ClockPainter(hour: _hour, minute: _minute),
                ),
              ),
            ),
            SizedBox(width: 16.w),

            // AM/PM radios + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _radioButton('AM', _isAM, () => setState(() => _isAM = true)),
                  SizedBox(height: 8.h),
                  _radioButton(
                    'PM',
                    !_isAM,
                    () => setState(() => _isAM = false),
                  ),
                  SizedBox(height: 10.h),
                  // Minute stepper — the clock face only lets the user pick
                  // an hour by dragging/tapping; there was previously no
                  // way to change the minute at all.
                  Row(
                    children: [
                      Text(
                        'Min',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _minute = (_minute - 1 + 60) % 60),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 18.r,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      SizedBox(
                        width: 22.w,
                        child: Text(
                          _minute.toString().padLeft(2, '0'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _labelColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _minute = (_minute + 1) % 60),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 18.r,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_durationHours',
                          style: GoogleFonts.inter(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: ' hrs',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: _labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Total Duration',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 14.h),
        _divider(),
        SizedBox(height: 12.h),

        // Start / End time
        Row(
          children: [
            _timeBox('Start Time', _formattedTime),
            _timeBox('End Time', _endTime),
          ],
        ),
        SizedBox(height: 14.h),

        // Cancel / Done
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _showTimePicker = false;
                  _assignTimeEnabled = false;
                }),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: _textColor),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFF42C8F5)],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ElevatedButton(
                  onPressed: () => setState(() => _showTimePicker = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _updateHourFromOffset(Offset local) {
    final c = Offset(65.w, 65.w);
    final vec = local - c;
    if (vec.distance < 8) return;
    final angle = math.atan2(vec.dy, vec.dx);
    final raw = ((angle + math.pi / 2) / (2 * math.pi) * 12).floor() % 12;
    setState(() => _hour = raw == 0 ? 12 : raw);
  }

  Widget _radioButton(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? _primaryColor : const Color(0xFFCCCCCC),
                  width: 1.5,
                ),
              ),
              child: active
                  ? Center(
                      child: Container(
                        width: 9.w,
                        height: 9.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: _labelColor,
              ),
            ),
          ],
        ),
      );

  Widget _timeBox(String label, String time) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.access_time, size: 13.r, color: _textColor),
            SizedBox(width: 4.w),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: _labelColor,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: '', onTileTap: (_) {}),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 16.h),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Task Details',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20.r,
                              color: const Color(0xFF1D1B20),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  showActivityBottomSheet(
                                    context,
                                    activities: activityLogs
                                        .map(
                                          (log) => ActivityItem(
                                            text: log.text,
                                            timeAgo: log.timeAgo,
                                          ),
                                        )
                                        .toList(),

                                    // [
                                    //   //Fetch the activity log controller and display the activity log for the task instance
                                    //   // await taskController.fetchActivityLog(widget.taskId ?? ''),
                                    //   const ActivityItem(
                                    //     text:
                                    //         'You created taskinstance "Design"',
                                    //     timeAgo: '2 hours ago',
                                    //   ),
                                    //   const ActivityItem(
                                    //     text: 'Show more',
                                    //     timeAgo: '',
                                    //     isExpandable: true,
                                    //   ),
                                    //   const ActivityItem(
                                    //     text:
                                    //         'Sudipta Sarkar uploaded proof for "Design" (1 file(s))',
                                    //     timeAgo: '1 hour ago',
                                    //   ),
                                    // ],
                                    onDelete: () {
                                      // TODO: delete action
                                    },
                                    onSubmit: () {
                                      // TODO: submit action
                                    },
                                  );
                                },
                                child: PanelRightCloseIcon(
                                  size: 20.r,
                                  color: _textColor,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.close,
                                  size: 20.r,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: Row(
                        //     mainAxisSize: MainAxisSize.min,
                        //     children: [
                        //       InkWell(
                        //         onTap: () {
                        //           showActivityBottomSheet(
                        //             context,
                        //             activities: const [
                        //               ActivityItem(
                        //                 text:
                        //                     'You created taskinstance "Design"',
                        //                 timeAgo: '2 hours ago',
                        //               ),
                        //               ActivityItem(
                        //                 text: 'Show more',
                        //                 timeAgo: '',
                        //                 isExpandable: true,
                        //               ),
                        //               ActivityItem(
                        //                 text:
                        //                     'Sudipta Sarkar uploaded proof for "Design" (1 file(s))',
                        //                 timeAgo: '1 hour ago',
                        //               ),
                        //             ],
                        //             onDelete: () {
                        //               // TODO: delete action
                        //             },
                        //             onSubmit: () {
                        //               // TODO: submit action
                        //             },
                        //           );
                        //         },
                        //         child: PanelRightCloseIcon(
                        //           size: 20.r,
                        //           color: _textColor,
                        //         ),
                        //       ),
                        //       SizedBox(width: 12.w),
                        //       InkWell(
                        //         onTap: () => Navigator.pop(context),
                        //         child: Icon(
                        //           Icons.close,
                        //           size: 20.r,
                        //           color: _textColor,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: Row(
                        //     mainAxisSize: MainAxisSize.min,
                        //     children: [
                        //       InkWell(
                        //         onTap: () {
                        //           showActivityBottomSheet(
                        //             context,
                        //             activities: const [
                        //               ActivityItem(
                        //                 text:
                        //                     'You created taskinstance "Design"',
                        //                 timeAgo: '2 hours ago',
                        //               ),
                        //               ActivityItem(
                        //                 text: 'Show more',
                        //                 timeAgo: '',
                        //                 isExpandable: true,
                        //               ),
                        //               ActivityItem(
                        //                 text:
                        //                     'Sudipta Sarkar uploaded proof for "Design" (1 file(s))',
                        //                 timeAgo: '1 hour ago',
                        //               ),
                        //             ],
                        //             onDelete: () {
                        //               // TODO: delete action
                        //             },
                        //             onSubmit: () {
                        //               // TODO: submit action
                        //             },
                        //           );

                        //         },
                        //         child: PanelRightCloseIcon(
                        //           size: 20.r,
                        //           color: _textColor,
                        //         ),
                        //       ),
                        //       SizedBox(width: 12.w),
                        //       InkWell(
                        //         onTap: () => Navigator.pop(context),
                        //         child: Icon(
                        //           Icons.close,
                        //           size: 20.r,
                        //           color: _textColor,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: InkWell(
                        //     onTap: () => Navigator.pop(context),
                        //     child: Icon(
                        //       Icons.close,
                        //       size: 20.r,
                        //       color: _textColor,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  // Error banner
                  if (_errorMsg != null)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 15.w),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),

                  // Scrollable body
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadInstance,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 15.w,
                          right: 15.w,
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 24.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔒 LOCKED SECTION STARTS HERE
                            AbsorbPointer(
                              absorbing: _isSaving || _isReadOnly,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Task info card
                                  _buildInfoCard(),
                                  SizedBox(height: 16.h),

                                  // Date & Time card
                                  _sectionLabel('Date & Time'),
                                  _card(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 2.h,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Schedule Date — read-only, never editable
                                        _staticInfoRow(
                                          label: 'Schedule Date',
                                          value: _selectedDateLabel,
                                        ),
                                        _divider(),

                                        // Schedule Time toggle
                                        _toggleRow(
                                          label: 'Schedule Time',
                                          sub: _formattedTime,
                                          value: _assignTimeEnabled,
                                          onTap: () => setState(() {
                                            _assignTimeEnabled =
                                                !_assignTimeEnabled;
                                            _showTimePicker =
                                                _assignTimeEnabled;
                                          }),
                                        ),
                                        if (_showTimePicker) ...[
                                          SizedBox(height: 6.h),
                                          _buildTimePicker(),
                                          SizedBox(height: 8.h),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // 🔓 ATTACHMENTS — the task's own attached
                                  // files; the widget itself renders nothing
                                  // when there are none.
                                  _buildAttachmentsSection(),

                                  // Action card (Priority Only)
                                  _sectionLabel('Action'),
                                  _card(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 2.h,
                                    ),
                                    child: Column(
                                      children: [
                                        _dropdownField(
                                          label: 'Priority',
                                          value: _priority,
                                          valueColor: const Color(0xFF4CAF50),
                                          onTap: () => _showSearchableSheet(
                                            title: 'Priority',
                                            items: _priorityItems,
                                            selected: _priority,
                                            onSelect: (v) =>
                                                setState(() => _priority = v),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🔓 LOCKED SECTION ENDS HERE
                            SizedBox(height: 16.h),

                            // 🔓 UNLOCKED ACTION CARD (Status Only)
                            _card(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 2.h,
                              ),
                              child: Column(
                                children: [
                                  _dropdownField(
                                    label: 'Status',
                                    value: _status,
                                    valueColor: const Color(0xFFE57373),
                                    onTap: () => _showSearchableSheet(
                                      title: 'Status',
                                      items: _statusItems,
                                      selected: _status,
                                      onSelect: (v) =>
                                          setState(() => _status = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // 🔓 UNLOCKED UPLOAD PROOF BUTTON — only shown when
                            // the instance actually requires proof types.
                            if (_proofAllowed) ...[
                              _buildUploadProofButton(),
                              SizedBox(height: 16.h),
                            ],

                            // 🔓 UPLOADED PROOFS LIST — only shown for tasks
                            // that collect proof AND (assigned to the
                            // current user OR created/assigned by them) —
                            // not just anyone viewing the task.
                            if (_proofAllowed && (_isAssignedToMe || _isCreatedByMe))
                              _buildUploadedProofsSection(),

                            // 🔓 SUBTASKS — listing + create button.
                            _buildSubtasksSection(),

                            // 🔓 UNLOCKED SAVE BUTTON
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    height: 40.h,
                                    constraints: BoxConstraints(
                                      minWidth: 120.w,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFD96CFF),
                                          Color(0xFF5CE1E6),
                                        ],
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () async {
                                          if (!_isSaving &&
                                              await userTaskPermission) {
                                            String statusAfterUpdate = 'todo';

                                            if (_status == 'To Do') {
                                              statusAfterUpdate = 'todo';
                                            } else if (_status ==
                                                'In Progress') {
                                              statusAfterUpdate = 'inProgress';
                                            } else if (_status == 'Completed') {
                                              statusAfterUpdate = 'completed';
                                            }

                                            setState(() => _isSaving = true);

                                            print(
                                              'Scheduled Date for Save: $_scheduledDateForSave',
                                            );
                                            print(
                                              'Scheduled Time for Save: $_scheduledTimeForSave',
                                            );
                                            print(
                                              'Scheduled Period for Save: $_scheduledPeriodForSave',
                                            );

                                            final success = await taskController
                                                .handleUpdateInstanceConfiguration(
                                                  taskId:
                                                      widget.mainTaskId ?? '',
                                                  instanceId:
                                                      widget.taskId ?? '',
                                                  status: statusAfterUpdate,
                                                  assigneeIds: _assigneeIds,
                                                  priority: _priority
                                                      .toLowerCase(),
                                                  date: _scheduledDateForSave,
                                                  time: _scheduledTimeForSave,
                                                  period:
                                                      _scheduledPeriodForSave,

                                                  scope: 'single',
                                                );

                                            if (!mounted) return;

                                            setState(() => _isSaving = false);

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Task updated successfully'
                                                      : (taskController
                                                                .errorMessage ??
                                                            'Failed to update task'),
                                                ),
                                                backgroundColor: success
                                                    ? _greenOn
                                                    : Colors.redAccent,
                                                duration: const Duration(
                                                  seconds: 3,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'You are not authorized to edit tasks.',
                                                ),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                        splashColor: Colors.white.withOpacity(
                                          0.15,
                                        ),
                                        highlightColor: Colors.transparent,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24.w,
                                          ),
                                          child: Center(
                                            child: _isSaving
                                                ? SizedBox(
                                                    width: 16.w,
                                                    height: 16.h,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Text(
                                                    'Save Changes',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
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

                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Clock painter
// ═══════════════════════════════════════════════════════════════════════════

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  const _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Background
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..color = const Color(0xFFEEEEF8)
        ..style = PaintingStyle.fill,
    );

    // Hour numbers + selected highlight
    const nums = [
      '12',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
    ];
    final selH = hour % 12;
    for (int i = 0; i < 12; i++) {
      final a = (i * 30 - 90) * math.pi / 180;
      final nx = c.dx + (r - 18) * math.cos(a);
      final ny = c.dy + (r - 18) * math.sin(a);
      final isSel = i == selH;
      if (isSel) {
        canvas.drawCircle(
          Offset(nx, ny),
          13,
          Paint()..color = const Color(0xFF0A0258),
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: nums[i],
          style: TextStyle(
            fontSize: 9,
            color: isSel ? Colors.white : const Color(0xFF6C7278),
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(nx - tp.width / 2, ny - tp.height / 2));
    }

    // Hour hand
    final hAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * math.pi / 180;
    canvas.drawLine(
      c,
      Offset(
        c.dx + r * 0.42 * math.cos(hAngle),
        c.dy + r * 0.42 * math.sin(hAngle),
      ),
      Paint()
        ..color = const Color(0xFF0A0258)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final mAngle = (minute * 6 - 90) * math.pi / 180;
    canvas.drawLine(
      c,
      Offset(
        c.dx + r * 0.55 * math.cos(mAngle),
        c.dy + r * 0.55 * math.sin(mAngle),
      ),
      Paint()
        ..color = const Color(0xFF0A0258)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF0A0258));
    canvas.drawCircle(c, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hour != hour || old.minute != minute;
}
