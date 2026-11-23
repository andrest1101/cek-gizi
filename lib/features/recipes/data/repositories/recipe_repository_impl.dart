import 'package:flutter/services.dart';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/recipes/data/models/recipe_model.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/repositories/recipe_repository.dart';

/// Katalog resep dari asset lokal (offline-first, PRD §6.6).
///
/// Tidak ada jaringan: resep dibaca sekali dari `assets/recipes/recipes.json`
/// lalu di-cache selama sesi. Berkas korup ditolak oleh [RecipeCatalogLoader].
final class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/recipes/recipes.json';

  final AssetBundle _bundle;
  List<Recipe>? _cache;

  @override
  Future<List<Recipe>> listRecipes() async {
    final cached = _cache;
    if (cached != null) return cached;

    final String contents;
    try {
      contents = await _bundle.loadString(assetPath);
    } catch (_) {
      throw const InvalidReferenceDataException(
        'recipes.json: berkas resep tidak dapat dibaca.',
      );
    }
    final recipes = RecipeCatalogLoader.fromJsonString(contents);
    _cache = recipes;
    return recipes;
  }
}
