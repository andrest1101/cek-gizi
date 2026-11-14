import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi "bibit tumbuh" untuk empty state Tumbuh (PRD §7.1).
///
/// Pot + batang + dua daun; murni `CustomPainter` dan hanya memakai token
/// tema. Dekoratif: teks di sebelahnya selalu membawa makna.
class SeedlingIllustration extends StatelessWidget {
  const SeedlingIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SeedlingPainter(
          leaf: colors.primary,
          leafFill: colors.primaryContainer,
          pot: colors.accent,
          stem: colors.primary,
        ),
      ),
    );
  }
}

class _SeedlingPainter extends CustomPainter {
  const _SeedlingPainter({
    required this.leaf,
    required this.leafFill,
    required this.pot,
    required this.stem,
  });

  final Color leaf;
  final Color leafFill;
  final Color pot;
  final Color stem;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.88;

    // Pot: trapesium dengan tepi atas (rim).
    final potWidth = size.width * 0.4;
    final potHeight = size.height * 0.2;
    final potPath = Path()
      ..moveTo(centerX - potWidth * 0.5, baseY)
      ..lineTo(centerX + potWidth * 0.5, baseY)
      ..lineTo(centerX + potWidth * 0.38, baseY - potHeight)
      ..lineTo(centerX - potWidth * 0.38, baseY - potHeight)
      ..close();
    canvas.drawPath(
      potPath,
      Paint()..color = pot.withValues(alpha: 0.3),
    );
    canvas.drawLine(
      Offset(centerX - potWidth * 0.44, baseY - potHeight),
      Offset(centerX + potWidth * 0.44, baseY - potHeight),
      Paint()
        ..color = pot
        ..strokeWidth = size.width * 0.03
        ..strokeCap = StrokeCap.round,
    );

    // Batang.
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemBottom = Offset(centerX, baseY - potHeight);
    final stemTop = Offset(centerX, size.height * 0.26);
    canvas.drawLine(stemBottom, stemTop, stemPaint);

    // Dua daun (ke kiri dan ke kanan).
    _drawLeaf(
      canvas,
      origin: Offset(centerX, size.height * 0.52),
      direction: -1,
      size: size,
      fill: leafFill,
      stroke: leaf,
    );
    _drawLeaf(
      canvas,
      origin: Offset(centerX, size.height * 0.4),
      direction: 1,
      size: size,
      fill: leafFill,
      stroke: leaf,
    );
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset origin,
    required int direction,
    required Size size,
    required Color fill,
    required Color stroke,
  }) {
    final length = size.width * 0.3;
    final height = size.height * 0.13;
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        origin.dx + direction * length * 0.5,
        origin.dy - height,
        origin.dx + direction * length,
        origin.dy - height * 0.35,
      )
      ..quadraticBezierTo(
        origin.dx + direction * length * 0.45,
        origin.dy + height * 0.25,
        origin.dx,
        origin.dy,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.024,
    );
  }

  @override
  bool shouldRepaint(_SeedlingPainter oldDelegate) =>
      oldDelegate.leaf != leaf ||
      oldDelegate.leafFill != leafFill ||
      oldDelegate.pot != pot ||
      oldDelegate.stem != stem;
}
