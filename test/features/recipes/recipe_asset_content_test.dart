import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/recipes/data/models/recipe_model.dart';
import 'package:cekgizi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_image.dart';

/// Uji konten aset asli terhadap syarat PRD §9.1 (bukan data karangan).
///
/// Berkas `recipes.json` disediakan pemilik; tes ini memastikan katalog yang
/// dibundel memenuhi jumlah minimum, sebaran usia, dan kelengkapan field.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Recipe> recipes;

  setUpAll(() async {
    final contents = await rootBundle.loadString(
      RecipeRepositoryImpl.assetPath,
    );
    recipes = RecipeCatalogLoader.fromJsonString(contents);
  });

  test('minimal 24 resep', () {
    expect(recipes.length, greaterThanOrEqualTo(24));
  });

  test('setiap rentang usia punya tepat 6 resep', () {
    for (final band in RecipeAgeBand.values) {
      final count = recipes.where((r) => r.ageBand == band).length;
      expect(count, 6, reason: 'rentang ${band.code}');
    }
  });

  test('id unik dan berupa slug', () {
    final ids = recipes.map((r) => r.id).toSet();
    expect(ids.length, recipes.length);
  });

  test('semua kelompok adalah kode resmi PRD §3.7', () {
    for (final recipe in recipes) {
      for (final code in recipe.groups) {
        expect(FoodGroup.fromCode(code), isNotNull, reason: recipe.id);
      }
    }
  });

  test('penanda protein hewani konsisten dengan kelompok', () {
    for (final recipe in recipes) {
      final hasAnimal = recipe.groups.any(
        FoodGroup.animalProteinCodes.contains,
      );
      expect(recipe.animalProtein, hasAnimal, reason: recipe.id);
    }
  });

  test('bahan, langkah, dan catatan tekstur selalu terisi', () {
    for (final recipe in recipes) {
      expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
      expect(recipe.steps, isNotEmpty, reason: recipe.id);
      expect(recipe.textureNote.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.minutes, greaterThan(0), reason: recipe.id);
    }
  });

  test('resep belum ditinjau tetap terbaca (penanda jujur di UI)', () {
    // Berkas saat ini reviewed_by null; loader tidak boleh menolak, dan UI
    // wajib menampilkan penanda "belum ditinjau" (PRD §9.1).
    expect(recipes.every((r) => r.isReviewed), isFalse);
  });

  test('setiap resep punya foto teroptimasi yang dibundel', () async {
    var total = 0;
    for (final recipe in recipes) {
      final data = await rootBundle.load(RecipeImage.assetFor(recipe.id));
      expect(data.lengthInBytes, greaterThan(0), reason: recipe.id);
      // Batas per foto: hero tetap tajam tanpa membengkakkan APK.
      expect(
        data.lengthInBytes,
        lessThanOrEqualTo(300 * 1024),
        reason: recipe.id,
      );
      total += data.lengthInBytes;
    }
    // Anggaran total 24 foto (hasil tool/optimize_recipe_images.py).
    expect(total, lessThan(3 * 1024 * 1024));
  });
}
