import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi skematik pertumbuhan untuk onboarding.
///
/// Hanya bentuk: kartu grafik, pita SD, dan garis tren. **Tidak ada angka,
/// label, atau data anak** — ilustrasi ini dekoratif dan tidak boleh dibaca
/// sebagai hasil pengukuran. Teks di sebelahnya yang membawa makna.
class OnboardingGrowthIllustration extends StatelessWidget {
  const OnboardingGrowthIllustration({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size * 0.82),
        painter: _GrowthIllustrationPainter(
          surface: colors.surface,
          outline: colors.outline,
          line: colors.primary,
          band: colors.primaryContainer,
          accent: colors.accent,
        ),
      ),
    );
  }
}

class _GrowthIllustrationPainter extends CustomPainter {
  const _GrowthIllustrationPainter({
    required this.surface,
    required this.outline,
    required this.line,
    required this.band,
    required this.accent,
  });

  final Color surface;
  final Color outline;
  final Color line;
  final Color band;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kartu grafik.
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.90, h * 0.84),
      Radius.circular(w * 0.07),
    );
    canvas.drawRRect(card, Paint()..color = surface);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline,
    );

    // Garis bantu horizontal.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = outline.withValues(alpha: 0.75);
    for (final fy in const [0.30, 0.50, 0.70]) {
      canvas.drawLine(
        Offset(w * 0.12, h * fy),
        Offset(w * 0.88, h * fy),
        grid,
      );
    }

    // Pita SD: area di antara dua kurva.
    final bandPath = Path()
      ..moveTo(w * 0.12, h * 0.64)
      ..cubicTo(w * 0.32, h * 0.56, w * 0.52, h * 0.48, w * 0.88, h * 0.26)
      ..lineTo(w * 0.88, h * 0.46)
      ..cubicTo(w * 0.52, h * 0.66, w * 0.32, h * 0.76, w * 0.12, h * 0.80)
      ..close();
    canvas.drawPath(
      bandPath,
      Paint()..color = band.withValues(alpha: 0.55),
    );

    // Garis tren.
    final points = <Offset>[
      Offset(w * 0.14, h * 0.70),
      Offset(w * 0.34, h * 0.62),
      Offset(w * 0.54, h * 0.54),
      Offset(w * 0.74, h * 0.40),
      Offset(w * 0.86, h * 0.34),
    ];
    final trend = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      trend.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      trend,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    // Titik tren; titik terakhir memakai aksen.
    for (var index = 0; index < points.length; index++) {
      final isLast = index == points.length - 1;
      final radius = isLast ? 5.0 : 3.5;
      canvas.drawCircle(
        points[index],
        radius,
        Paint()..color = isLast ? accent : surface,
      );
      canvas.drawCircle(
        points[index],
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = isLast ? accent : line,
      );
    }
  }

  @override
  bool shouldRepaint(_GrowthIllustrationPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.outline != outline ||
      oldDelegate.line != line ||
      oldDelegate.band != band ||
      oldDelegate.accent != accent;
}
