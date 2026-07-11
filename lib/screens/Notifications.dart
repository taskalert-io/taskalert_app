import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Severity system ────────────────────────────────────────────────────
//
// Mirrors the web SEVERITY_CONFIG 1:1 (danger / warning / info), so the
// backend can send a plain `"severity": "danger"` string and every color
// in this screen follows automatically — no per-screen color branching.
// `NotifFilter` (below) stays a separate concept: it's the *category*
// tab the user filters by (All / Overdue / Due now / Assigned), while
// `NotifSeverity` is what actually drives color. A card's filter category
// and its severity are independent — e.g. two different "Overdue" cards
// could in theory carry different severities if the API ever needs that.

enum NotifSeverity { success, danger, warning, info }

class SeverityStyle {
  final Color dot; // barColor
  final Color iconWrapBg;
  final Color iconWrapFg;
  final Color pillBg; // badge
  final Color pillFg;
  final Color cardBorder;
  final IconData icon;

  const SeverityStyle({
    required this.dot,
    required this.iconWrapBg,
    required this.iconWrapFg,
    required this.pillBg,
    required this.pillFg,
    required this.cardBorder,
    required this.icon,
  });
}

/// Single source of truth for severity → color/icon, mirrored 1:1 from the
/// web SEVERITY_STYLE map:
///   success: bg-success / bg-green-100 text-success  / border-green-200
///   danger:  bg-error   / bg-red-100 text-error       / border-red-200
///   warning: bg-warning / bg-amber-100 text-warning   / border-amber-200
///   info:    bg-info    / bg-tertiary-200 text-tertiary-700 / border-tertiary-200
/// Swap these Color values to match your exact design tokens if the hexes
/// differ from what's below — this map is the only place that needs to
/// change.
const Map<NotifSeverity, SeverityStyle> kSeverityConfig = {
  NotifSeverity.success: SeverityStyle(
    dot: Color(0xFF22C55E), // bg-success
    iconWrapBg: Color(0xFFDCFCE7), // bg-green-100
    iconWrapFg: Color(0xFF22C55E), // text-success
    pillBg: Color(0xFFDCFCE7),
    pillFg: Color(0xFF22C55E),
    cardBorder: Color(0xFFBBF7D0), // border-green-200
    icon: Icons.check_circle_rounded,
  ),
  NotifSeverity.danger: SeverityStyle(
    dot: Color(0xFFEF4444), // bg-error
    iconWrapBg: Color(0xFFFEE2E2), // bg-red-100
    iconWrapFg: Color(0xFFEF4444), // text-error
    pillBg: Color(0xFFFEE2E2),
    pillFg: Color(0xFFEF4444),
    cardBorder: Color(0xFFFECACA), // border-red-200
    icon: Icons.warning_rounded, // AlertTriangle
  ),
  NotifSeverity.warning: SeverityStyle(
    dot: Color(0xFFF59E0B), // bg-warning
    iconWrapBg: Color(0xFFFEF3C7), // bg-amber-100
    iconWrapFg: Color(0xFFF59E0B), // text-warning
    pillBg: Color(0xFFFEF3C7),
    pillFg: Color(0xFFF59E0B),
    cardBorder: Color(0xFFFDE68A), // border-amber-200
    icon: Icons.warning_rounded, // AlertTriangle
  ),
  NotifSeverity.info: SeverityStyle(
    dot: Color(0xFF3B82F6), // bg-info
    iconWrapBg: Color(0xFFBFDBFE), // bg-tertiary-200
    iconWrapFg: Color(0xFF1D4ED8), // text-tertiary-700
    pillBg: Color(0xFFBFDBFE),
    pillFg: Color(0xFF1D4ED8),
    cardBorder: Color(0xFFBFDBFE), // border-tertiary-200
    icon: Icons.info_outline, // Info
  ),
};

NotifSeverity severityFromApi(String? raw) {
  switch (raw) {
    case 'success':
      return NotifSeverity.success;
    case 'danger':
      return NotifSeverity.danger;
    case 'warning':
      return NotifSeverity.warning;
    case 'info':
      return NotifSeverity.info;
    default:
      return NotifSeverity.info;
  }
}

// ── Filter categories (tabs) ───────────────────────────────────────────

enum NotifFilter { all, overdue, dueNow, assigned }

NotifFilter filterFromApi(String? raw) {
  switch (raw) {
    case 'overdue':
      return NotifFilter.overdue;
    case 'due_now':
    case 'dueNow':
      return NotifFilter.dueNow;
    case 'assigned':
      return NotifFilter.assigned;
    default:
      return NotifFilter.all;
  }
}

/// Display label for a filter's own status pill (e.g. "Overdue", "Due now").
/// Separate from severity color — this is just the pill *text*.
String filterLabel(NotifFilter f) {
  switch (f) {
    case NotifFilter.overdue:
      return 'Overdue';
    case NotifFilter.dueNow:
      return 'Due now';
    case NotifFilter.assigned:
      return 'Assigned';
    case NotifFilter.all:
      return '';
  }
}

// ── Model ───────────────────────────────────────────────────────────────

class TaskNotification {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  final NotifFilter status; // which tab this belongs to
  final NotifSeverity severity; // drives all coloring
  final bool expandable; // trailing chevron for grouped items
  final bool isRead;

  const TaskNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.status,
    required this.severity,
    this.expandable = false,
    this.isRead = false,
  });

  /// EXPECTED API SHAPE:
  /// {
  ///   "id": "n1",
  ///   "title": "Human Assignment (2)",
  ///   "description": "Task \"Human Assignment\" is now due...",
  ///   "time": "2026-07-11T10:00:00Z",
  ///   "status": "due_now",       // -> NotifFilter
  ///   "severity": "warning",     // -> NotifSeverity (drives color)
  ///   "expandable": true,
  ///   "isRead": false
  /// }
  factory TaskNotification.fromJson(Map<String, dynamic> json) {
    return TaskNotification(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      time:
          DateTime.tryParse(json['time'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      status: filterFromApi(json['status'] as String?),
      severity: severityFromApi(json['severity'] as String?),
      expandable: (json['expandable'] as bool?) ?? false,
      isRead: (json['isRead'] as bool?) ?? false,
    );
  }

  TaskNotification copyWith({bool? isRead}) {
    return TaskNotification(
      id: id,
      title: title,
      description: description,
      time: time,
      status: status,
      severity: severity,
      expandable: expandable,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Mock data — matches the reference screenshot. Swap for a repository call
// once the API above is live; the widget tree below doesn't need to change.
final List<TaskNotification> _mockNotifications = [
  TaskNotification(
    id: 'n1',
    title: 'Human Assignment (2)',
    description:
        'Task "Human Assignment" is now due. Please complete and submit it.',
    time: DateTime.now().subtract(const Duration(hours: 4)),
    status: NotifFilter.dueNow,
    severity: NotifSeverity.warning,
    expandable: true,
  ),
  TaskNotification(
    id: 'n2',
    title: 'Task Overdue',
    description:
        'Task "Notification" was not completed within 5 minutes of reporting time.',
    time: DateTime.now().subtract(const Duration(hours: 19)),
    status: NotifFilter.overdue,
    severity: NotifSeverity.danger,
  ),
  TaskNotification(
    id: 'n3',
    title: 'Task Overdue',
    description:
        'Task "fvgfhfhjtyhtyhvtnhtybv" was not completed within 5 minutes of reporting time.',
    time: DateTime.now().subtract(const Duration(days: 2)),
    status: NotifFilter.overdue,
    severity: NotifSeverity.danger,
  ),
  TaskNotification(
    id: 'n4',
    title: 'Task Overdue',
    description:
        'Task "Code" was not completed within 5 minutes of reporting time.',
    time: DateTime.now().subtract(const Duration(days: 2)),
    status: NotifFilter.overdue,
    severity: NotifSeverity.danger,
  ),
  TaskNotification(
    id: 'n5',
    title: 'Task Overdue',
    description:
        'Task "close" was not completed within 5 minutes of reporting time.',
    time: DateTime.now().subtract(const Duration(days: 2)),
    status: NotifFilter.overdue,
    severity: NotifSeverity.danger,
  ),
  TaskNotification(
    id: 'n6',
    title: 'New Task Assigned',
    description: 'Task "Human Assignment" has been assigned to you.',
    time: DateTime.now().subtract(const Duration(days: 2)),
    status: NotifFilter.assigned,
    severity: NotifSeverity.info,
  ),
];

// ── Neutral (non-severity) UI colors ──────────────────────────────────

class _C {
  static const primary = Color(0xFF6C5CE7);
  static const chipSelectedBg = Color(0xFFEDE9FE);
  static const chipBorder = Color(0xFFE4E7EC);
  static const chipText = Color(0xFF667085);
  static const title = Color(0xFF1D2433);
  static const subtitle = Color(0xFF667085);
  static const sectionLabel = Color(0xFF98A2B3);
  static const cardBorder = Color(0xFFEAECF0);
  static const radioBorder = Color(0xFFD0D5DD);
}

// ── Screen ───────────────────────────────────────────────────────────────

class NotificationStart extends StatefulWidget {
  final String userId;
  final List<TaskNotification>? notifications; // defaults to mock data

  const NotificationStart({
    super.key,
    required this.userId,
    this.notifications,
  });

  @override
  State<NotificationStart> createState() => _NotificationStartState();
}

class _NotificationStartState extends State<NotificationStart> {
  NotifFilter _selectedFilter = NotifFilter.all;
  late List<TaskNotification> _items =
      widget.notifications ?? List.of(_mockNotifications);
  final Set<String> _selectedIds = {};

  List<TaskNotification> get _visible {
    if (_selectedFilter == NotifFilter.all) return _items;
    return _items.where((n) => n.status == _selectedFilter).toList();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      return '${m < 1 ? 1 : m}m ago';
    }
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool get _hasUnread => _items.any((n) => !n.isRead);

  void _markAllAsRead() {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  /// Tapping a card marks just that notification read. Local-only for now
  /// (mirrors `_markAllAsRead`) — swap in a repository call once the
  /// per-notification read-receipt endpoint exists; the optimistic
  /// setState here can stay as-is around it.
  void _markAsRead(String id) {
    if (_items.firstWhere((n) => n.id == id).isRead) return;
    setState(() {
      _items = [
        for (final n in _items)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ];
    });
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, size: 20.r, color: _C.title),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: _C.title,
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, size: 22.r, color: _C.subtitle),
          ),
        ],
      ),
    );
  }

  /// Dot color shown next to each filter option in the dropdown sheet.
  /// `all` gets the neutral primary color; the rest borrow their matching
  /// severity's dot color from kSeverityConfig, so the dropdown stays in
  /// sync automatically if the severity palette ever changes.
  Color _filterDotColor(NotifFilter f) {
    switch (f) {
      case NotifFilter.all:
        return _C.primary;
      case NotifFilter.overdue:
        return kSeverityConfig[NotifSeverity.danger]!.dot;
      case NotifFilter.dueNow:
        return kSeverityConfig[NotifSeverity.warning]!.dot;
      case NotifFilter.assigned:
        return kSeverityConfig[NotifSeverity.info]!.dot;
    }
  }

  String _filterDisplayLabel(NotifFilter f) {
    switch (f) {
      case NotifFilter.all:
        return 'All';
      case NotifFilter.overdue:
        return 'Overdue';
      case NotifFilter.dueNow:
        return 'Due now';
      case NotifFilter.assigned:
        return 'Assigned';
    }
  }

  int _countFor(NotifFilter f) {
    if (f == NotifFilter.all) return _items.length;
    return _items.where((n) => n.status == f).length;
  }

  Future<void> _openFilterSheet() async {
    final picked = await showModalBottomSheet<NotifFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                SizedBox(height: 10.h),
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: _C.chipBorder,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                  child: Text(
                    'Filter by',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: _C.title,
                    ),
                  ),
                ),
                ...NotifFilter.values.map((f) {
                  final selected = _selectedFilter == f;
                  return InkWell(
                    onTap: () => Navigator.pop(sheetContext, f),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 9.r,
                            height: 9.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _filterDotColor(f),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              _filterDisplayLabel(f),
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? _C.primary : _C.title,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _C.chipSelectedBg,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '${_countFor(f)}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: _C.primary,
                              ),
                            ),
                          ),
                          if (selected) ...[
                            SizedBox(width: 10.w),
                            Icon(
                              Icons.check_circle,
                              size: 18.r,
                              color: _C.primary,
                            ),
                          ] else
                            SizedBox(width: 28.r),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedFilter = picked);
    }
  }

  Widget _filterRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: _C.chipSelectedBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _filterDotColor(_selectedFilter),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _filterDisplayLabel(_selectedFilter),
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _C.primary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18.r,
                    color: _C.primary,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mark all as read',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: _C.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: _C.sectionLabel,
        ),
      ),
    );
  }

  /// Fixed-size radio circle. The previous 16.r + hairline-border version
  /// rendered as a broken partial arc at small sizes on some devices —
  /// this uses a slightly larger, explicitly-filled circle so it always
  /// paints as a clean ring regardless of pixel density.
  Widget _radio(String id, Color accent) {
    final selected = _selectedIds.contains(id);
    return GestureDetector(
      onTap: () => _toggleSelect(id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Extra invisible padding widens the actual tap target without
        // affecting the visible circle size.
        padding: EdgeInsets.all(4.w),
        child: Container(
          width: 20.r,
          height: 20.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? accent : Colors.white,
            border: Border.all(
              color: selected ? accent : _C.radioBorder,
              width: 1.6,
            ),
          ),
          child: selected
              ? Icon(Icons.check, size: 13.r, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _statusPill(NotifSeverity severity, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    final style = kSeverityConfig[severity]!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: style.pillBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w600,
          color: style.pillFg,
        ),
      ),
    );
  }

  Widget _card(TaskNotification n) {
    final style = kSeverityConfig[n.severity]!;
    return GestureDetector(
      key: ValueKey(n.id),
      behavior: HitTestBehavior.opaque,
      onTap: () => _markAsRead(n.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: style.cardBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _radio(n.id, style.dot),
            SizedBox(width: 6.w),

            // Severity icon box — color/icon fully driven by kSeverityConfig.
            Container(
              width: 34.r,
              height: 34.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: style.iconWrapBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(style.icon, size: 17.r, color: style.iconWrapFg),
            ),
            SizedBox(width: 10.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _C.title,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    n.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: _C.subtitle,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.r, color: _C.subtitle),
                      SizedBox(width: 4.w),
                      Text(
                        _relativeTime(n.time),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: _C.subtitle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _statusPill(n.severity, filterLabel(n.status)),
                    ],
                  ),
                ],
              ),
            ),

            if (n.expandable) ...[
              SizedBox(width: 6.w),
              Icon(Icons.chevron_right, size: 18.r, color: _C.subtitle),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Divider(height: 1, color: _C.cardBorder),
            SizedBox(height: 14.h),
            _filterRow(),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications here.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: _C.subtitle,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _sectionLabel('EARLIER TODAY');
                        return _card(items[index - 1]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
