/// Pemberitahuan jujur di katalog resep.
///
/// Konten yang belum ditinjau ahli gizi/bidan WAJIB diberi penanda
/// (PRD §9.1). Penanda tidak bisa ditutup agar tidak terlewat.
library;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Penanda "belum ditinjau" untuk katalog/detail resep.
class RecipeReviewNotice extends StatelessWidget {
  const RecipeReviewNotice({super.key, this.compact = false});

  /// true = satu baris ringkas (dipakai di detail); false = kartu katalog.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      container: true,
      label: AppStrings.recipesReviewPendingShort,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.accentContainer,
          borderRadius: BorderRadius.circular(AppRadius.control + 4),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: colors.onAccentContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                compact
                    ? AppStrings.recipesReviewPendingShort
                    : AppStrings.recipesReviewPendingNote,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.onAccentContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Catatan ASI eksklusif untuk anak < 6 bulan (resep tetap bisa dijelajahi).
class RecipeAsiNotice extends StatelessWidget {
  const RecipeAsiNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.child_care_rounded, size: 22, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.asiExclusiveTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.asiExclusiveBody,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ajakan menambah profil anak agar usia resep bisa disesuaikan.
class RecipeNoChildNotice extends StatelessWidget {
  const RecipeNoChildNotice({super.key, required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_alt_rounded,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.recipesNoChildTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.recipesNoChildBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onAddChild,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text(AppStrings.recipesNoChildCta),
            ),
          ),
        ],
      ),
    );
  }
}
