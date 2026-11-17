import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi "gelembung tanya" untuk empty state Tanya Gizi (PRD §7.1).
///
/// Murni `CustomPainter` (tanpa aset PNG) dan hanya memakai token tema,
/// sehingga terlihat baik di light/dark. Dekoratif: konteks teks di
/// sebelahnya selalu membawa makna.
class ChatIllustration extends StatelessWidget {
  const ChatIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _ChatIllustrationPainter(
          bubble: colors.primary,
          dots: colors.onPrimary,
          accent: colors.accent,
          leaf: colors.surface,
        ),
      ),
    );
  }
}

class _ChatIllustrationPainter extends CustomPainter {
  const _ChatIllustrationPainter({
    required this.bubble,
    required this.dots,
    required this.accent,
    required this.leaf,
  });

  final Color bubble;
  final Color dots;
  final Color accent;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Gelembung chat: kotak membulat + ekor di kiri bawah.
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.14, s * 0.16, s * 0.72, s * 0.50),
      Radius.circular(s * 0.22),
    );
    canvas.drawRRect(bubbleRect, Paint()..color = bubble);

    final tail = Path()
      ..moveTo(s * 0.28, s * 0.64)
      ..lineTo(s * 0.18, s * 0.84)
      ..lineTo(s * 0.46, s * 0.64)
      ..close();
    canvas.drawPath(tail, Paint()..color = bubble);

    // Tiga titik ketikan di dalam gelembung.
    final dotPaint = Paint()..color = dots;
    const dotRadiusFactor = 0.045;
    for (var index = 0; index < 3; index++) {
      canvas.drawCircle(
        Offset(s * (0.32 + index * 0.18), s * 0.41),
        s * dotRadiusFactor,
        dotPaint,
      );
    }

    // Lingkaran aksen dengan daun (motif gizi) di kanan atas gelembung.
    final accentCenter = Offset(s * 0.78, s * 0.19);
    canvas.drawCircle(accentCenter, s * 0.155, Paint()..color = accent);

    canvas.save();
    canvas.translate(accentCenter.dx, accentCenter.dy);
    canvas.rotate(-math.pi / 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: s * 0.15,
        height: s * 0.078,
      ),
      Paint()..color = leaf,
    );
    canvas.drawLine(
      Offset(-s * 0.065, 0),
      Offset(s * 0.065, 0),
      Paint()
        ..color = accent
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChatIllustrationPainter oldDelegate) =>
      oldDelegate.bubble != bubble ||
      oldDelegate.dots != dots ||
      oldDelegate.accent != accent ||
      oldDelegate.leaf != leaf;
}
