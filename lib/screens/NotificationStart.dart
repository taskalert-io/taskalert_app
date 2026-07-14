import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../core/features/notifications/controllers/notification_controller.dart';
import '../core/features/notifications/data/models/notification_model.dart';
import '../utils/injection_container.dart';

// ── Severity system ────────────────────────────────────────────────────
//
// Mirrors the web SEVERITY_CONFIG 1:1 (danger / warning / info), so the
// backend can send a plain `"severity": "danger"` string and every color
// in this screen follows automatically — no per-screen color branching.
// `NotifFilter` (below) stays a separate concept: it's the *category*
// tab the user filters by (All / Overdue / Due now / Assigned), while
// `NotifSeverity` is what actually drives color.

enum NotifSeverity { success, danger, warning, info }

class SeverityStyle {
  final Color dot;
  final Color iconWrapBg;
  final Color iconWrapFg;
  final Color pillBg;
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

const Map<NotifSeverity, SeverityStyle> kSeverityConfig = {
  NotifSeverity.success: SeverityStyle(
    dot: Color(0xFF22C55E),
    iconWrapBg: Color(0xFFDCFCE7),
    iconWrapFg: Color(0xFF22C55E),
    pillBg: Color(0xFFDCFCE7),
    pillFg: Color(0xFF22C55E),
    cardBorder: Color(0xFFBBF7D0),
    icon: Icons.check_circle_rounded,
  ),
  NotifSeverity.danger: SeverityStyle(
    dot: Color(0xFFEF4444),
    iconWrapBg: Color(0xFFFEE2E2),
    iconWrapFg: Color(0xFFEF4444),
    pillBg: Color(0xFFFEE2E2),
    pillFg: Color(0xFFEF4444),
    cardBorder: Color(0xFFFECACA),
    icon: Icons.warning_rounded,
  ),
  NotifSeverity.warning: SeverityStyle(
    dot: Color(0xFFF59E0B),
    iconWrapBg: Color(0xFFFEF3C7),
    iconWrapFg: Color(0xFFF59E0B),
    pillBg: Color(0xFFFEF3C7),
    pillFg: Color(0xFFF59E0B),
    cardBorder: Color(0xFFFDE68A),
    icon: Icons.warning_rounded,
  ),
  NotifSeverity.info: SeverityStyle(
    dot: Color(0xFF3B82F6),
    iconWrapBg: Color(0xFFBFDBFE),
    iconWrapFg: Color(0xFF1D4ED8),
    pillBg: Color(0xFFBFDBFE),
    pillFg: Color(0xFF1D4ED8),
    cardBorder: Color(0xFFBFDBFE),
    icon: Icons.info_outline,
  ),
};

NotifSeverity severityFromApi(String? raw) {
  switch (raw) {
    case 'success':
      return NotifSeverity.success;
    case 'danger':
    case 'error':
    case 'critical':
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
    case 'task_overdue':
      return NotifFilter.overdue;
    // Confirmed against real API data: a "due now" notification's `type`
    // is 'reporting_time' (title "Task Due for Reporting"), not
    // 'due_now'/'task_due' as originally guessed.
    case 'reporting_time':
    case 'due_now':
    case 'dueNow':
    case 'task_due':
      return NotifFilter.dueNow;
    // Confirmed: an "assigned" notification's `type` is 'task_created'
    // (title "New Task Assigned"), not 'assigned'/'task_assigned'.
    case 'task_created':
    case 'assigned':
    case 'task_assigned':
      return NotifFilter.assigned;
    default:
      return NotifFilter.all;
  }
}

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

// ── Display model ───────────────────────────────────────────────────────

class TaskNotification {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  final NotifFilter status;
  final NotifSeverity severity;
  final bool isRead;

  const TaskNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.status,
    required this.severity,
    this.isRead = false,
  });

  factory TaskNotification.fromModel(NotificationModel model) {
    return TaskNotification(
      id: model.id ?? '',
      title: (model.title == null || model.title!.isEmpty)
          ? 'Notification'
          : model.title!,
      description: model.description ?? '',
      time: model.sendAt ?? model.createdAt ?? DateTime.now(),
      status: filterFromApi(model.type),
      severity: severityFromApi(model.severity),
      isRead: model.isRead == true,
    );
  }
}

/// Formats a DateTime as "3 minutes ago" / "2 hours ago" / "yesterday at
/// 7:57 PM" / "Aug 10", computed live rather than hardcoded.
class RelativeTime {
  static String format(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) {
      return 'yesterday at ${_formatClock(dt)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return shortDate(dt);
  }

  static String shortDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}';
  }

  static String _formatClock(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

enum _DateBucket { today, yesterday, earlier }

_DateBucket _bucketFor(DateTime dt) {
  final now = DateTime.now();
  final d = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (d == today) return _DateBucket.today;
  if (d == yesterday) return _DateBucket.yesterday;
  return _DateBucket.earlier;
}

String _bucketLabel(_DateBucket b) {
  switch (b) {
    case _DateBucket.today:
      return 'TODAY';
    case _DateBucket.yesterday:
      return 'YESTERDAY';
    case _DateBucket.earlier:
      return 'EARLIER';
  }
}

// ── Neutral (non-severity) UI colors ──────────────────────────────────

class _C {
  static const primary = Color(0xFF6C5CE7);
  static const chipSelectedBg = Color(0xFFEDE9FE);
  static const chipBorder = Color(0xFFE4E7EC);
  static const title = Color(0xFF1D2433);
  static const subtitle = Color(0xFF667085);
  static const sectionLabel = Color(0xFF98A2B3);
  static const cardBorder = Color(0xFFEAECF0);
  static const radioBorder = Color(0xFFD0D5DD);
}

// ── Screen ───────────────────────────────────────────────────────────────

class NotificationStart extends StatefulWidget {
  final String userId;

  const NotificationStart({super.key, required this.userId});

  @override
  State<NotificationStart> createState() => _NotificationStartState();
}

class _NotificationStartState extends State<NotificationStart> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final NotificationController _notificationController =
      sl<NotificationController>();

  NotifFilter _selectedFilter = NotifFilter.all;
  bool _isLoading = true;
  bool _markingAllAsRead = false;
  final Set<String> _selectedIds = {};
  Timer? _relativeTimeTicker;

  List<TaskNotification> get _allItems => _notificationController.notifications
      .map(TaskNotification.fromModel)
      .toList();

  List<TaskNotification> get _visible {
    if (_selectedFilter == NotifFilter.all) return _allItems;
    return _allItems.where((n) => n.status == _selectedFilter).toList();
  }

  bool get _hasUnread => _notificationController.unreadCount > 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Keeps "3 minutes ago" -> "4 minutes ago" labels current.
    _relativeTimeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await _notificationController.handleGetNotifications();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (_notificationController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notificationController.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _markAllAsRead() async {
    if (_markingAllAsRead || !_hasUnread) return;
    setState(() => _markingAllAsRead = true);
    final success = await _notificationController.handleMarkAllRead();
    if (!mounted) return;
    setState(() => _markingAllAsRead = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationController.errorMessage ??
                'Could not mark all as read.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(String id) async {
    final match = _notificationController.notifications
        .where((n) => n.id == id)
        .firstOrNull;
    if (match == null || match.isRead == true) return;
    final success = await _notificationController.handleMarkRead(id: id);
    if (!mounted) return;
    setState(() {});
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationController.errorMessage ?? 'Could not mark as read.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    if (f == NotifFilter.all) return _allItems.length;
    return _allItems.where((n) => n.status == f).length;
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
          if (_markingAllAsRead)
            SizedBox(
              width: 14.r,
              height: 14.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_hasUnread)
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

  /// Fixed-size radio circle. Purely a local selection affordance (mirrors
  /// the reference design) — independent of read/unread state.
  Widget _radio(String id, Color accent) {
    final selected = _selectedIds.contains(id);
    return GestureDetector(
      onTap: () => _toggleSelect(id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
          color: n.isRead ? Colors.white : const Color(0xFFFAFAFF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: style.cardBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _radio(n.id, style.dot),
            SizedBox(width: 6.w),
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
                  if (n.description.isNotEmpty) ...[
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
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.r, color: _C.subtitle),
                      SizedBox(width: 4.w),
                      Text(
                        RelativeTime.format(n.time),
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
            if (!n.isRead) ...[
              SizedBox(width: 6.w),
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListChildren(List<TaskNotification> items) {
    final widgets = <Widget>[];
    _DateBucket? lastBucket;
    for (final n in items) {
      final bucket = _bucketFor(n.time);
      if (bucket != lastBucket) {
        widgets.add(_sectionLabel(_bucketLabel(bucket)));
        lastBucket = bucket;
      }
      widgets.add(_card(n));
    }
    return widgets;
  }

  Widget _body() {
    if (_isLoading && _notificationController.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notificationController.errorMessage != null &&
        _notificationController.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 36.r, color: _C.subtitle),
              SizedBox(height: 10.h),
              Text(
                _notificationController.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13.sp, color: _C.subtitle),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _visible;
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120.h),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 36.r,
                        color: _C.subtitle,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'No notifications here.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: _C.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              physics: const AlwaysScrollableScrollPhysics(),
              children: _buildListChildren(items),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 0.h),

              child: Row(
                children: [
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
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: _C.title,
                    ),
                  ).paddingHorizontal(16.w),
                ],
              ),
            ),

            // Text(
            //   'Notifications',
            //   style: GoogleFonts.inter(
            //     fontSize: 15.sp,
            //     fontWeight: FontWeight.w700,
            //     color: _C.title,
            //   ),
            // ).paddingHorizontal(16.w),
            SizedBox(height: 10.h),
            Divider(height: 1, color: _C.cardBorder),
            SizedBox(height: 10.h),
            _filterRow(),
            Expanded(child: _body()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }
}

extension _PaddingHorizontal on Widget {
  Widget paddingHorizontal(double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: amount),
      child: this,
    );
  }
}

// `ThemeConst`/`ToggleSwitch` that used to live here have moved to
// `lib/components/ToggleSwitch.dart` — that's now the single shared
// implementation used across every screen with a toggle control.
