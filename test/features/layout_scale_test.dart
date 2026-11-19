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
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

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

  Future<void> pumpApp(
    WidgetTester tester,
    LocalPrefs prefs, {
    List<FoodLog> logs = const [],
  }) async {
    final child = fakeChild();
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
          foodLogRepositoryProvider.overrideWithValue(
            FakeFoodLogRepository(logs),
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

  for (final brightness in brightnesses) {
    testWidgets('Beranda & Tumbuh muat di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      await pumpApp(
        tester,
        await prefsFor({
          'onboarding_completed': true,
          'consent_version_accepted': '2',
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
    });

    testWidgets('Tanya muat di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      await pumpApp(
        tester,
        await prefsFor({
          'onboarding_completed': true,
          'consent_version_accepted': '2',
        }),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(AppStrings.tanyaBubbleLabel));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Ide MPASI hari ini?');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Contoh jawaban dari Tanya Gizi.'), findsOneWidget);
    });

    testWidgets('Onboarding muat di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
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
    });

    testWidgets('Consent muat di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      await pumpApp(tester, await prefsFor({'onboarding_completed': true}));
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.consentTitle), findsOneWidget);
      expect(find.byKey(const Key('consent-footer')), findsOneWidget);
      expect(find.text(AppStrings.consentSubmit), findsOneWidget);

      // Footer tetap terlihat; checkbox mengaktifkan tombol tanpa scroll.
      final submitBefore = tester.widget<FilledButton>(
        find.byKey(const Key('consent-submit')),
      );
      expect(submitBefore.onPressed, isNull);

      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final submitAfter = tester.widget<FilledButton>(
        find.byKey(const Key('consent-submit')),
      );
      expect(submitAfter.onPressed, isNotNull);

      // Rincian data & disclaimer tetap bisa digulir di belakang footer.
      await tester.scrollUntilVisible(
        find.text(AppStrings.consentDisclaimerTitle),
        240,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.consentSubmit), findsOneWidget);
    });

    testWidgets(
      'Makan & tips Beranda muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        await pumpApp(
          tester,
          await prefsFor({
            'onboarding_completed': true,
            'consent_version_accepted': '2',
          }),
        );

        await tester.tap(find.text(AppStrings.navMakan));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Gulir ke diary kosong (grid kelompok ada di atas).
        await tester.scrollUntilVisible(
          find.text(AppStrings.makanDiaryEmpty),
          240,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('makan-list')),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);

        // Beranda: kartu tips tampil (belum ada catatan) & tidak overflow.
        await tester.tap(find.text(AppStrings.navHome));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(AppStrings.tipTitle),
          240,
          scrollable: find.descendant(
            of: find.byKey(const Key('home-list')),
            matching: find.byType(Scrollable),
          ),
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.tipTitle), findsOneWidget);
      },
    );

    testWidgets(
      'Riwayat Makan (ringkasan + kalender) muat di 360dp @1.3 (${brightness.name})',
      (tester) async {
        useSmallScreen(tester, brightness);
        final child = fakeChild();
        await pumpApp(
          tester,
          await prefsFor({
            'onboarding_completed': true,
            'consent_version_accepted': '2',
          }),
          logs: [
            fakeFoodLog(
              id: 'yesterday-1',
              childId: child.id,
              eatenAt: DateTime.now().subtract(const Duration(days: 1)),
              groups: const ['eggs'],
            ),
          ],
        );

        await tester.tap(find.text(AppStrings.navMakan));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.makanSectionHistory));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final historyScrollable = find
            .descendant(
              of: find.byKey(const Key('makan-history-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text(AppStrings.makanHistorySummaryTitle),
          120,
          scrollable: historyScrollable,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.makanHistorySummaryTitle), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text(AppStrings.makanHistoryCalendarTitle),
          120,
          scrollable: historyScrollable,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.makanHistoryCalendarTitle), findsOneWidget);
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
            'consent_version_accepted': '2',
          }),
        );

        // Kelola anak kini dibuka dari tab Akun (header Beranda tidak lagi
        // menyimpan tombol ini).
        await tester.tap(find.text(AppStrings.navAccount));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(AppStrings.accountChildManage));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.childListTitle), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.childPhotoTitle), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text(AppStrings.childNicknameLabel),
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
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

    testWidgets('Akun (profil + pengingat) & Resep muat di 360dp @1.3 '
        '(${brightness.name})', (tester) async {
      useSmallScreen(tester, brightness);
      await pumpApp(
        tester,
        await prefsFor({
          'onboarding_completed': true,
          'consent_version_accepted': '2',
        }),
      );

      await tester.tap(find.text(AppStrings.navAccount));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.accountChildSection), findsOneWidget);

      final accountScrollable = find.descendant(
        of: find.byKey(const Key('account-list')),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        find.text(AppStrings.settingsRemindersTitle),
        240,
        scrollable: accountScrollable.first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(AppStrings.settingsReminderMonthlyTitle),
        findsOneWidget,
      );
      expect(find.text(AppStrings.settingsReminderDailyTitle), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.settingsReminderFootnote),
        240,
        scrollable: accountScrollable.first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.settingsReminderFootnote), findsOneWidget);

      // Privasi & data: tampil dan dapat diakses dengan gulir.
      await tester.scrollUntilVisible(
        find.text(AppStrings.accountPrivacyTitle),
        240,
        scrollable: accountScrollable.first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.accountPrivacyTitle), findsOneWidget);
      expect(find.text(AppStrings.accountPrivacyPhotoBody), findsOneWidget);

      // Tentang aplikasi: heading + rujukan tampil.
      await tester.scrollUntilVisible(
        find.text(AppStrings.accountDisclaimerTitle),
        240,
        scrollable: accountScrollable.first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.accountDisclaimerTitle), findsOneWidget);

      // Tab Resep: empty state jujur (katalog belum dirilis).
      await tester.tap(find.text(AppStrings.navRecipe));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.recipesPendingTitle), findsOneWidget);
    });
  }
}
