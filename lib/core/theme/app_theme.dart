import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Rakit [ThemeData] light/dark dari token (PRD §7.2–7.4).
///
/// Semua warna bersumber dari [AppColors] / [ColorScheme]; tidak ada literal
/// `Colors.*` di luar `ThemeExtension` dan file ini.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  /// Ambil token warna aktif dari context. Gunakan di widget:
  /// `final colors = AppTheme.colorsOf(context);`
  static AppColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          primaryContainer: colors.primaryContainer,
          onPrimaryContainer: colors.textPrimary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          surfaceContainerHighest: colors.surfaceVariant,
          outline: colors.outline,
          error: colors.statusAlert,
          onError: colors.onPrimary,
        );

    final textTheme = TextTheme(
      displaySmall: AppTextStyles.heroNumber.copyWith(color: colors.textPrimary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: colors.textPrimary),
      bodyMedium: AppTextStyles.body.copyWith(color: colors.textPrimary),
      bodySmall:
          AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
      labelLarge: AppTextStyles.label.copyWith(color: colors.textPrimary),
      labelMedium: AppTextStyles.label.copyWith(color: colors.textSecondary),
      labelSmall:
          AppTextStyles.label.copyWith(color: colors.textSecondary),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      extensions: [colors],
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: AppTextStyles.label,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: colors.outline, width: 1),
          textStyle: AppTextStyles.label,
          shape: controlShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle:
            AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.statusAlert, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.statusAlert, width: 1.5),
        ),
      ),
    );
  }
}
