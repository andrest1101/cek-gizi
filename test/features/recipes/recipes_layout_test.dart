import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/presentation/providers/recipe_providers.dart';

import '../../fakes.dart';

/// PRD §7.7: katalog & detail resep tidak overflow di 360dp pada text scale
/// 1,3, baik light maupun dark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 23, 12, 0);
  final child = fakeChild(birthDate: DateTime(2025, 11, 20));

  List<Recipe> seed() => [
    fakeRecipe(
      id: 'resep-panjang-1',
      title: 'Bubur Saring Hati Ayam dengan Wortel dan Bayam',
      band: RecipeAgeBand.months12to23,
      minutes: 35,
      groups: const [
        'grains_tubers',
        'flesh',
        'eggs',
        'vit_a_fruit_veg',
        'other_fruit_veg',
      ],
    ),
    fakeRecipe(
      id: 'resep-panjang-2',
      title: 'Nasi Tim Daging Sapi Cincang dengan Buncis dan Wortel',
      band: RecipeAgeBand.months12to23,
      minutes: 45,
      groups: const ['grains_tubers', 'flesh', 'vit_a_fruit_veg'],
    ),
    fakeRecipe(
      id: 'resep-panjang-3',
      title: 'Puree Tempe Labu Kuning dan Beras Merah',
      band: RecipeAgeBand.months12to23,
      minutes: 30,
      groups: const ['grains_tubers', 'legumes_nuts', 'vit_a_fruit_veg'],
      animalProtein: false,
    ),
  ];

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'katalog & detail resep muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

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
                FakeChildRepository([child]),
              ),
              growthRepositoryProvider.overrideWithValue(
                FakeGrowthRepository(),
              ),
              permenkesTablesProvider.overrideWith(
                (ref) => Future.value(const FakeAnthropometryTables()),
              ),
              foodLogRepositoryProvider.overrideWithValue(
                FakeFoodLogRepository(),
              ),
              nutritionRulesProvider.overrideWith(
                (ref) => Future.value(fakeNutritionRules()),
              ),
              chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
              recipeRepositoryProvider.overrideWithValue(
                FakeRecipeRepository(seed()),
              ),
            ],
            child: const CekGiziApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.navRecipe));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.recipesSubtitle), findsOneWidget);

        // Gulir katalog sampai kartu terakhir terlihat; tidak boleh overflow.
        final catalogScroll = find.descendant(
          of: find.byKey(const Key('recipes-list')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Puree Tempe Labu Kuning dan Beras Merah'),
          150,
          scrollable: catalogScroll.first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Buka detail kartu terakhir dan gulir sampai disclaimer.
        await tester.tap(find.text('Puree Tempe Labu Kuning dan Beras Merah'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.recipesDetailTitle), findsOneWidget);

        final detailScroll = find.descendant(
          of: find.byKey(const Key('recipe-detail-list')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text(AppStrings.recipesDisclaimer),
          150,
          scrollable: detailScroll.first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.recipesDisclaimer), findsOneWidget);
        expect(find.byKey(const Key('recipe-detail-log')), findsOneWidget);
      },
    );
  }
}
