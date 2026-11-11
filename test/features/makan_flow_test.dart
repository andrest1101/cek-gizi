import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/router.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 240,
}) {
  return tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 60,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'catat manual → ring Beranda naik → target tercapai → hapus → turun',
    (tester) async {
      final child = fakeChild();
      SharedPreferences.setMockInitialValues(
        {'onboarding_completed': true, 'consent_version_accepted': '1'},
      );
      final prefs = await LocalPrefs.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(prefs),
            childRepositoryProvider
                .overrideWithValue(FakeChildRepository([child])),
            growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
            permenkesTablesProvider.overrideWith(
              (ref) => Future.value(const FakeAnthropometryTables()),
            ),
            foodLogRepositoryProvider
                .overrideWithValue(FakeFoodLogRepository()),
            nutritionRulesProvider.overrideWith(
              (ref) => Future.value(fakeNutritionRules()),
            ),
          ],
          child: const CekGiziApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Beranda: hero menampilkan kondisi kosong.
      expect(find.text(AppStrings.piringEmpty), findsOneWidget);

      // Pindah ke Makan lewat bottom nav.
      await tester.tap(find.text(AppStrings.navMakan));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.makanTitle), findsWidgets);

      // Diary kosong dulu (konten di bawah lipatan → scroll dulu).
      await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
      expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);

      // Catat "Makanan pokok" → sheet → Sarapan → simpan.
      await _scrollTo(tester, find.text(AppStrings.groupGrainsTubers));
      await tester.tap(find.text(AppStrings.groupGrainsTubers));
      await tester.pumpAndSettle();
      expect(find.text('Catat ${AppStrings.groupGrainsTubers}'), findsOneWidget);
      await tester.tap(find.text(AppStrings.mealBreakfast));
      await tester.pumpAndSettle();
      final saveButton = find.text(AppStrings.makanSaveLog);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Entry muncul di diary (di bawah lipatan → scroll dulu).
      await _scrollTo(
        tester,
        find.textContaining(AppStrings.groupGrainsTubers).last,
      );
      expect(
        find.textContaining(AppStrings.groupGrainsTubers),
        findsWidgets,
      );

      // Catat 4 kelompok lain agar target 5/8 tercapai.
      for (final group in [
        AppStrings.groupLegumesNuts,
        AppStrings.groupDairy,
        AppStrings.groupEggs,
        AppStrings.groupOtherFruitVeg,
      ]) {
        await _scrollTo(tester, find.text(group));
        await tester.tap(find.text(group));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.mealSnack));
        await tester.pumpAndSettle();
        final save = find.text(AppStrings.makanSaveLog);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
      }

      // Beranda menampilkan status tercapai.
      await tester.tap(find.text(AppStrings.navHome));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text(AppStrings.piringTargetReached));
      expect(find.text(AppStrings.piringTargetReached), findsOneWidget);
      expect(find.text('5/8'), findsOneWidget);

      // Tips disembunyikan saat target tercapai.
      expect(find.text(AppStrings.tipTitle), findsNothing);
    },
  );

  testWidgets('toggle ASI menambah & menghapus catatan ASI', (tester) async {
    final child = fakeChild();
    SharedPreferences.setMockInitialValues(
      {'onboarding_completed': true, 'consent_version_accepted': '1'},
    );
    final prefs = await LocalPrefs.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider
              .overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider
              .overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Nyalakan ASI hari ini.
    final asiSwitch = find.byType(SwitchListTile);
    expect(asiSwitch, findsOneWidget);
    await tester.tap(asiSwitch);
    await tester.pumpAndSettle();
    // Entry ASI muncul di diary (di bawah lipatan → scroll dulu).
    await _scrollTo(tester, find.text('ASI').last);
    expect(find.text('ASI'), findsWidgets);

    // Matikan lagi (scroll kembali ke atas agar switch terlihat & bisa ditap).
    await _scrollTo(tester, asiSwitch, delta: -240);
    await tester.tap(asiSwitch);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
    expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);
  });

  testWidgets('bayi <6 bulan: grid disembunyikan, kartu ASI eksklusif tampil', (
    tester,
  ) async {
    final child = fakeChild(
      birthDate: DateTime.now().subtract(const Duration(days: 90)),
    );
    SharedPreferences.setMockInitialValues(
      {'onboarding_completed': true, 'consent_version_accepted': '1'},
    );
    final prefs = await LocalPrefs.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider
              .overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider
              .overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Beranda: kartu ASI eksklusif menggantikan ring.
    expect(find.text(AppStrings.asiExclusiveTitle), findsWidgets);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Grid kelompok pangan TIDAK tampil; kartu ASI eksklusif tampil.
    expect(find.text(AppStrings.makanGridTitle), findsNothing);
    expect(find.text(AppStrings.asiExclusiveTitle), findsOneWidget);
    // Toggle ASI tetap bisa dipakai.
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('tips hari ini tampil saat kelompok belum tercapai', (tester) async {
    final child = fakeChild();
    SharedPreferences.setMockInitialValues(
      {'onboarding_completed': true, 'consent_version_accepted': '1'},
    );
    final prefs = await LocalPrefs.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider
              .overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(
            FakeFoodLogRepository([
              fakeFoodLog(
                id: 'log-1',
                childId: child.id,
                eatenAt: DateTime.now(),
                groups: const ['grains_tubers'],
              ),
            ]),
          ),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tips tampil (satu tips dari aturan palsu).
    expect(find.text(AppStrings.tipTitle), findsOneWidget);
  });
}
