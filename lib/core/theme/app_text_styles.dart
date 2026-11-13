import 'package:flutter/material.dart';

/// Skala tipografi Plus Jakarta Sans (PRD §7.3).
///
/// Style di sini hanya ukuran/tinggi/berat - **tanpa warna**. Warna diambil
/// dari theme (`textTheme`) atau [AppColors] di call site.
abstract final class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'PlusJakartaSans';

  /// Angka besar: hero "4/8", berat 7,4 kg (28/34, w700, tabular figures).
  static const TextStyle heroNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Angka metrik kartu: "8,2 kg" (26/32, w700, tabular figures).
  static const TextStyle metricNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Judul layar (22/28, w700).
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
  );

  /// Judul section / kartu (17/24, w600).
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Body utama (16/24, w400).
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// Body angka (16/24, w400, tabular figures) - berat, tinggi, z-score.
  static const TextStyle bodyTabular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Body kecil (14/20, w400).
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  /// Label / caption (13/16, w500).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w500,
  );
}
