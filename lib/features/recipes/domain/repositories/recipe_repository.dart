import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';

/// Kontrak repository katalog resep (PRD §6.6).
///
/// Resep adalah konten lokal offline-first: tidak ada jaringan, tidak ada
/// server. Implementasi konkret membaca asset JSON di data layer.
abstract interface class RecipeRepository {
  /// Seluruh resep terkurasi, urut stabil (rentang usia lalu judul).
  Future<List<Recipe>> listRecipes();
}
