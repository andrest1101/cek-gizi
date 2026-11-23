import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_group_thumb.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_log_sheet.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_meta.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_notices.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Detail resep (PRD §6.6): bahan, langkah, catatan keamanan, dan aksi
/// "Catat sebagai makan". Seluruh teks berasal dari berkas resep terkurasi.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeByIdProvider(recipeId));
    final child = ref.watch(selectedChildProvider).value;
    final recipe = recipeAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recipesDetailTitle)),
      body: recipeAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, stackTrace) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ErrorCard(
              message: AppStrings.recipesLoadError,
              onRetry: () => ref.invalidate(recipesProvider),
            ),
          ),
        ),
        data: (loaded) =>
            loaded == null ? const _NotFound() : _DetailBody(recipe: loaded),
      ),
      bottomNavigationBar: recipe == null
          ? null
          : _LogBar(recipe: recipe, child: child),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ListView(
      key: const Key('recipe-detail-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeGroupThumb(groups: recipe.groups, size: 96),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        recipe.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.textPrimary,
                        ),
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
                        if (recipe.animalProtein) const RecipeProteinPill(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.recipesGroupCount(recipe.groupCount),
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle(
          icon: Icons.shopping_basket_outlined,
          text: AppStrings.recipesIngredientsTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        _IngredientsCard(ingredients: recipe.ingredients),
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle(
          icon: Icons.format_list_numbered_rounded,
          text: AppStrings.recipesStepsTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < recipe.steps.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _StepRow(number: i + 1, text: recipe.steps[i]),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle(
          icon: Icons.health_and_safety_outlined,
          text: AppStrings.recipesSafetyTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SafetyNote(
          icon: Icons.soup_kitchen_rounded,
          iconColor: colors.primary,
          label: AppStrings.recipesTextureLabel,
          note: recipe.textureNote,
        ),
        const SizedBox(height: AppSpacing.md),
        _SafetyNote(
          icon: recipe.hasAllergenNote
              ? Icons.warning_amber_rounded
              : Icons.info_outline_rounded,
          iconColor: recipe.hasAllergenNote
              ? colors.onAccentContainer
              : colors.textSecondary,
          label: AppStrings.recipesAllergenLabel,
          note: recipe.hasAllergenNote
              ? recipe.allergenNote
              : AppStrings.recipesNoAllergenNote,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (recipe.isReviewed)
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: colors.statusGood),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  recipe.reviewedOn != null
                      ? AppStrings.recipesReviewedBy(
                          recipe.reviewedBy!,
                          recipe.reviewedOn!,
                        )
                      : AppStrings.recipesReviewedByName(recipe.reviewedBy!),
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          )
        else
          const RecipeReviewNotice(compact: true),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.recipesDisclaimer,
          style: AppTextStyles.label.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.ingredients});

  final List<RecipeIngredient> ingredients;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < ingredients.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.outline,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
            Semantics(
              label: AppStrings.recipesIngredientSemantics(
                ingredients[i].name,
                ingredients[i].amount,
              ),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ingredients[i].name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        ingredients[i].amount,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      label: '${AppStrings.recipesStepSemantics(number)}. $text',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.label.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control + 4),
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  note,
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

class _LogBar extends StatelessWidget {
  const _LogBar({required this.recipe, required this.child});

  final Recipe recipe;
  final ChildProfile? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final canLog = child != null;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!canLog) ...[
                Text(
                  AppStrings.recipesLogNoChild,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton.icon(
                key: const Key('recipe-detail-log'),
                onPressed: canLog
                    ? () => showRecipeLogSheet(
                        context,
                        recipe: recipe,
                        childId: child!.id,
                      )
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                icon: const Icon(Icons.restaurant_rounded),
                label: const Text(AppStrings.recipesLogCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: AppStrings.recipesNotFoundTitle,
          body: AppStrings.recipesNotFoundBody,
          action: FilledButton(
            onPressed: () => context.pop(),
            child: const Text(AppStrings.recipesBackToCatalog),
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        Skeleton(height: 120, radius: AppRadius.card),
        SizedBox(height: AppSpacing.xl),
        Skeleton(width: 120, height: 18),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 140, radius: AppRadius.card),
        SizedBox(height: AppSpacing.xl),
        Skeleton(width: 160, height: 18),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 24),
        SizedBox(height: AppSpacing.sm),
        Skeleton(height: 24),
        SizedBox(height: AppSpacing.sm),
        Skeleton(height: 24),
      ],
    );
  }
}
