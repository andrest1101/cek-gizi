import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Permukaan kartu & blok yang konsisten di light/dark (PRD §7.1–7.2).
///
/// Kedalaman visual datang dari lapisan tone + hairline — bukan bayangan,
/// bukan gradien:
/// - `card`: permukaan utama (light putih + garis rambut, dark tone naik).
/// - `sunken`: blok di dalam kartu (lebih gelap dari kartu di kedua mode).
/// - `hero`: sorotan lembut (mis. kartu anak terpilih) memakai
///   `primaryContainer` yang dicadangkan PRD §7.1.
abstract final class AppSurfaces {
  const AppSurfaces._();

  /// Permukaan kartu utama di atas latar layar.
  static BoxDecoration card(
    BuildContext context, {
    double radius = AppRadius.card,
  }) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? colors.surfaceVariant : colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: isDark ? null : Border.all(color: colors.outline, width: 1),
    );
  }

  /// Blok inset di dalam kartu (lebih gelap dari kartu di kedua mode).
  static BoxDecoration sunken(
    BuildContext context, {
    double radius = AppRadius.control,
  }) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? colors.surface : colors.surfaceVariant,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Sorotan lembut `primaryContainer` (tanpa garis, tanpa gradien).
  static BoxDecoration hero(
    BuildContext context, {
    double radius = AppRadius.card,
  }) {
    final colors = AppTheme.colorsOf(context);
    return BoxDecoration(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Warna permukaan kartu aktif — untuk `Material`/ripple di atas kartu.
  static Color cardColor(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Theme.of(context).brightness == Brightness.dark
        ? colors.surfaceVariant
        : colors.surface;
  }

  /// Garis rambut (1px) untuk memisahkan blok.
  static BorderSide hairline(BuildContext context) =>
      BorderSide(color: AppTheme.colorsOf(context).outline, width: 1);
}
