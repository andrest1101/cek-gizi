import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';

/// Bilah filter katalog: pencarian, rentang usia, dan saring protein hewani.
///
/// Chip usia digeser horizontal agar tetap muat di 360dp pada text scale 1,3.
/// Semua chip adalah tombol dengan target sentuh ≥ 48dp.
class RecipeFilterBar extends ConsumerWidget {
  const RecipeFilterBar({
    super.key,
    required this.searchController,
    this.resultCount,
  });

  final TextEditingController searchController;
  final int? resultCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final filter = ref.watch(recipeFilterProvider);
    final effectiveBand = ref.watch(recipeEffectiveBandProvider);
    final notifier = ref.read(recipeFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          textField: true,
          label: AppStrings.recipesSearchSemantics,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            onChanged: notifier.setQuery,
            decoration: InputDecoration(
              hintText: AppStrings.recipesSearchHint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colors.textSecondary,
              ),
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: AppStrings.recipesSearchClear,
                      onPressed: () {
                        searchController.clear();
                        notifier.setQuery('');
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: BorderSide(color: colors.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterPill(
                label: AppStrings.recipesFilterAll,
                semanticsLabel: AppStrings.recipesFilterAllSemantics,
                selected: effectiveBand == null,
                onTap: () => notifier.selectBand(null),
              ),
              for (final band in RecipeAgeBand.values) ...[
                const SizedBox(width: AppSpacing.sm),
                _FilterPill(
                  label: AppStrings.recipesFilterBandLabel(band.code),
                  semanticsLabel: AppStrings.recipesFilterBandSemantics(
                    band.code,
                  ),
                  selected: effectiveBand == band,
                  onTap: () => notifier.selectBand(band),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterPill(
              key: const Key('recipe-protein-filter'),
              label: AppStrings.recipesProteinFilter,
              semanticsLabel: AppStrings.recipesProteinFilterSemantics,
              icon: Icons.set_meal_rounded,
              selected: filter.animalProteinOnly,
              accent: true,
              onTap: notifier.toggleAnimalProtein,
            ),
            if (resultCount != null)
              Text(
                AppStrings.recipesResultCount(resultCount!),
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final background = selected
        ? (accent ? colors.accentContainer : colors.primaryContainer)
        : colors.surface;
    final foreground = selected
        ? (accent ? colors.onAccentContainer : colors.primary)
        : colors.textSecondary;
    final border = selected
        ? (accent ? colors.accent : colors.primary)
        : colors.outline;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
