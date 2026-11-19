import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_tips_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/week_strip.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';

import '../fakes.dart';

/// UX-4: Beranda 3 blok & riwayat Tumbuh berbentuk accordion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalPrefs> prefs() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    return LocalPrefs.load();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required ChildProfile child,
    List<GrowthMeasurement> measurements = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(await prefs()),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository([child]),
          ),
          growthRepositoryProvider.overrideWithValue(
            FakeGrowthRepository(measurements),
          ),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Beranda: hero, strip pil horizontal, tips di dalam kartu tumbuh',
    (tester) async {
      await pumpApp(tester, child: fakeChild());

      expect(find.text(AppStrings.piringTitle.toUpperCase()), findsOneWidget);
      expect(find.byType(HomeWeekChips), findsOneWidget);
      // Identitas pindah ke header, bukan kartu berdiri sendiri.
      expect(find.byType(ChildSwitcherCard), findsNothing);
      // Tips tetap tampil, tetapi sebagai baris di dalam blok tumbuh.
      expect(find.byType(PiringTipsCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tumbuh: detail pengukuran terbuka saat baris diketuk', (
    tester,
  ) async {
    final child = fakeChild();
    await pumpApp(
      tester,
      child: child,
      measurements: [fakeMeasurement(id: 'm1', childId: child.id)],
    );

    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();

    final growthList = find.byKey(const Key('growth-list'));
    final growthScroll = find.descendant(
      of: growthList,
      matching: find.byType(Scrollable),
    );
    final row = find.text('8,2 kg · 72,0 cm');
    await tester.scrollUntilVisible(row, 200, scrollable: growthScroll);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.actionEdit), findsNothing);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.actionEdit), findsOneWidget);
    expect(find.text(AppStrings.actionDelete), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
