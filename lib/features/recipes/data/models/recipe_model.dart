import 'dart:convert';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/services/recipe_catalog.dart';

/// Parser & validasi ketat `assets/recipes/recipes.json` (PRD §9.1).
///
/// Berkas resep adalah konten terkurasi milik pemilik proyek. Loader ini
/// TIDAK memperbaiki, menebak, atau mengisi data yang hilang: berkas korup
/// ditolak dengan [InvalidReferenceDataException] agar UI menampilkan galat
/// yang jujur, bukan resep separuh jadi.
abstract final class RecipeCatalogLoader {
  const RecipeCatalogLoader._();

  static const int maxTitleLength = 120;
  static const int maxIngredientNameLength = 200;
  static const int maxIngredientAmountLength = 80;
  static const int maxStepLength = 600;
  static const int maxNoteLength = 400;
  static const int maxMinutes = 240;

  /// id resep berupa slug stabil (dipakai route detail & kunci tes).
  static final RegExp _idPattern = RegExp(r'^[a-z0-9]+(?:[-_][a-z0-9]+)*$');

  static List<Recipe> fromJsonString(String contents) {
    final decoded = jsonDecode(contents);
    if (decoded is! List) {
      throw const InvalidReferenceDataException(
        'recipes.json: akar dokumen harus berupa array JSON.',
      );
    }
    return fromJsonList(decoded);
  }

  static List<Recipe> fromJsonList(List<dynamic> items) {
    if (items.isEmpty) {
      throw const InvalidReferenceDataException(
        'recipes.json: katalog tidak boleh kosong.',
      );
    }
    final seen = <String>{};
    final recipes = <Recipe>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw const InvalidReferenceDataException(
          'recipes.json: setiap resep harus berupa objek JSON.',
        );
      }
      final recipe = _parseRecipe(item);
      if (!seen.add(recipe.id)) {
        throw InvalidReferenceDataException(
          'recipes.json: id resep duplikat: ${recipe.id}',
        );
      }
      recipes.add(recipe);
    }
    return RecipeCatalog.sorted(recipes);
  }

  static Recipe _parseRecipe(Map<String, dynamic> json) {
    final id = _string(json, 'id', maxLength: 80);
    if (!_idPattern.hasMatch(id)) {
      throw InvalidReferenceDataException(
        'recipes.json: id resep tidak valid: $id',
      );
    }
    final title = _string(json, 'title', maxLength: maxTitleLength);

    final bandCode = _string(json, 'age_band', maxLength: 16);
    final band = RecipeAgeBand.fromCode(bandCode);
    if (band == null) {
      throw InvalidReferenceDataException(
        'recipes.json: age_band tidak dikenal untuk "$id": $bandCode',
      );
    }

    final minutes = json['minutes'];
    if (minutes is! int || minutes <= 0 || minutes > maxMinutes) {
      throw InvalidReferenceDataException(
        'recipes.json: "minutes" harus bilangan bulat 1–$maxMinutes untuk "$id".',
      );
    }

    final ingredients = _parseIngredients(json['ingredients'], id);
    final steps = _parseSteps(json['steps'], id);
    final groups = _parseGroups(json['groups'], id);

    final animalProtein = json['animal_protein'];
    if (animalProtein is! bool) {
      throw InvalidReferenceDataException(
        'recipes.json: "animal_protein" harus boolean untuk "$id".',
      );
    }
    final hasAnimalGroup = groups.any(FoodGroup.animalProteinCodes.contains);
    if (animalProtein != hasAnimalGroup) {
      throw InvalidReferenceDataException(
        'recipes.json: penanda protein hewani tidak cocok dengan kelompok '
        'pangan untuk "$id".',
      );
    }

    final textureNote = _string(json, 'texture_note', maxLength: maxNoteLength);
    final allergenNote = _string(
      json,
      'allergen_note',
      maxLength: maxNoteLength,
      allowEmpty: true,
    );

    return Recipe(
      id: id,
      title: title,
      ageBand: band,
      minutes: minutes,
      ingredients: ingredients,
      steps: steps,
      groups: groups,
      animalProtein: animalProtein,
      textureNote: textureNote,
      allergenNote: allergenNote,
      reviewedBy: _nullableString(json, 'reviewed_by', maxLength: 120),
      reviewedOn: _nullableString(json, 'reviewed_on', maxLength: 40),
    );
  }

  static List<RecipeIngredient> _parseIngredients(Object? raw, String id) {
    if (raw is! List || raw.isEmpty) {
      throw InvalidReferenceDataException(
        'recipes.json: "ingredients" wajib ada dan tidak kosong untuk "$id".',
      );
    }
    final result = <RecipeIngredient>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        throw InvalidReferenceDataException(
          'recipes.json: bahan harus berupa objek untuk "$id".',
        );
      }
      result.add(
        RecipeIngredient(
          name: _string(item, 'name', maxLength: maxIngredientNameLength),
          amount: _string(item, 'amount', maxLength: maxIngredientAmountLength),
        ),
      );
    }
    return result;
  }

  static List<String> _parseSteps(Object? raw, String id) {
    if (raw is! List || raw.isEmpty) {
      throw InvalidReferenceDataException(
        'recipes.json: "steps" wajib ada dan tidak kosong untuk "$id".',
      );
    }
    final result = <String>[];
    for (final item in raw) {
      if (item is! String || item.trim().isEmpty) {
        throw InvalidReferenceDataException(
          'recipes.json: langkah kosong untuk "$id".',
        );
      }
      if (item.length > maxStepLength) {
        throw InvalidReferenceDataException(
          'recipes.json: langkah terlalu panjang untuk "$id".',
        );
      }
      result.add(item.trim());
    }
    return result;
  }

  static List<String> _parseGroups(Object? raw, String id) {
    if (raw is! List || raw.isEmpty) {
      throw InvalidReferenceDataException(
        'recipes.json: "groups" wajib ada dan tidak kosong untuk "$id".',
      );
    }
    final codes = <String>{};
    for (final item in raw) {
      if (item is! String || FoodGroup.fromCode(item) == null) {
        throw InvalidReferenceDataException(
          'recipes.json: kode kelompok tidak dikenal untuk "$id": $item',
        );
      }
      if (!codes.add(item)) {
        throw InvalidReferenceDataException(
          'recipes.json: kelompok duplikat untuk "$id": $item',
        );
      }
    }
    return PiringDayEvaluator.canonicalOrder(codes);
  }

  static String _string(
    Map<String, dynamic> json,
    String key, {
    required int maxLength,
    bool allowEmpty = false,
  }) {
    final value = json[key];
    if (value is! String) {
      throw InvalidReferenceDataException(
        'recipes.json: "$key" wajib ada (string).',
      );
    }
    final trimmed = value.trim();
    if (!allowEmpty && trimmed.isEmpty) {
      throw InvalidReferenceDataException(
        'recipes.json: "$key" tidak boleh kosong.',
      );
    }
    if (trimmed.length > maxLength) {
      throw InvalidReferenceDataException(
        'recipes.json: "$key" terlalu panjang (maks $maxLength karakter).',
      );
    }
    return trimmed;
  }

  static String? _nullableString(
    Map<String, dynamic> json,
    String key, {
    required int maxLength,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw InvalidReferenceDataException(
        'recipes.json: "$key" harus string atau null.',
      );
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxLength) {
      throw InvalidReferenceDataException(
        'recipes.json: "$key" terlalu panjang (maks $maxLength karakter).',
      );
    }
    return trimmed;
  }
}
