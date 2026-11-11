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

import '../fakes.dart';

/// PRD §7.7: tidak boleh overflow di 360dp pada text scale 1,3,
/// baik light maupun dark theme.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const brightnesses = [Brightness.light, Brightness.dark];

  Future<LocalPrefs> prefsFor(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalPrefs.load();
  }

  void useSmallScreen(WidgetTester tester, Brightness brightness) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Future<void> pumpApp(WidgetTester tester, LocalPrefs prefs) async {
    final child = fakeChild();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider
              .overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(
            FakeGrowthRepository([
              fakeMeasurement(id: 'm1', childId: child.id),
            ]),
          ),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in brightnesses) {
    testWidgets(
      'Beranda & Tumbuh muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        await pumpApp(
          tester,
          await prefsFor({
            'onboarding_completed': true,
            'consent_version_accepted': '1',
          }),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(AppStrings.navGrowth));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Gulir sampai kartu riwayat terlihat (konten tinggi di 360dp @1,3).
        final historyTile = find.text('8,2 kg · 72,0 cm');
        await tester.scrollUntilVisible(
          historyTile,
          240,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(historyTile, findsOneWidget);
      },
    );

    testWidgets(
      'Onboarding muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        await pumpApp(tester, await prefsFor({}));
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.disclaimer), findsWidgets);

        for (var page = 0; page < 2; page++) {
          await tester.tap(find.text(AppStrings.onboardingNext));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text(AppStrings.onboardingStart), findsOneWidget);
        expect(find.text(AppStrings.disclaimer), findsWidgets);
      },
    );

    testWidgets(
      'Consent muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        await pumpApp(
          tester,
          await prefsFor({'onboarding_completed': true}),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.consentTitle), findsOneWidget);

        // Gulir ke bawah: checkbox + tombol setuju tetap rapi.
        await tester.scrollUntilVisible(
          find.text(AppStrings.consentSubmit),
          240,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.consentSubmit), findsOneWidget);
      },
    );

    testWidgets(
      'Kelola anak & formulir anak muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        await pumpApp(
          tester,
          await prefsFor({
            'onboarding_completed': true,
            'consent_version_accepted': '1',
          }),
        );

        await tester.tap(find.byTooltip(AppStrings.homeManageChild));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.childListTitle), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.childNicknameLabel), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text(AppStrings.childSexLabel),
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.childSave), findsOneWidget);
      },
    );
  }
}
