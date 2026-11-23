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

/// Kartu unggulan "Ide hari ini" di puncak katalog.
///
/// Dipilih deterministik dari tanggal perangkat (lihat
/// `RecipeCatalog.featured`) sehingga tampilan stabil sepanjang hari. Foto
/// besar jadi fokus, teks tetap di atas permukaan kartu - bukan di atas foto -
/// agar kontras aman di light maupun dark.
class RecipeFeaturedCard extends StatelessWidget {
  const RecipeFeaturedCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.decodeWidth = 1000,
  });

  /// Maksimum chip kelompok; sisanya diringkas menjadi "+N".
  static const int maxGroupChips = 3;

  final Recipe recipe;
  final VoidCallback onTap;

  /// Lebar decode foto (piksel fisik) - kartu selebar layar.
  final int? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final bandLabel = AppStrings.recipesFilterBandLabel(recipe.ageBand.code);
    final groupLabels = recipe.groups.map(AppStrings.groupLabel).join(', ');
    final semanticsLabel =
        '${AppStrings.recipesFeaturedSemantics(recipe.title, recipe.minutes, bandLabel)} '
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
                aspectRatio: 16 / 10,
                child: RecipeImage(
                  recipeId: recipe.id,
                  groups: recipe.groups,
                  decodeWidth: decodeWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            AppStrings.recipesFeaturedEyebrow.toUpperCase(),
                            style: AppTextStyles.label.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      recipe.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RecipeMetaRow(
                      minutes: recipe.minutes,
                      groupCount: recipe.groupCount,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RecipeBandPill(bandCode: recipe.ageBand.code),
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
