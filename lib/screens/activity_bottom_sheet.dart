import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Adjust these to match your app's theme constants ──────────────────────
const Color _primaryColor = Color(0xFF0A0258);
const Color _textColor = Color(0xFF1D1B20);
const Color _mutedColor = Color(0xFF8E8E93);

/// Model for a single activity feed item.
class ActivityItem {
  final String text;
  final String timeAgo;
  final bool isExpandable; // true for a "Show more" style row

  const ActivityItem({
    required this.text,
    required this.timeAgo,
    this.isExpandable = false,
  });
}

/// Call this to open the Activity popup as a bottom sheet.
Future<void> showActivityBottomSheet(
  BuildContext context, {
  required List<ActivityItem> activities,
  required VoidCallback onDelete,
  required VoidCallback onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ActivityBottomSheet(
      activities: activities,
      onDelete: onDelete,
      onSubmit: onSubmit,
    ),
  );
}

class ActivityBottomSheet extends StatelessWidget {
  final List<ActivityItem> activities;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const ActivityBottomSheet({
    super.key,
    required this.activities,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Sheet takes up to 85% of screen height, but shrinks to fit content.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Activity',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.r), // Better tap area
                      child: Icon(Icons.close, size: 20.r, color: _textColor),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Scrollable activity list (grows/scrolls, footer stays put) ──
            Flexible(
              child: Container(
                color: const Color(0xFFF2F2F7),
                child: activities.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Center(
                          child: Text(
                            'No activity yet',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: _mutedColor,
                            ),
                          ),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                          itemCount: activities.length,
                          separatorBuilder: (_, __) => SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            final item = activities[index];
                            return _ActivityRow(item: item);
                          },
                        ),
                      ),
              ),
            ),

            // ── Fixed footer action buttons ────────────────────────
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // "Show more" style rows: chevron + text only, both vertically
    // centered on the same line — no bullet, no timestamp.
    if (item.isExpandable) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.chevron_right, size: 16.r, color: _mutedColor),
          SizedBox(width: 6.w),
          Text(
            item.text,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: _mutedColor,
            ),
          ),
        ],
      );
    }

    // Regular activity rows: bullet dot top-aligned with (possibly
    // multi-line) text, plus a trailing timestamp.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 5.h, right: 10.w),
          child: Container(
            width: 5.w,
            height: 5.w,
            decoration: const BoxDecoration(
              color: _textColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            item.text,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          item.timeAgo,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF2DD4BF), Color(0xFFA855F7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
