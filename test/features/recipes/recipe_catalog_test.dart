import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/services/recipe_catalog.dart';

import '../../fakes.dart';

void main() {
  group('RecipeAgeBand', () {
    test('fromCode mengenal keempat rentang PRD', () {
      expect(RecipeAgeBand.fromCode('6-8'), RecipeAgeBand.months6to8);
      expect(RecipeAgeBand.fromCode('9-11'), RecipeAgeBand.months9to11);
      expect(RecipeAgeBand.fromCode('12-23'), RecipeAgeBand.months12to23);
      expect(RecipeAgeBand.fromCode('24+'), RecipeAgeBand.months24plus);
      expect(RecipeAgeBand.fromCode('0-6'), isNull);
    });

    test('forAge memetakan usia ke rentang yang tepat', () {
      expect(RecipeAgeBand.forAge(5), isNull);
      expect(RecipeAgeBand.forAge(6), RecipeAgeBand.months6to8);
      expect(RecipeAgeBand.forAge(8), RecipeAgeBand.months6to8);
      expect(RecipeAgeBand.forAge(9), RecipeAgeBand.months9to11);
      expect(RecipeAgeBand.forAge(11), RecipeAgeBand.months9to11);
      expect(RecipeAgeBand.forAge(12), RecipeAgeBand.months12to23);
      expect(RecipeAgeBand.forAge(23), RecipeAgeBand.months12to23);
      expect(RecipeAgeBand.forAge(24), RecipeAgeBand.months24plus);
      expect(RecipeAgeBand.forAge(59), RecipeAgeBand.months24plus);
    });
  });

  group('RecipeCatalog.filter', () {
    final recipes = [
      fakeRecipe(
        id: 'a',
        title: 'Bubur Hati Ayam',
        band: RecipeAgeBand.months6to8,
        groups: const ['grains_tubers', 'flesh'],
      ),
      fakeRecipe(
        id: 'b',
        title: 'Puree Tempe Labu',
        band: RecipeAgeBand.months6to8,
        groups: const ['grains_tubers', 'legumes_nuts'],
        animalProtein: false,
      ),
      fakeRecipe(
        id: 'c',
        title: 'Nasi Tim Sapi',
        band: RecipeAgeBand.months12to23,
        groups: const ['grains_tubers', 'flesh'],
      ),
    ];

    test('tanpa filter mengembalikan semua', () {
      expect(RecipeCatalog.filter(recipes), hasLength(3));
    });

    test('filter rentang usia', () {
      final result = RecipeCatalog.filter(
        recipes,
        band: RecipeAgeBand.months6to8,
      );
      expect(result.map((r) => r.id), orderedEquals(['a', 'b']));
    });

    test('filter protein hewani', () {
      final result = RecipeCatalog.filter(recipes, animalProteinOnly: true);
      expect(result.map((r) => r.id), orderedEquals(['a', 'c']));
    });

    test('pencarian cocokkan judul tanpa peka huruf besar', () {
      final result = RecipeCatalog.filter(recipes, query: 'BUBUR');
      expect(result.map((r) => r.id), ['a']);
    });

    test('pencarian cocokkan nama bahan', () {
      final result = RecipeCatalog.filter(recipes, query: 'beras');
      expect(result, hasLength(3));
    });

    test('pencarian tidak cocok menghasilkan kosong', () {
      expect(RecipeCatalog.filter(recipes, query: 'cokelat'), isEmpty);
    });

    test('kombinasi usia + protein + kata kunci', () {
      final result = RecipeCatalog.filter(
        recipes,
        band: RecipeAgeBand.months6to8,
        animalProteinOnly: true,
        query: 'hati',
      );
      expect(result.map((r) => r.id), ['a']);
    });
  });

  group('RecipeCatalog.sorted & forAge', () {
    test('urut rentang usia lalu judul', () {
      final recipes = [
        fakeRecipe(id: 'z', title: 'Zebra', band: RecipeAgeBand.months6to8),
        fakeRecipe(id: 'a', title: 'Apel', band: RecipeAgeBand.months6to8),
        fakeRecipe(id: 'm', title: 'Mangga', band: RecipeAgeBand.months24plus),
      ];
      final sorted = RecipeCatalog.sorted(recipes);
      expect(sorted.map((r) => r.id), orderedEquals(['a', 'z', 'm']));
    });

    test('forAge hanya rentang yang cocok dan sudah urut', () {
      final recipes = [
        fakeRecipe(id: 'x', title: 'B', band: RecipeAgeBand.months12to23),
        fakeRecipe(id: 'y', title: 'A', band: RecipeAgeBand.months12to23),
        fakeRecipe(id: 'z', title: 'C', band: RecipeAgeBand.months6to8),
      ];
      final result = RecipeCatalog.forAge(recipes, 15);
      expect(result.map((r) => r.id), orderedEquals(['y', 'x']));
    });

    test('forAge di bawah 6 bulan kosong (ASI eksklusif)', () {
      final recipes = [fakeRecipe()];
      expect(RecipeCatalog.forAge(recipes, 4), isEmpty);
    });
  });

  group('RecipeCatalog.featured', () {
    final recipes = [
      for (var i = 0; i < 5; i++)
        fakeRecipe(id: 'r$i', title: 'Resep $i', minutes: 20 + i),
    ];

    test('stabil sepanjang hari yang sama', () {
      final morning = RecipeCatalog.featured(
        recipes,
        DateTime(2026, 11, 23, 6, 30),
      );
      final night = RecipeCatalog.featured(
        recipes,
        DateTime(2026, 11, 23, 22, 45),
      );
      expect(morning, isNotNull);
      expect(night!.id, morning!.id);
    });

    test('berganti pada hari berikutnya', () {
      final today = RecipeCatalog.featured(recipes, DateTime(2026, 11, 23));
      final tomorrow = RecipeCatalog.featured(recipes, DateTime(2026, 11, 24));
      expect(tomorrow!.id, isNot(today!.id));
    });

    test('katalog kosong menghasilkan null', () {
      expect(RecipeCatalog.featured(const [], DateTime(2026, 1, 1)), isNull);
    });
  });
}
