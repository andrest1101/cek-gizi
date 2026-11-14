import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import 'fakes.dart';

Future<LocalPrefs> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalPrefs.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows onboarding, Lewati goes to consent', (
    tester,
  ) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(FakeChildRepository()),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith((ref) => Future.value(const FakeAnthropometryTables())),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith((ref) => Future.value(fakeNutritionRules())),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.consentTitle), findsOneWidget);
  });

  testWidgets('Beranda shows empty state when no children yet', (
    tester,
  ) async {
    final prefs =
        await _prefs({'onboarding_completed': true, 'consent_version_accepted': '1'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(FakeChildRepository([])),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith((ref) => Future.value(const FakeAnthropometryTables())),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith((ref) => Future.value(fakeNutritionRules())),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.childEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.childEmptyCta), findsOneWidget);
  });

  testWidgets('Beranda shows normal status card with a measurement', (
    tester,
  ) async {
    final child = fakeChild();
    final prefs =
        await _prefs({'onboarding_completed': true, 'consent_version_accepted': '1'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(
            FakeGrowthRepository([
              fakeMeasurement(id: 'm1', childId: child.id),
            ]),
          ),
          permenkesTablesProvider.overrideWith((ref) => Future.value(const FakeAnthropometryTables())),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith((ref) => Future.value(fakeNutritionRules())),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.statusNormalTitle), findsWidgets);
    expect(find.text(AppStrings.statusViewDetail), findsOneWidget);
    expect(find.text(AppStrings.statusAddFirst), findsWidgets);
  });
}
