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
class PiringRing extends StatelessWidget {
  const PiringRing({
    super.key,
    required this.met,
    this.size = 200,
    this.strokeWidth = 18,
    this.gapDegrees = 5,
    this.showCount = true,
    this.semanticsLabel,
  });

  /// Kelompok yang terisi hari ini (subset [FoodGroup.allCodes]).
  final Set<String> met;

  final double size;
  final double strokeWidth;

  /// Celah antar busur dalam derajat (PRD §6.3: ±4dp pada 200dp).
  final double gapDegrees;

  /// Tampilkan teks "n/8" di tengah.
  final bool showCount;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final label = semanticsLabel ??
        AppStrings.piringGroupsMetSemantics(met.length, FoodGroup.allCodes.length);

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
            colors: colors,
            strokeWidth: strokeWidth,
            gapDegrees: gapDegrees,
          ),
          child: showCount
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${met.length}/${FoodGroup.allCodes.length}',
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
    required this.colors,
    required this.strokeWidth,
    required this.gapDegrees,
  });

  final Set<String> met;
  final AppColors colors;
  final double strokeWidth;
  final double gapDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = 360 / FoodGroup.allCodes.length;
    final sweep = arc - gapDegrees;
    final startOffset = -math.pi / 2 + (gapDegrees / 2) * math.pi / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < FoodGroup.allCodes.length; i++) {
      final code = FoodGroup.allCodes[i];
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
      oldDelegate.colors != colors ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gapDegrees != gapDegrees;
}
