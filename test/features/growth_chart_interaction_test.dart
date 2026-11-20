import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

/// Grafik harus menjelaskan sumbu X/Y dan memberi tahu cara melihat detail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('grafik Tumbuh menampilkan judul sumbu & hint ketuk', (
    tester,
  ) async {
    final child = fakeChild();
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    final prefs = await LocalPrefs.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository([child]),
          ),
          growthRepositoryProvider.overrideWithValue(
            FakeGrowthRepository([
              fakeMeasurement(id: 'm1', childId: child.id),
            ]),
          ),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text(AppStrings.growthChartTitle), findsOneWidget);
    expect(find.text(AppStrings.growthAxisXAge), findsOneWidget);
    expect(find.text(AppStrings.growthAxisYHeight), findsOneWidget);
    expect(find.text(AppStrings.growthChartTapHint), findsOneWidget);
  });
}
