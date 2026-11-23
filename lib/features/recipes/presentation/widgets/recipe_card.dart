import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_image.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_meta.dart';

/// Kartu katalog resep: foto asli di atas, lalu judul dan meta ringkas.
///
/// Seluruh isi berasal dari berkas resep terkurasi. Kartu adalah satu tombol
/// besar (target sentuh penuh) yang membuka detail. Rentang usia tidak
/// diulang di kartu karena sudah menjadi judul seksi di katalog.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.decodeWidth = 800,
  });

  /// Maksimum chip kelompok di kartu; sisanya diringkas menjadi "+N".
  static const int maxGroupChips = 3;

  final Recipe recipe;
  final VoidCallback onTap;

  /// Lebar decode foto (piksel fisik) - hemat memori untuk daftar panjang.
  final int? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final bandLabel = AppStrings.recipesFilterBandLabel(recipe.ageBand.code);
    final groupLabels = recipe.groups.map(AppStrings.groupLabel).join(', ');
    final semanticsLabel =
        '${AppStrings.recipesCardSemantics(recipe.title, recipe.minutes, bandLabel)} '
        '${AppStrings.recipesGroupCount(recipe.groupCount)}. '
        '${AppStrings.recipesThumbSemantics(groupLabels)}'
        '${recipe.animalProtein ? ' ${AppStrings.recipesProteinBadge}.' : ''}';
    final visibleGroups = recipe.groups.take(maxGroupChips).toList();
    final hiddenGroups = recipe.groups.length - visibleGroups.length;

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppSurfaces.cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: AppSurfaces.hairline(context),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: RecipeImage(
                  recipeId: recipe.id,
                  groups: recipe.groups,
                  decodeWidth: decodeWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RecipeMetaRow(
                      minutes: recipe.minutes,
                      groupCount: recipe.groupCount,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final code in visibleGroups)
                          RecipeGroupChip(code: code),
                        if (hiddenGroups > 0)
                          RecipeGroupOverflowChip(count: hiddenGroups),
                        if (recipe.animalProtein) const RecipeProteinPill(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
