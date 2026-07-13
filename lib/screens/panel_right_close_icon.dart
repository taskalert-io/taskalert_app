import 'package:flutter/material.dart';

/// Pixel-perfect custom-drawn "panel-right-close" icon.
/// Matches the Lucide panel-right-close glyph exactly, with zero
/// dependency on any icon font package — so it can never render
/// as a missing-glyph box.
///
/// Usage:
/// ```dart
/// PanelRightCloseIcon(
///   size: 20.r,
///   color: _textColor,
/// )
/// ```
class PanelRightCloseIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const PanelRightCloseIcon({
    super.key,
    this.size = 20,
    this.color = Colors.black,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PanelRightCloseIconPainter(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _PanelRightCloseIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PanelRightCloseIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base Lucide icon is drawn on a 24x24 grid — scale to the given size.
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer rounded rectangle (the panel/window frame): x=3,y=3 w=18,h=18, rx=2
    final outerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 18, 18),
      const Radius.circular(2),
    );
    canvas.drawRRect(outerRect, paint);

    // Vertical divider line separating the right-hand panel: x=15, from y=3 to y=21
    canvas.drawLine(const Offset(15, 3), const Offset(15, 21), paint);

    // Arrow pointing right, into the panel: chevron at ~ (10,9) -> (13,12) -> (10,15)
    final arrowPath = Path()
      ..moveTo(10, 9)
      ..lineTo(13, 12)
      ..lineTo(10, 15);
    canvas.drawPath(arrowPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PanelRightCloseIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
