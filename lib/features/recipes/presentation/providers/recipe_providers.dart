import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:cekgizi/features/recipes/domain/services/recipe_catalog.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepositoryImpl(),
);

/// Seluruh resep terkurasi dari asset lokal (offline-safe).
final recipesProvider = FutureProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).listRecipes(),
);

/// State filter katalog. [followChild] true = rentang usia mengikuti anak
/// terpilih; begitu pengguna memilih chip usia, pilihan itu yang dipakai.
final class RecipeFilter {
  const RecipeFilter({
    this.band,
    this.query = '',
    this.animalProteinOnly = false,
    this.followChild = true,
  });

  final RecipeAgeBand? band;
  final String query;
  final bool animalProteinOnly;
  final bool followChild;

  static const Object _unset = Object();

  RecipeFilter copyWith({
    Object? band = _unset,
    String? query,
    bool? animalProteinOnly,
    bool? followChild,
  }) {
    return RecipeFilter(
      band: identical(band, _unset) ? this.band : band as RecipeAgeBand?,
      query: query ?? this.query,
      animalProteinOnly: animalProteinOnly ?? this.animalProteinOnly,
      followChild: followChild ?? this.followChild,
    );
  }
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterNotifier, RecipeFilter>(
      RecipeFilterNotifier.new,
    );

class RecipeFilterNotifier extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  /// Pilih rentang usia eksplisit; null = "Semua usia".
  void selectBand(RecipeAgeBand? band) {
    state = state.copyWith(band: band, followChild: false);
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleAnimalProtein() =>
      state = state.copyWith(animalProteinOnly: !state.animalProteinOnly);

  void reset() => state = const RecipeFilter();
}

/// Rentang usia yang benar-benar dipakai katalog (anak terpilih atau pilihan
/// eksplisit pengguna). Null = semua usia / anak < 6 bulan.
final recipeEffectiveBandProvider = Provider<RecipeAgeBand?>((ref) {
  final filter = ref.watch(recipeFilterProvider);
  if (!filter.followChild) return filter.band;
  final child = ref.watch(selectedChildProvider).value;
  if (child == null) return null;
  final now = ref.watch(clockProvider)();
  return RecipeAgeBand.forAge(child.ageInCompletedMonths(now));
});

/// Katalog setelah filter + pencarian. Loading/error diteruskan dari
/// [recipesProvider] agar UI bisa menampilkan skeleton / kartu galat.
final filteredRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final recipes = await ref.watch(recipesProvider.future);
  final filter = ref.watch(recipeFilterProvider);
  final band = ref.watch(recipeEffectiveBandProvider);
  return RecipeCatalog.filter(
    recipes,
    band: band,
    query: filter.query,
    animalProteinOnly: filter.animalProteinOnly,
  );
});

/// Satu resep untuk layar detail; null bila id tidak dikenal.
final recipeByIdProvider = FutureProvider.family<Recipe?, String>((
  ref,
  id,
) async {
  final recipes = await ref.watch(recipesProvider.future);
  return recipes.where((recipe) => recipe.id == id).firstOrNull;
});
