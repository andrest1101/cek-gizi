import 'package:flutter/material.dart';

/// Panduan lingkaran untuk pemotongan foto profil: area di luar lingkaran
/// diredupkan, lingkaran sendiri diberi garis tepi.
///
/// Dipakai sebagai overlay di atas foto yang bisa di-geser/di-zoom.
class CircleCropGuidePainter extends CustomPainter {
  const CircleCropGuidePainter({
    required this.overlayColor,
    required this.borderColor,
  });

  final Color overlayColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final circle = Rect.fromCircle(center: center, radius: radius);

    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addOval(circle),
    );
    canvas.drawPath(outside, Paint()..color = overlayColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(CircleCropGuidePainter oldDelegate) =>
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.borderColor != borderColor;
}
