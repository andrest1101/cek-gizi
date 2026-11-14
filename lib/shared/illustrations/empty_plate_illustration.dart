import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi "piring kosong" untuk empty state makan/riwayat (PRD §7.1).
///
/// Murni `CustomPainter` (tanpa aset PNG) dan hanya memakai token tema,
/// sehingga terlihat baik di light/dark. Dekoratif: konteks teks di
/// sebelahnya selalu membawa makna.
class EmptyPlateIllustration extends StatelessWidget {
  const EmptyPlateIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _EmptyPlatePainter(
          plate: colors.primaryContainer,
          inner: colors.surface,
          line: colors.outline,
        ),
      ),
    );
  }
}

class _EmptyPlatePainter extends CustomPainter {
  const _EmptyPlatePainter({
    required this.plate,
    required this.inner,
    required this.line,
  });

  final Color plate;
  final Color inner;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);

    // Piring: cincin luar + bagian dalam.
    canvas.drawCircle(center, size.width * 0.36, Paint()..color = plate);
    canvas.drawCircle(center, size.width * 0.24, Paint()..color = inner);

    // Garis kecil di dalam piring (tekstur "piring bersih").
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.15),
      math.pi * 0.12,
      math.pi * 0.32,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.width * 0.022
        ..color = line,
    );

    // Sendok di kiri.
    final utensil = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.026
      ..color = line;
    final spoonX = size.width * 0.17;
    final spoonTop = size.height * 0.36;
    canvas.drawLine(
      Offset(spoonX, spoonTop + size.height * 0.09),
      Offset(spoonX, spoonTop + size.height * 0.36),
      utensil,
    );
    canvas.drawCircle(Offset(spoonX, spoonTop), size.width * 0.052, utensil);

    // Garpu di kanan.
    final forkX = size.width * 0.83;
    final forkTop = size.height * 0.33;
    canvas.drawLine(
      Offset(forkX, forkTop + size.height * 0.14),
      Offset(forkX, forkTop + size.height * 0.37),
      utensil,
    );
    for (var index = -1; index <= 1; index++) {
      canvas.drawLine(
        Offset(forkX + index * size.width * 0.036, forkTop),
        Offset(forkX + index * size.width * 0.036,
            forkTop + size.height * 0.13),
        utensil,
      );
    }

    // Dua garis uap di atas piring.
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.024
      ..color = line;
    for (var index = 0; index < 2; index++) {
      final x = size.width * (0.44 + index * 0.14);
      final y = size.height * 0.24;
      final path = Path()
        ..moveTo(x, y + size.height * 0.10)
        ..quadraticBezierTo(
          x + size.width * 0.055,
          y + size.height * 0.05,
          x,
          y,
        )
        ..quadraticBezierTo(
          x - size.width * 0.055,
          y - size.height * 0.05,
          x,
          y - size.height * 0.10,
        );
      canvas.drawPath(path, steam);
    }
  }

  @override
  bool shouldRepaint(_EmptyPlatePainter oldDelegate) =>
      oldDelegate.plate != plate ||
      oldDelegate.inner != inner ||
      oldDelegate.line != line;
}
