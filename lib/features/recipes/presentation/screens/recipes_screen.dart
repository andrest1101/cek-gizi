import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';

/// Tab Resep (PRD §6.6).
///
/// Katalog belum dirilis karena `recipes.json` masih ditinjau ahli gizi.
/// Layar ini sengaja **tidak** menampilkan contoh resep karangan: aturan
/// proyek melarang mengarang data gizi. Begitu aset tersedia, daftar resep
/// menggantikan empty state ini tanpa mengubah navigasi.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      floatingActionButton: const TanyaBubble(),
      body: SafeArea(
        child: ListView(
          key: const Key('recipes-list'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxxl + AppSpacing.lg,
          ),
          children: [
            const ScreenHeader(
              eyebrow: AppStrings.recipesEyebrow,
              title: AppStrings.recipesTitle,
              subtitle: AppStrings.recipesSubtitle,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const EmptyState(
              icon: Icons.menu_book_rounded,
              title: AppStrings.recipesPendingTitle,
              body: AppStrings.recipesPendingBody,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.recipesPendingNote,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
