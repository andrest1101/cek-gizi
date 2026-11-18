import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Blok skeleton untuk keadaan memuat (PRD §6.9).
///
/// Sengaja statis (tanpa animasi berulang) agar tidak memicu frame terus
/// menerus - termasuk saat widget test memakai `pumpAndSettle`.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.control,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;

  /// Warna blok; default `surfaceVariant`. Di atas permukaan hero pakai
  /// `heroTrack` agar tetap terbaca.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? colors.surfaceVariant,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
