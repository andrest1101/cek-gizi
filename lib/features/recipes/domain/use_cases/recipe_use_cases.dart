import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';

/// Use case resep (PRD §6.6): "Catat sebagai makan".
///
/// Resep menjadi SATU catatan `source = recipe` dengan satu item bernama
/// judul resep dan `groups` union canonical - sama seperti pola scan/manual,
/// sehingga Piring Hari Ini menghitung seluruh kelompok resep tanpa mengubah
/// skema `food_logs`.
abstract final class RecipeUseCases {
  const RecipeUseCases._();

  static FoodLog toFoodLog({
    required Recipe recipe,
    required String childId,
    required MealType mealType,
    required DateTime at,
  }) {
    if (childId.trim().isEmpty) {
      throw StateError('Tidak ada anak yang dipilih.');
    }
    final canonical = PiringDayEvaluator.canonicalOrder(recipe.groups);
    if (canonical.isEmpty) {
      throw StateError('Resep tidak memiliki kelompok pangan yang dikenal.');
    }
    return FoodLog(
      id: '',
      childId: childId,
      eatenAt: at,
      mealType: mealType,
      source: FoodLogSource.recipe,
      items: [FoodLogItem(name: recipe.title, groups: canonical)],
      groups: canonical,
    );
  }
}
