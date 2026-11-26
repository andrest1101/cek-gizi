import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

/// UX-24: pilihan tema murni lokal, default terang, dan catatan privasi
/// tentang akun anonim.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalPrefs> prefsFor(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalPrefs.load();
  }

  Future<void> pumpApp(WidgetTester tester, LocalPrefs prefs) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository([fakeChild()]),
          ),
          growthRepositoryProvider.overrideWithValue(
            FakeGrowthRepository(const []),
          ),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(
            FakeFoodLogRepository(const []),
          ),
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

  Future<void> openAppearance(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(SegmentedButton<ThemeMode>),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('account-list')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
  }

  ThemeMode currentTheme(WidgetTester tester) => tester
      .widgetList<MaterialApp>(find.byType(MaterialApp))
      .first
      .themeMode!;

  testWidgets('Default tema = terang', (tester) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    await pumpApp(tester, prefs);

    expect(tester.takeException(), isNull);
    expect(currentTheme(tester), ThemeMode.light);
    expect(prefs.themeMode, LocalPrefs.themeModeLight);
  });

  testWidgets('Memilih Gelap mengubah tema & tersimpan di LocalPrefs', (
    tester,
  ) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    await pumpApp(tester, prefs);
    await openAppearance(tester);

    expect(find.text(AppStrings.accountThemeLight), findsOneWidget);
    await tester.tap(find.text(AppStrings.accountThemeDark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(currentTheme(tester), ThemeMode.dark);
    final reloaded = await LocalPrefs.load();
    expect(reloaded.themeMode, LocalPrefs.themeModeDark);
  });

  testWidgets('Sistem & Terang bisa dipilih ulang', (tester) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
      'theme_mode': 'dark',
    });
    await pumpApp(tester, prefs);
    expect(currentTheme(tester), ThemeMode.dark);
    await openAppearance(tester);

    await tester.tap(find.text(AppStrings.accountThemeSystem));
    await tester.pumpAndSettle();
    expect(currentTheme(tester), ThemeMode.system);

    await tester.tap(find.text(AppStrings.accountThemeLight));
    await tester.pumpAndSettle();
    expect(currentTheme(tester), ThemeMode.light);
    expect((await LocalPrefs.load()).themeMode, LocalPrefs.themeModeLight);
  });

  testWidgets('Nilai tema tak dikenal jatuh ke terang', (tester) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
      'theme_mode': 'bukan-tema',
    });
    await pumpApp(tester, prefs);
    expect(currentTheme(tester), ThemeMode.light);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Tampilan muat di 360dp @1,3 (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      final prefs = await prefsFor({
        'onboarding_completed': true,
        'consent_version_accepted': '2',
        'theme_mode': brightness == Brightness.light
            ? LocalPrefs.themeModeLight
            : LocalPrefs.themeModeDark,
      });
      await pumpApp(tester, prefs);
      await openAppearance(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(find.text(AppStrings.accountThemeLight), findsOneWidget);
      expect(find.text(AppStrings.accountThemeSystem), findsOneWidget);
    });
  }

  testWidgets('Catatan akun anonim tampil di kartu privasi', (tester) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    await pumpApp(tester, prefs);
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppStrings.accountPrivacyAnonymousNote),
      260,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('account-list')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.accountPrivacyAnonymousNote), findsOneWidget);
  });
}
