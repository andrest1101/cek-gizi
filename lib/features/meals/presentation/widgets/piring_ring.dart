import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Ring 8 busur kelompok pangan "Piring Hari Ini" (PRD §6.3).
///
/// Busur menyala = kelompok terisi hari ini; busur protein hewani yang
/// menyala memakai `accent`; busur yang belum terisi = `surfaceVariant`.
/// Warna tidak pernah menjadi sinyal tunggal - label/teks di sebelahnya
/// selalu ada (PRD §7.2).
///
/// Hanya dipakai pada ukuran besar (hero Beranda). Pada ukuran kecil
/// (≤ 60dp) delapan segmen tidak terbaca - gunakan [PiringProgressRing].
class PiringRing extends StatelessWidget {
  const PiringRing({
    super.key,
    required this.met,
    this.codes = FoodGroup.allCodes,
    this.size = 200,
    this.strokeWidth = 18,
    this.gapDegrees,
    this.showCount = true,
    this.onHero = false,
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

  /// True bila ring berada di atas permukaan hero hijau tua: busur terisi
  /// memakai `onHeroSurface`, protein hewani `onHeroAccent`, dan busur kosong
  /// `heroTrack` agar kontras tetap terbaca.
  final bool onHero;

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
    final label =
        semanticsLabel ??
        AppStrings.piringGroupsMetSemantics(metCount, codes.length);
    final gap =
        gapDegrees ??
        segmentGapDegrees(
          strokeWidth: strokeWidth,
          size: size,
          segments: codes.length,
        );
    final metColor = onHero ? colors.onHeroSurface : colors.primary;
    final animalColor = onHero ? colors.onHeroAccent : colors.accent;
    final trackColor = onHero ? colors.heroTrack : colors.surfaceVariant;
    final valueColor = onHero ? colors.onHeroSurface : colors.textPrimary;
    final valueLabelColor = onHero
        ? colors.onHeroSurfaceMuted
        : colors.textSecondary;

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.of(context, AppMotion.ring),
          curve: AppMotion.easeOutCubic,
          builder: (context, progress, child) => CustomPaint(
            size: Size.square(size),
            painter: _PiringRingPainter(
              met: met,
              codes: codes,
              metColor: metColor,
              animalColor: animalColor,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
              gapDegrees: gap,
              progress: progress,
            ),
            child: child,
          ),
          child: showCount
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$metCount/${codes.length}',
                        style: AppTextStyles.displayMetric.copyWith(
                          height: 1.0,
                          color: valueColor,
                        ),
                      ),
                      Text(
                        AppStrings.piringGroupsLabel,
                        style: AppTextStyles.label.copyWith(
                          color: valueLabelColor,
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
    required this.metColor,
    required this.animalColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.gapDegrees,
    required this.progress,
  });

  /// 0 → 1 saat ring pertama muncul; 1 = semua busur menyala penuh.
  final double progress;

  final Set<String> met;
  final List<String> codes;
  final Color metColor;
  final Color animalColor;
  final Color trackColor;
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

    // Track digambar untuk semua busur dulu, lalu busur yang terisi menyala
    // bertahap dari kiri ke kanan. Saat `progress == 1` hasilnya identik
    // dengan tampilan statis sebelumnya.
    for (var i = 0; i < codes.length; i++) {
      final startAngle = startOffset + i * arc * math.pi / 180;
      paint.color = trackColor;
      canvas.drawArc(rect, startAngle, sweep * math.pi / 180, false, paint);
    }
    final visible = (progress.clamp(0.0, 1.0) * codes.length);
    for (var i = 0; i < codes.length; i++) {
      final local = (visible - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final code = codes[i];
      if (!met.contains(code)) continue;
      final isAnimal = FoodGroup.animalProteinCodes.contains(code);
      paint.color = isAnimal ? animalColor : metColor;
      final startAngle = startOffset + i * arc * math.pi / 180;
      canvas.drawArc(
        rect,
        startAngle,
        sweep * local * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PiringRingPainter oldDelegate) =>
      oldDelegate.met != met ||
      oldDelegate.codes != codes ||
      oldDelegate.metColor != metColor ||
      oldDelegate.animalColor != animalColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gapDegrees != gapDegrees ||
      oldDelegate.progress != progress;
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
        semanticsLabel ??
        AppStrings.piringGroupsMetSemantics(safeMet, safeTotal);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: safeMet / safeTotal),
          duration: AppMotion.of(context, AppMotion.ring),
          curve: AppMotion.easeOutCubic,
          builder: (context, value, child) => CustomPaint(
            size: Size.square(size),
            painter: _ProgressRingPainter(
              progress: value,
              trackColor: colors.surfaceVariant,
              progressColor: colors.primary,
              strokeWidth: strokeWidth,
            ),
            child: child,
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
