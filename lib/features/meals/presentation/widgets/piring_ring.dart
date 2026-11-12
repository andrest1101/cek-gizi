import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Ring 8 busur kelompok pangan "Piring Hari Ini" (PRD §6.3).
///
/// Busur menyala = kelompok terisi hari ini; busur protein hewani yang
/// menyala memakai `accent`; busur yang belum terisi = `surfaceVariant`.
/// Warna tidak pernah menjadi sinyal tunggal — label/teks di sebelahnya
/// selalu ada (PRD §7.2).
///
/// Hanya dipakai pada ukuran besar (hero Beranda). Pada ukuran kecil
/// (≤ 60dp) delapan segmen tidak terbaca — gunakan [PiringProgressRing].
class PiringRing extends StatelessWidget {
  const PiringRing({
    super.key,
    required this.met,
    this.codes = FoodGroup.allCodes,
    this.size = 200,
    this.strokeWidth = 18,
    this.gapDegrees,
    this.showCount = true,
    this.semanticsLabel,
  });

  /// Kelompok yang terisi hari ini (subset [codes]).
  final Set<String> met;

  /// Kelompok yang membentuk ring. Untuk usia 24–59 bulan semestanya 7
  /// kelompok (tanpa ASI) agar jumlah di tengah konsisten dengan target.
  final List<String> codes;

  final double size;
  final double strokeWidth;

  /// Celah antar busur dalam derajat. Bila null dihitung dari ketebalan
  /// stroke supaya jarak yang terlihat selalu ±4dp dan ujung bulat tidak
  /// saling menimpa.
  final double? gapDegrees;

  /// Tampilkan teks "n/8" di tengah.
  final bool showCount;

  final String? semanticsLabel;

  /// Jumlah kelompok yang terisi dalam semesta [codes].
  int get metCount => codes.where(met.contains).length;

  /// Celah busur yang membuat jarak visual antar ujung ±4dp.
  ///
  /// `jarak_dp ≈ radius × celah_radian`, jadi celah = (stroke + 4) / radius
  /// dalam radian. Dibatasi 45% lebar satu busur agar busur tidak hilang
  /// pada ring kecil. [segments] default 8 (semesta PRD §3.7).
  static double segmentGapDegrees({
    required double strokeWidth,
    required double size,
    int segments = 8,
  }) {
    final radius = (size - strokeWidth) / 2;
    if (radius <= 0 || segments <= 1) return 0;
    final byStroke = (strokeWidth + 4) / radius * 180 / math.pi;
    final maxByArc = (360 / segments) * 0.45;
    return math.min(byStroke, maxByArc);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final label = semanticsLabel ??
        AppStrings.piringGroupsMetSemantics(metCount, codes.length);
    final gap = gapDegrees ??
        segmentGapDegrees(
          strokeWidth: strokeWidth,
          size: size,
          segments: codes.length,
        );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size.square(size),
          painter: _PiringRingPainter(
            met: met,
            codes: codes,
            colors: colors,
            strokeWidth: strokeWidth,
            gapDegrees: gap,
          ),
          child: showCount
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$metCount/${codes.length}',
                        style: AppTextStyles.heroNumber.copyWith(
                          fontSize: 40,
                          height: 1.0,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        AppStrings.piringGroupsLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _PiringRingPainter extends CustomPainter {
  const _PiringRingPainter({
    required this.met,
    required this.codes,
    required this.colors,
    required this.strokeWidth,
    required this.gapDegrees,
  });

  final Set<String> met;
  final List<String> codes;
  final AppColors colors;
  final double strokeWidth;
  final double gapDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    if (radius <= 0 || codes.isEmpty) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = 360 / codes.length;
    final sweep = arc - gapDegrees;
    final startOffset = -math.pi / 2 + (gapDegrees / 2) * math.pi / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < codes.length; i++) {
      final code = codes[i];
      final isMet = met.contains(code);
      final isAnimal = FoodGroup.animalProteinCodes.contains(code);
      paint.color = isMet
          ? (isAnimal ? colors.accent : colors.primary)
          : colors.surfaceVariant;
      final startAngle = startOffset + i * arc * math.pi / 180;
      canvas.drawArc(
        rect,
        startAngle,
        sweep * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PiringRingPainter oldDelegate) =>
      oldDelegate.met != met ||
      oldDelegate.codes != codes ||
      oldDelegate.colors != colors ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gapDegrees != gapDegrees;
}

/// Ring progres monokrom untuk ukuran kecil (36–60dp): satu busur
/// terisi + angka `n/total`. Delapan segmen pada ukuran ini tidak terbaca,
/// sehingga jumlahnya dibuat eksplisit lewat angka.
class PiringProgressRing extends StatelessWidget {
  const PiringProgressRing({
    super.key,
    required this.met,
    required this.total,
    this.size = 52,
    this.strokeWidth = 7,
    this.showCount = true,
    this.semanticsLabel,
  });

  final int met;
  final int total;
  final double size;
  final double strokeWidth;
  final bool showCount;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final safeTotal = total <= 0 ? 1 : total;
    final safeMet = met < 0 ? 0 : (met > safeTotal ? safeTotal : met);
    final label =
        semanticsLabel ?? AppStrings.piringGroupsMetSemantics(safeMet, safeTotal);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size.square(size),
          painter: _ProgressRingPainter(
            progress: safeMet / safeTotal,
            trackColor: colors.surfaceVariant,
            progressColor: colors.primary,
            strokeWidth: strokeWidth,
          ),
          child: showCount
              ? Center(
                  child: Text(
                    '$safeMet/$safeTotal',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: (size * 0.26).clamp(10.0, 16.0),
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    if (radius <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, paint);

    if (progress <= 0) return;
    paint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (360 * progress.clamp(0.0, 1.0)) * math.pi / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
