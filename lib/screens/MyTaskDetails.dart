// ignore_for_file: use_build_context_synchronously
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/utils/injection_container.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

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
  final String timeZone;
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
    required this.timeZone,
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
    timeZone: json['time_zone'] as String? ?? 'Kolkata',
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
    'time_zone': timeZone,
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
    String? timeZone,
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
    timeZone: timeZone ?? this.timeZone,
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

  const TaskDetailScreen({super.key, required this.userId, this.taskId});

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
  String? _errorMsg;

  // ── UI-only toggle visibility flags ───────────────────────────────────────
  // These are purely UI — not sent to API.
  bool _showCalendar = false;
  bool _showTimePicker = false;

  // ── Toggle enable states (drive API fields) ────────────────────────────────
  bool _assignDateEnabled = false;
  bool _assignTimeEnabled = false;
  bool _selectDurationEnabled = false;

  // ── Calendar navigation state ──────────────────────────────────────────────
  int _calendarMonth = DateTime.now().month;
  int _calendarYear = DateTime.now().year;
  int? _selectedDay;

  // ── Time picker state ──────────────────────────────────────────────────────
  bool _isAM = true;
  int _hour = 2;
  int _minute = 0;
  int _durationHours = 5;

  // ── Editable fields (all API-mapped) ──────────────────────────────────────
  String _title = 'Retail Market';
  String _description =
      "Lorem Ipsum has been the industry's standard dummy "
      "text ever since the 1500s, when an unknown printer "
      "took a galley of type.";
  String _assignTo = 'Guadalupe Mró';
  String _reportTo = 'Guadalupe Mró';
  String _priority = 'Low';
  String _status = 'Pending';
  String _timeZone = 'Kolkata';

  // ── Static option lists ────────────────────────────────────────────────────
  static const _assignToItems = [
    'Alice Johnson',
    'Bob Smith',
    'Carol White',
    'David Brown',
    'Eva Martinez',
    'Frank Lee',
    'Grace Kim',
    'Guadalupe Mró',
    'Henry Wilson',
    'Irene Taylor',
  ];
  static const _reportToItems = [
    'Manager',
    'Team Lead',
    'Director',
    'HR',
    'Guadalupe Mró',
    'Alice Johnson',
    'Bob Smith',
  ];
  static const _priorityItems = ['Low', 'Medium', 'High'];
  static const _statusItems = [
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];
  static const _timeZoneItems = [
    'Kolkata',
    'Mumbai',
    'Delhi',
    'Chennai',
    'Bangalore',
    'London',
    'New York',
    'Los Angeles',
    'Dubai',
    'Singapore',
    'Tokyo',
    'Sydney',
    'Paris',
    'Berlin',
    'Toronto',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  late final TaskInstanceController taskController;

  // @override
  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: _title);
    _descCtrl = TextEditingController(text: _description);

    taskController = sl<TaskInstanceController>();

    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await taskController.handleGetInstanceById(instanceId: widget.taskId!);

        if (mounted) {
          setState(() {
            _title = taskController.selectedInstance?.title ?? '';
            _description = taskController.selectedInstance?.description ?? '';

            _titleCtrl.text = _title;
            _descCtrl.text = _description;
            // _assignTo = taskController.selectedInstance?.assigneeName ?? '';
          });
        }
      });
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
      _timeZone = m.timeZone;
      _durationHours = m.durationHours;

      // Parse assign_date "YYYY-MM-DD"
      if (m.assignDate != null) {
        final p = m.assignDate!.split('-');
        if (p.length == 3) {
          _calendarYear = int.tryParse(p[0]) ?? _calendarYear;
          _calendarMonth = int.tryParse(p[1]) ?? _calendarMonth;
          _selectedDay = int.tryParse(p[2]);
          _assignDateEnabled = true;
          _showCalendar = false;
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
      timeZone: _timeZone,
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

  int _daysInMonth(int m, int y) => DateTime(y, m + 1, 0).day;
  int _firstWeekday(int m, int y) => DateTime(y, m, 1).weekday % 7;

  // ═══════════════════════════════════════════════════════════════════════════
  // Reusable UI components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildToggle({required bool value, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30.w,
          height: 15.h,
          padding: EdgeInsets.all(1.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: value ? _greenOn : _greyOff, width: 1.2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14.w,
              height: 14.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? _greenOn : _greyOff,
              ),
            ),
          ),
        ),
      );

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
        _buildToggle(value: value, onTap: onTap),
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

  // ── Assign col (Assign to / Reporting to) ────────────────────────────────
  Widget _assignCol(String label, String val, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
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
          SizedBox(height: 3.h),
          Text(
            val,
            style: GoogleFonts.inter(fontSize: 11.sp, color: _labelColor),
          ),
        ],
      ),
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
              _assignCol(
                'Assign to',
                _assignTo,
                () => _showSearchableSheet(
                  title: 'Assign To',
                  items: _assignToItems,
                  selected: _assignTo,
                  onSelect: (v) => setState(() => _assignTo = v),
                ),
              ),
              _assignCol(
                'Reporting to',
                _reportTo,
                () => _showSearchableSheet(
                  title: 'Reporting To',
                  items: _reportToItems,
                  selected: _reportTo,
                  onSelect: (v) => setState(() => _reportTo = v),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Calendar widget
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCalendar() {
    final days = _daysInMonth(_calendarMonth, _calendarYear);
    final firstDay = _firstWeekday(_calendarMonth, _calendarYear);
    final now = DateTime.now();
    final isNowMonth = _calendarMonth == now.month && _calendarYear == now.year;

    return _card(
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
                icon: Icon(Icons.chevron_left, size: 20.r, color: _accentColor),
                onPressed: () => setState(() {
                  if (_calendarYear > now.year ||
                      (_calendarYear == now.year &&
                          _calendarMonth > now.month)) {
                    if (--_calendarMonth < 1) {
                      _calendarMonth = 12;
                      _calendarYear--;
                    }
                  }
                }),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _calDropdown(
                      _monthNames[_calendarMonth - 1].substring(0, 3),
                      _showMonthPicker,
                    ),
                    SizedBox(width: 6.w),
                    _calDropdown('$_calendarYear', _showYearPicker),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
                icon: Icon(
                  Icons.chevron_right,
                  size: 20.r,
                  color: _accentColor,
                ),
                onPressed: () => setState(() {
                  if (++_calendarMonth > 12) {
                    _calendarMonth = 1;
                    _calendarYear++;
                  }
                }),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Day headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 4.h),
          // Day grid
          ...() {
            final rows = <Widget>[];
            int day = 1;
            final totalRows = ((firstDay + days) / 7).ceil();
            for (int r = 0; r < totalRows; r++) {
              final cells = <Widget>[];
              for (int c = 0; c < 7; c++) {
                final idx = r * 7 + c;
                if (idx < firstDay || day > days) {
                  cells.add(Expanded(child: SizedBox(height: 30.h)));
                } else {
                  final d = day;
                  final isToday = isNowMonth && d == now.day;
                  final isSel = _selectedDay == d;
                  final isPast =
                      _calendarYear < now.year ||
                      (_calendarYear == now.year &&
                          _calendarMonth < now.month) ||
                      (_calendarYear == now.year &&
                          _calendarMonth == now.month &&
                          d < now.day);
                  cells.add(
                    Expanded(
                      child: GestureDetector(
                        onTap: isPast
                            ? null
                            : () => setState(() => _selectedDay = d),
                        child: Container(
                          height: 30.h,
                          margin: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSel
                                ? _primaryColor
                                : isToday
                                ? const Color(0xFFE8E6F5)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '$d',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: isToday || isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isPast
                                    ? const Color(0xFFCCCCCC)
                                    : isSel
                                    ? Colors.white
                                    : isToday
                                    ? _primaryColor
                                    : _labelColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  day++;
                }
              }
              rows.add(Row(children: cells));
              if (r < totalRows - 1) rows.add(SizedBox(height: 2.h));
            }
            return rows;
          }(),
        ],
      ),
    );
  }

  Widget _calDropdown(String text, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border.all(color: _dividerColor),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 14.r, color: _textColor),
        ],
      ),
    ),
  );

  void _showMonthPicker() {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: 12,
        itemBuilder: (_, i) {
          final month = i + 1;
          final isDisabled = _calendarYear == now.year && month < now.month;
          return ListTile(
            enabled: !isDisabled,
            title: Text(
              _monthNames[i],
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: isDisabled ? const Color(0xFFCCCCCC) : _labelColor,
              ),
            ),
            trailing: _calendarMonth == month
                ? Icon(Icons.check, color: _primaryColor, size: 16.r)
                : null,
            onTap: isDisabled
                ? null
                : () {
                    setState(() => _calendarMonth = month);
                    Navigator.pop(context);
                  },
          );
        },
      ),
    );
  }

  void _showYearPicker() {
    final now = DateTime.now();
    final years = List.generate(2100 - now.year + 1, (i) => now.year + i);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: years
            .map(
              (y) => ListTile(
                title: Text(
                  '$y',
                  style: GoogleFonts.inter(fontSize: 13.sp, color: _labelColor),
                ),
                trailing: _calendarYear == y
                    ? Icon(Icons.check, color: _primaryColor, size: 16.r)
                    : null,
                onTap: () {
                  setState(() {
                    _calendarYear = y;
                    if (_calendarYear == now.year &&
                        _calendarMonth < now.month) {
                      _calendarMonth = now.month;
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

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
            _buildToggle(
              value: _selectDurationEnabled,
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
      drawer: CustomDrawer(activeTile: 'Home', onTileTap: (_) {}),
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
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              size: 20.r,
                              color: _textColor,
                            ),
                          ),
                        ),
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
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: 15.w,
                        right: 15.w,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
                      ),
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
                              children: [
                                // Assign Date toggle
                                _toggleRow(
                                  label: 'Assign Date',
                                  sub: _selectedDateLabel,
                                  value: _assignDateEnabled,
                                  onTap: () => setState(() {
                                    _assignDateEnabled = !_assignDateEnabled;
                                    _showCalendar = _assignDateEnabled;
                                    if (_assignDateEnabled) {
                                      _assignTimeEnabled = false;
                                      _showTimePicker = false;
                                    }
                                  }),
                                ),
                                if (_showCalendar) ...[
                                  SizedBox(height: 6.h),
                                  _buildCalendar(),
                                  SizedBox(height: 8.h),
                                ],
                                _divider(),

                                // Assign Time toggle
                                _toggleRow(
                                  label: 'Assign Time',
                                  sub: _formattedTime,
                                  value: _assignTimeEnabled,
                                  onTap: () => setState(() {
                                    _assignTimeEnabled = !_assignTimeEnabled;
                                    _showTimePicker = _assignTimeEnabled;
                                    if (_assignTimeEnabled) {
                                      _assignDateEnabled = false;
                                      _showCalendar = false;
                                    }
                                  }),
                                ),
                                if (_showTimePicker) ...[
                                  SizedBox(height: 6.h),
                                  _buildTimePicker(),
                                  SizedBox(height: 8.h),
                                ],
                                _divider(),

                                // Time Zone
                                _dropdownField(
                                  label: 'Time Zone',
                                  value: _timeZone,
                                  valueColor: _labelColor,
                                  onTap: () => _showSearchableSheet(
                                    title: 'Time Zone',
                                    items: _timeZoneItems,
                                    selected: _timeZone,
                                    onSelect: (v) =>
                                        setState(() => _timeZone = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Action card
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
                                _divider(),
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

                          // Save button — Ink wraps the gradient so the button never
                          // changes size or color on tap; only the ripple is visible.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  height: 40.h,
                                  constraints: BoxConstraints(minWidth: 120.w),
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
                                          _saveTask();
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
                                            // SnackBar(
                                            //   content: Text(
                                            //     'You are not authorized to update this task',
                                            //     style: GoogleFonts.inter(
                                            //       color: Colors.white,
                                            //       fontSize: 13.sp,
                                            //     ),
                                            //   ),
                                            //   backgroundColor: _greyOff,
                                            //   behavior:
                                            //       SnackBarBehavior.floating,
                                            //   shape: RoundedRectangleBorder(
                                            //     borderRadius:
                                            //         BorderRadius.circular(8.r),
                                            //   ),
                                            // ),
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
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
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
