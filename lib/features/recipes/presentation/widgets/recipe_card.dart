import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_group_thumb.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_meta.dart';

/// Kartu katalog resep. seluruh isi berasal dari berkas resep terkurasi.
///
/// Kartu adalah satu tombol besar (target sentuh penuh) yang membuka detail.
/// Sampul memakai kolase logo kelompok pangan, bukan foto karangan.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final bandLabel = AppStrings.recipesFilterBandLabel(recipe.ageBand.code);
    final groupLabels = recipe.groups.map(AppStrings.groupLabel).join(', ');
    final semanticsLabel =
        '${AppStrings.recipesCardSemantics(recipe.title, recipe.minutes, bandLabel)} '
        '${AppStrings.recipesThumbSemantics(groupLabels)}'
        '${recipe.animalProtein ? ' ${AppStrings.recipesProteinBadge}.' : ''}';

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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeGroupThumb(groups: recipe.groups),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
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
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RecipeMinutesMeta(minutes: recipe.minutes),
                              RecipeBandPill(bandCode: recipe.ageBand.code),
                              if (recipe.animalProtein)
                                const RecipeProteinPill(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final code in recipe.groups)
                      RecipeGroupChip(code: code),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
