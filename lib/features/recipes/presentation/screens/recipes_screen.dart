import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_filter_bar.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_notices.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Tab Resep (PRD §6.6): katalog resep terkurasi dari `recipes.json`.
///
/// Seluruh resep, bahan, langkah, dan catatan keamanan berasal dari berkas
/// yang disediakan pemilik - tidak ada konten karangan. Filter usia mengikuti
/// anak terpilih sampai pengguna memilih rentang lain. Konten yang belum
/// ditinjau ahli gizi/bidan selalu diberi penanda (PRD §9.1).
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(recipeFilterProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider).value;
    final allAsync = ref.watch(recipesProvider);
    final filteredAsync = ref.watch(filteredRecipesProvider);
    final now = ref.watch(clockProvider)();
    final unreviewed =
        allAsync.value?.any((recipe) => !recipe.isReviewed) ?? false;
    final showAsiNotice = child != null && child.ageInCompletedMonths(now) < 6;

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
            ScreenHeader(
              eyebrow: AppStrings.recipesEyebrow,
              title: AppStrings.recipesTitle,
              subtitle: AppStrings.recipesSubtitle,
              trailing: const ChildSwitcherButton(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (child == null) ...[
              RecipeNoChildNotice(
                onAddChild: () => context.push('/children/add'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (showAsiNotice) ...[
              const RecipeAsiNotice(),
              const SizedBox(height: AppSpacing.md),
            ],
            if (unreviewed) ...[
              const RecipeReviewNotice(),
              const SizedBox(height: AppSpacing.lg),
            ],
            RecipeFilterBar(
              searchController: _searchController,
              resultCount: filteredAsync.value?.length,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._buildResults(filteredAsync),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(AsyncValue<List<Recipe>> filtered) {
    return filtered.when(
      loading: () => [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const Skeleton(height: 132, radius: AppRadius.card),
        ],
      ],
      error: (error, stackTrace) => [
        ErrorCard(
          message: AppStrings.recipesLoadError,
          onRetry: () => ref.invalidate(recipesProvider),
        ),
      ],
      data: (recipes) {
        if (recipes.isEmpty) {
          return [
            EmptyState(
              icon: Icons.search_off_rounded,
              title: AppStrings.recipesEmptyTitle,
              body: AppStrings.recipesEmptyBody,
              action: OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text(AppStrings.recipesEmptyReset),
              ),
            ),
          ];
        }
        return [
          for (var i = 0; i < recipes.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            RecipeCard(
              recipe: recipes[i],
              onTap: () => context.push('/recipes/${recipes[i].id}'),
            ),
          ],
        ];
      },
    );
  }
}
