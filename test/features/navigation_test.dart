import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/account/presentation/widgets/reminder_settings_section.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/home/presentation/widgets/app_nav_bar.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

/// Navigasi utama v2.1 (PRD §6.2): 5 tab + Tanya sebagai route penuh.
Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'onboarding_completed': true,
    'consent_version_accepted': '2',
  });
  final prefs = await LocalPrefs.load();
  final child = fakeChild();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
        growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lima destinasi: label & path unik, urutan sesuai router', () {
    const expectedLabels = [
      AppStrings.navHome,
      AppStrings.navMakan,
      AppStrings.navRecipe,
      AppStrings.navGrowth,
      AppStrings.navAccount,
    ];

    expect(
      AppDestination.values.map((d) => d.label),
      orderedEquals(expectedLabels),
    );
    expect(
      AppDestination.values.map((d) => d.path).toSet(),
      hasLength(AppDestination.values.length),
    );
    expect(AppDestination.home.path, '/');
  });

  testWidgets('setiap tab menampilkan layar yang sesuai', (tester) async {
    await _pumpApp(tester);

    // Beranda: kartu hero Piring Hari Ini.
    expect(find.text(AppStrings.piringTitle.toUpperCase()), findsOneWidget);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.capturePanelTitle), findsOneWidget);
    expect(find.text(AppStrings.makanSectionToday), findsOneWidget);

    await tester.tap(find.text(AppStrings.navRecipe));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.recipesSubtitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.growthSubtitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountChildSection), findsOneWidget);

    // Kembali ke Beranda: state tab lain tidak menghalangi.
    await tester.tap(find.text(AppStrings.navHome));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.piringTitle.toUpperCase()), findsOneWidget);
  });

  testWidgets('bubble Tanya membuka layar penuh dan bisa ditutup', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text(AppStrings.tanyaBubbleLabel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tanyaTitle), findsOneWidget);

    // Tombol tutup mengembalikan ke shell (bilah navigasi terlihat lagi).
    await tester.tap(find.byTooltip(AppStrings.tanyaClose));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tanyaTitle), findsNothing);
    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.text(AppStrings.piringTitle.toUpperCase()), findsOneWidget);
  });

  testWidgets('tab Akun: profil anak, pengingat, dan jalan ke kelola anak', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.accountChildSection), findsOneWidget);
    expect(find.text(AppStrings.accountChildManage), findsOneWidget);

    // Seksi Pengingat ada di bawah Tampilan. ListView membuild anak secara
    // lazy, jadi gulir dulu sebelum mencari teksnya, lalu kembali ke atas
    // untuk tombol "Kelola anak".
    final accountList = find.byKey(const Key('account-list'));
    await tester.dragFrom(tester.getCenter(accountList), const Offset(0, -720));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ReminderSettingsSection),
        matching: find.text(AppStrings.settingsRemindersTitle),
      ),
      findsOneWidget,
    );

    await tester.dragFrom(tester.getCenter(accountList), const Offset(0, 720));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.accountChildManage));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childListTitle), findsOneWidget);
  });
}
