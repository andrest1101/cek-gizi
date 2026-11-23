import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';

import '../../fakes.dart';

/// Alur katalog resep (PRD §6.6): filter usia, pencarian, detail, dan
/// "Catat sebagai makan" yang masuk ke Piring Hari Ini.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 23, 12, 0);
  // Anak 12 bulan → rentang 12–23 bulan.
  final child = fakeChild(birthDate: DateTime(2025, 11, 20));

  List<Recipe> seed() => [
    fakeRecipe(
      id: 'nasi-tim-sapi',
      title: 'Nasi Tim Sapi',
      band: RecipeAgeBand.months12to23,
    ),
    fakeRecipe(
      id: 'bubur-ayam',
      title: 'Bubur Ayam Sayur',
      band: RecipeAgeBand.months12to23,
    ),
    fakeRecipe(
      id: 'puree-tempe',
      title: 'Puree Tempe Labu',
      band: RecipeAgeBand.months12to23,
      groups: const ['grains_tubers', 'legumes_nuts'],
      animalProtein: false,
    ),
    fakeRecipe(
      id: 'puree-hati',
      title: 'Puree Hati Ayam',
      band: RecipeAgeBand.months6to8,
    ),
    fakeRecipe(
      id: 'nasi-goreng',
      title: 'Nasi Goreng Telur',
      band: RecipeAgeBand.months24plus,
      groups: const ['grains_tubers', 'eggs'],
    ),
  ];

  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeRecipeRepository recipeRepo,
    required FakeFoodLogRepository foodRepo,
    List<ChildProfile>? children,
  }) async {
    // Viewport tall agar seluruh kartu & detail ter-build tanpa perlu gulir
    // (uji alur, bukan uji layout - layout diuji terpisah di 360dp @1,3).
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(const {
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    final prefs = await LocalPrefs.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository(children ?? [child]),
          ),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(foodRepo),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          recipeRepositoryProvider.overrideWithValue(recipeRepo),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.navRecipe));
    await tester.pumpAndSettle();
  }

  testWidgets('katalog mengikuti usia anak dan menampilkan penanda tinjauan', (
    tester,
  ) async {
    final recipeRepo = FakeRecipeRepository(seed());
    await pumpApp(
      tester,
      recipeRepo: recipeRepo,
      foodRepo: FakeFoodLogRepository(),
    );

    // Default: hanya rentang 12–23 (3 resep), bukan seluruh katalog.
    expect(find.text('Nasi Tim Sapi'), findsOneWidget);
    expect(find.text('Bubur Ayam Sayur'), findsOneWidget);
    expect(find.text('Puree Tempe Labu'), findsOneWidget);
    expect(find.text('Puree Hati Ayam'), findsNothing);
    expect(find.text('Nasi Goreng Telur'), findsNothing);
    expect(find.text(AppStrings.recipesResultCount(3)), findsOneWidget);
    // Konten belum ditinjau → penanda jujur tampil.
    expect(find.text(AppStrings.recipesReviewPendingNote), findsOneWidget);
  });

  testWidgets('chip Semua usia menampilkan seluruh katalog', (tester) async {
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: FakeFoodLogRepository(),
    );

    await tester.tap(find.text(AppStrings.recipesFilterAll));
    await tester.pumpAndSettle();

    expect(find.text('Puree Hati Ayam'), findsOneWidget);
    expect(find.text('Nasi Goreng Telur'), findsOneWidget);
    expect(find.text(AppStrings.recipesResultCount(5)), findsOneWidget);
  });

  testWidgets('pencarian menyaring judul lalu bisa diatur ulang', (
    tester,
  ) async {
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: FakeFoodLogRepository(),
    );

    await tester.enterText(find.byType(TextField), 'tempe');
    await tester.pumpAndSettle();
    expect(find.text('Puree Tempe Labu'), findsOneWidget);
    expect(find.text('Nasi Tim Sapi'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tidakada');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.recipesEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.recipesEmptyReset));
    await tester.pumpAndSettle();
    expect(find.text('Nasi Tim Sapi'), findsOneWidget);
  });

  testWidgets('saring protein hewani menyembunyikan resep nabati', (
    tester,
  ) async {
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: FakeFoodLogRepository(),
    );

    await tester.tap(find.byKey(const Key('recipe-protein-filter')));
    await tester.pumpAndSettle();

    expect(find.text('Puree Tempe Labu'), findsNothing);
    expect(find.text('Nasi Tim Sapi'), findsOneWidget);
    expect(find.text(AppStrings.recipesResultCount(2)), findsOneWidget);
  });

  testWidgets('detail resep menampilkan bahan, langkah, dan keamanan', (
    tester,
  ) async {
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: FakeFoodLogRepository(),
    );

    await tester.tap(find.text('Nasi Tim Sapi'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recipesDetailTitle), findsOneWidget);
    expect(find.text(AppStrings.recipesIngredientsTitle), findsOneWidget);
    expect(find.text(AppStrings.recipesStepsTitle), findsOneWidget);
    expect(find.text(AppStrings.recipesSafetyTitle), findsOneWidget);
    expect(find.text(AppStrings.recipesTextureLabel), findsOneWidget);
    expect(find.text(AppStrings.recipesLogCta), findsOneWidget);
    // Belum ditinjau → penanda ringkas di detail.
    expect(find.text(AppStrings.recipesReviewPendingShort), findsOneWidget);
  });

  testWidgets('catat sebagai makan menyimpan log recipe dan bisa diurungkan', (
    tester,
  ) async {
    final foodRepo = FakeFoodLogRepository();
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: foodRepo,
    );

    await tester.tap(find.text('Nasi Tim Sapi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipe-detail-log')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recipe-log-save')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.recipesLogSaved), findsOneWidget);
    final logs = foodRepo.logs(child.id);
    expect(logs, hasLength(1));
    expect(logs.single.source, FoodLogSource.recipe);
    expect(logs.single.items.single.name, 'Nasi Tim Sapi');

    // Urungkan menghapus catatan.
    await tester.tap(find.text(AppStrings.makanUndoAction));
    await tester.pumpAndSettle();
    expect(foodRepo.logs(child.id), isEmpty);
  });

  testWidgets('galat memuat katalog menampilkan kartu coba lagi', (
    tester,
  ) async {
    final recipeRepo = FakeRecipeRepository()
      ..loadError = StateError('asset korup (test)');
    await pumpApp(
      tester,
      recipeRepo: recipeRepo,
      foodRepo: FakeFoodLogRepository(),
    );

    expect(find.text(AppStrings.recipesLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);

    // Pulihkan lalu coba lagi → katalog tampil.
    recipeRepo
      ..loadError = null
      ..addRecipes(seed());
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Nasi Tim Sapi'), findsOneWidget);
  });

  testWidgets(
    'tanpa anak: ajakan tambah profil, katalog tetap bisa dijelajahi',
    (tester) async {
      await pumpApp(
        tester,
        recipeRepo: FakeRecipeRepository(seed()),
        foodRepo: FakeFoodLogRepository(),
        children: const [],
      );

      expect(find.text(AppStrings.recipesNoChildTitle), findsOneWidget);
      // Tanpa anak, semua usia tampil (tidak ada filter usia otomatis).
      expect(find.text('Nasi Tim Sapi'), findsOneWidget);
      expect(find.text('Puree Hati Ayam'), findsOneWidget);
    },
  );

  testWidgets('anak di bawah 6 bulan mendapat catatan ASI eksklusif', (
    tester,
  ) async {
    final infant = fakeChild(birthDate: DateTime(2026, 7, 20));
    await pumpApp(
      tester,
      recipeRepo: FakeRecipeRepository(seed()),
      foodRepo: FakeFoodLogRepository(),
      children: [infant],
    );

    expect(find.text(AppStrings.asiExclusiveTitle), findsOneWidget);
  });
}
