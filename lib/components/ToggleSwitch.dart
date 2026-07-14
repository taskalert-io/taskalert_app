import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared on/off toggle control — small pill track with an animated thumb.
///
/// Promoted from `NotificationStart.dart` (which had the only correctly
/// shared version) to replace 4 other screens' independent, pixel-identical
/// private `_buildToggle` methods. Adds a `Semantics(toggled: ...)` role so
/// this reads as a real toggle to assistive technology, which none of the
/// previous copies had.
class ToggleSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  /// Track/thumb color when [value] is true. Defaults to this app's
  /// standard "on" green.
  final Color activeColor;

  /// Track/thumb color when [value] is false. Defaults to this app's
  /// standard "off" color.
  final Color inactiveColor;

  /// Accessible label announced alongside the toggled state, e.g. "Proof
  /// required". Optional — omit for a toggle whose adjacent text label
  /// already describes it.
  final String? semanticLabel;

  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onTap,
    this.activeColor = const Color(0xFF1DC230),
    this.inactiveColor = const Color(0xFF676299),
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30.w,
          height: 15.h,
          padding: EdgeInsets.all(1.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: value ? activeColor : inactiveColor,
              width: 1.2,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14.w,
              height: 14.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? activeColor : inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
