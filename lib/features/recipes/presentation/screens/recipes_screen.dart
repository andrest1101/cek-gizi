import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/services/recipe_catalog.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_featured_card.dart';
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
///
/// Saat pencarian kosong, satu resep tampil sebagai "Ide hari ini"
/// (deterministik per tanggal) dan sisanya dikelompokkan per rentang usia.
/// Saat mencari, hasil tampil sebagai daftar agar tidak menambah jarak baca.
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
    final filter = ref.watch(recipeFilterProvider);
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
            ..._buildResults(
              filteredAsync,
              now: now,
              showFeatured: RecipeCatalog.normalize(filter.query).isEmpty,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(
    AsyncValue<List<Recipe>> filtered, {
    required DateTime now,
    required bool showFeatured,
  }) {
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

        final sorted = RecipeCatalog.sorted(recipes);
        // Unggulan hanya saat menjelajah; hasil pencarian tampil apa adanya.
        // Minimal tiga resep agar kartu unggulan tidak menggantikan hampir
        // seluruh daftar.
        final featured = showFeatured && sorted.length >= 3
            ? RecipeCatalog.featured(sorted, now)
            : null;
        final remaining = featured == null
            ? sorted
            : [
                for (final recipe in sorted)
                  if (recipe.id != featured.id) recipe,
              ];

        final byBand = <RecipeAgeBand, List<Recipe>>{};
        for (final recipe in remaining) {
          byBand.putIfAbsent(recipe.ageBand, () => []).add(recipe);
        }
        // Judul seksi hanya berguna bila hasil mencakup lebih dari satu
        // rentang usia; bila tidak, filter usia di atas sudah menjelaskan.
        final grouped = byBand.length > 1;

        final widgets = <Widget>[];
        if (featured != null) {
          widgets
            ..add(
              RecipeFeaturedCard(
                recipe: featured,
                onTap: () => context.push('/recipes/${featured.id}'),
              ),
            )
            ..add(const SizedBox(height: AppSpacing.sectionGap));
        }

        var firstSection = true;
        for (final band in RecipeAgeBand.values) {
          final items = byBand[band];
          if (items == null) continue;
          if (grouped) {
            if (!firstSection) {
              widgets.add(const SizedBox(height: AppSpacing.lg));
            }
            widgets
              ..add(_BandHeader(code: band.code))
              ..add(const SizedBox(height: AppSpacing.sm));
          }
          for (var i = 0; i < items.length; i++) {
            if (i > 0) widgets.add(const SizedBox(height: AppSpacing.md));
            widgets.add(
              RecipeCard(
                recipe: items[i],
                onTap: () => context.push('/recipes/${items[i].id}'),
              ),
            );
          }
          firstSection = false;
        }
        return widgets;
      },
    );
  }
}

/// Judul seksi rentang usia dengan garis rambut yang memanjang ke kanan.
class _BandHeader extends StatelessWidget {
  const _BandHeader({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Text(
            AppStrings.recipesBandTitle(code),
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Container(height: 1, color: colors.outline)),
        ],
      ),
    );
  }
}
