import 'package:flutter/material.dart';

/// Dekorasi halus di belakang kartu hero: dua kelompok busur konsentris dan
/// tiga titik, meniru motif piring. Digambar dengan alpha rendah agar tidak
/// mengganggu keterbacaan ring dan teks.
class HeroPatternPainter extends CustomPainter {
  const HeroPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final topRight = Offset(size.width * 1.04, -size.height * 0.06);
    for (final factor in <double>[0.26, 0.38, 0.50]) {
      canvas.drawCircle(topRight, size.width * factor, stroke);
    }

    final bottomLeft = Offset(-size.width * 0.08, size.height * 1.02);
    for (final factor in <double>[0.16, 0.26]) {
      canvas.drawCircle(bottomLeft, size.width * factor, stroke);
    }

    for (final point in <Offset>[
      Offset(size.width * 0.72, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.28),
      Offset(size.width * 0.16, size.height * 0.86),
    ]) {
      canvas.drawCircle(point, 2, dot);
    }
  }

  @override
  bool shouldRepaint(HeroPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
