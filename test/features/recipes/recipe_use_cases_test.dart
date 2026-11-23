import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/recipes/domain/use_cases/recipe_use_cases.dart';

import '../../fakes.dart';

void main() {
  final at = DateTime(2026, 11, 23, 12, 30);

  test('resep menjadi satu log source=recipe dengan union kelompok', () {
    final recipe = fakeRecipe(
      title: 'Bubur Hati Ayam',
      groups: const ['flesh', 'grains_tubers', 'vit_a_fruit_veg'],
    );
    final log = RecipeUseCases.toFoodLog(
      recipe: recipe,
      childId: 'child-1',
      mealType: MealType.lunch,
      at: at,
    );

    expect(log.source, FoodLogSource.recipe);
    expect(log.childId, 'child-1');
    expect(log.mealType, MealType.lunch);
    expect(log.eatenAt, at);
    expect(log.items, hasLength(1));
    expect(log.items.single.name, 'Bubur Hati Ayam');
    // Kelompok diurutkan canonical PRD, bukan urutan input.
    expect(log.groups, ['grains_tubers', 'flesh', 'vit_a_fruit_veg']);
    expect(log.items.single.groups, log.groups);
  });

  test('menolak childId kosong', () {
    expect(
      () => RecipeUseCases.toFoodLog(
        recipe: fakeRecipe(),
        childId: '  ',
        mealType: MealType.snack,
        at: at,
      ),
      throwsStateError,
    );
  });

  test('menolak resep tanpa kelompok yang dikenal', () {
    expect(
      () => RecipeUseCases.toFoodLog(
        recipe: fakeRecipe(groups: const []),
        childId: 'child-1',
        mealType: MealType.snack,
        at: at,
      ),
      throwsStateError,
    );
  });

  test('kelompok tak dikenal diabaikan, bukan disimpan mentah', () {
    final recipe = fakeRecipe(
      groups: const ['flesh', 'kode_asing'],
      animalProtein: true,
    );
    final log = RecipeUseCases.toFoodLog(
      recipe: recipe,
      childId: 'child-1',
      mealType: MealType.dinner,
      at: at,
    );
    expect(log.groups, ['flesh']);
  });
}
