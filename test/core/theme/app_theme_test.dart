import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses PRD tokens', () {
      final theme = AppTheme.light();
      final colors = theme.extension<AppColors>()!;
      expect(colors.background, const Color(0xFFFBF7F0));
      expect(colors.primary, const Color(0xFF1F6F54));
      expect(colors.primaryContainer, const Color(0xFFD8EBDD));
      expect(theme.scaffoldBackgroundColor, colors.background);
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme uses PRD tokens', () {
      final theme = AppTheme.dark();
      final colors = theme.extension<AppColors>()!;
      expect(colors.background, const Color(0xFF101713));
      expect(colors.primary, const Color(0xFF7FD1A8));
      expect(colors.statusAlert, const Color(0xFFFF8E80));
      expect(theme.brightness, Brightness.dark);
    });

    test('text theme uses PlusJakartaSans and PRD sizes', () {
      final textTheme = AppTheme.light().textTheme;
      expect(textTheme.displaySmall?.fontFamily, AppTextStyles.fontFamily);
      expect(textTheme.displaySmall?.fontSize, 28);
      expect(textTheme.titleLarge?.fontSize, 22);
      expect(textTheme.titleMedium?.fontSize, 17);
      expect(textTheme.bodyLarge?.fontSize, 16);
      expect(textTheme.bodySmall?.fontSize, 14);
      expect(textTheme.labelLarge?.fontSize, 13);
    });
  });

  group('AppColors extension', () {
    test('copyWith overrides only requested tokens', () {
      final updated = AppColors.light.copyWith(primary: const Color(0xFF000000));
      expect(updated.primary, const Color(0xFF000000));
      expect(updated.background, AppColors.light.background);
      expect(updated.accent, AppColors.light.accent);
    });

    test('lerp returns midpoint colors', () {
      final lerped = AppColors.light.lerp(AppColors.dark, 0.5);
      expect(lerped.background,
          Color.lerp(AppColors.light.background, AppColors.dark.background, 0.5));
    });

    test('status colors are distinct from surface', () {
      for (final colors in [AppColors.light, AppColors.dark]) {
        expect(colors.statusGood, isNot(colors.surface));
        expect(colors.statusAlert, isNot(colors.surface));
      }
    });
  });

  group('Spacing and radius tokens (PRD 7.4)', () {
    test('spacing scale is 4pt based', () {
      expect(
        [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
        ],
        [4, 8, 12, 16, 20, 24, 32],
      );
      expect(AppSpacing.screenPadding, 20);
      expect(AppSpacing.sectionGap, 28);
    });

    test('radius tokens match PRD', () {
      expect(AppRadius.control, 12);
      expect(AppRadius.card, 20);
      expect(AppRadius.pill, 999);
    });
  });
}
