import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/router.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

final _berandaScrollable = find.descendant(
  of: find.byKey(const Key('home-list')),
  matching: find.byType(Scrollable),
);

final _makanScrollable = find.descendant(
  of: find.byKey(const Key('makan-list')),
  matching: find.byType(Scrollable),
).first;

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  double delta = 240,
}) {
  return tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable ?? _makanScrollable,
    maxScrolls: 60,
  );
}

/// Menjalankan aplikasi dengan fake repository; [logs] = seed food_logs.
Future<void> _pumpApp(
  WidgetTester tester, {
  required ChildProfile child,
  List<FoodLog> logs = const [],
}) async {
  SharedPreferences.setMockInitialValues(
    {'onboarding_completed': true, 'consent_version_accepted': '1'},
  );
  final prefs = await LocalPrefs.load();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
        growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
        permenkesTablesProvider.overrideWith(
          (ref) => Future.value(const FakeAnthropometryTables()),
        ),
        foodLogRepositoryProvider.overrideWithValue(
          FakeFoodLogRepository(logs),
        ),
        nutritionRulesProvider.overrideWith(
          (ref) => Future.value(fakeNutritionRules()),
        ),
      ],
      child: const CekGiziApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'quick-add: tap kelompok → tersimpan → ring naik → target tercapai → tips hilang',
    (tester) async {
      final child = fakeChild();
      await _pumpApp(tester, child: child);

      // Beranda: hero menampilkan kondisi kosong.
      expect(find.text(AppStrings.piringEmpty), findsOneWidget);

      // Pindah ke Makan lewat bottom nav.
      await tester.tap(find.text(AppStrings.navMakan));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.makanTitle), findsWidgets);

      // Diary kosong dulu.
      await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
      expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);

      // Catat "Makanan pokok" — sekali tap langsung tersimpan.
      await _scrollTo(tester, find.text(AppStrings.groupGrainsTubersShort));
      await tester.tap(find.text(AppStrings.groupGrainsTubersShort));
      await tester.pumpAndSettle();
      // Snackbar konfirmasi muncul dengan aksi Urungkan.
      expect(
        find.text(AppStrings.makanLogAdded(AppStrings.groupGrainsTubers)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.makanUndoAction), findsOneWidget);

      // Catat 4 kelompok lain agar target 5 tercapai (6–23 bln, ASI dihitung).
      for (final shortLabel in [
        AppStrings.groupLegumesNutsShort,
        AppStrings.groupDairyShort,
        AppStrings.groupEggsShort,
        AppStrings.groupOtherFruitVegShort,
      ]) {
        await _scrollTo(tester, find.text(shortLabel), delta: -240);
        await tester.tap(find.text(shortLabel));
        await tester.pumpAndSettle();
      }

      // Beranda menampilkan status tercapai.
      await tester.tap(find.text(AppStrings.navHome));
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        find.text(AppStrings.piringTargetReached),
        scrollable: _berandaScrollable,
      );
      expect(find.text(AppStrings.piringTargetReached), findsOneWidget);
      expect(find.text('5/8'), findsOneWidget);

      // Tips disembunyikan saat target tercapai.
      expect(find.text(AppStrings.tipTitle), findsNothing);
    },
  );

  testWidgets('aksi Urungkan pada snackbar menghapus catatan yang baru dibuat', (
    tester,
  ) async {
    final child = fakeChild();
    await _pumpApp(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text(AppStrings.groupGrainsTubersShort));
    await tester.tap(find.text(AppStrings.groupGrainsTubersShort));
    await tester.pumpAndSettle();
    // Urutkan dulu ke atas supaya diary kosong bisa diverifikasi.
    expect(find.text(AppStrings.makanUndoAction), findsOneWidget);
    await tester.tap(find.text(AppStrings.makanUndoAction));
    await tester.pumpAndSettle();

    // Tidak ada catatan tersisa.
    await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
    expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);
  });

  testWidgets('ASI: tombol Catat/Hapus ASI bekerja eksplisit', (tester) async {
    final child = fakeChild();
    await _pumpApp(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Tap "Catat ASI" → snackbar & tombol berubah jadi "Tercatat".
    expect(find.text(AppStrings.makanAsiActionLog), findsOneWidget);
    await tester.tap(find.text(AppStrings.makanAsiActionLog));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.makanAsiLogged), findsOneWidget);
    expect(find.text(AppStrings.makanAsiLoggedFeedback), findsOneWidget);

    // Ketuk tombol "Hapus ASI" → catatan ASI dihapus (tanpa scroll).
    await tester.tap(find.text(AppStrings.makanAsiActionRemove));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.makanAsiActionLog), findsOneWidget);
    expect(find.text(AppStrings.makanAsiSubtitle), findsOneWidget);

    // Catat lagi → entri ASI tampil di diary (scroll ke bawah).
    await tester.tap(find.text(AppStrings.makanAsiActionLog));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('ASI'));
    expect(find.text('ASI'), findsOneWidget);
  });

  testWidgets('bayi <6 bulan: grid disembunyikan, kartu ASI eksklusif tampil', (
    tester,
  ) async {
    final child = fakeChild(
      birthDate: DateTime.now().subtract(const Duration(days: 90)),
    );
    await _pumpApp(tester, child: child);

    // Beranda: kartu ASI eksklusif menggantikan ring.
    expect(find.text(AppStrings.asiExclusiveTitle), findsWidgets);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Grid kelompok pangan TIDAK tampil; catatan ASI eksklusif tampil.
    expect(find.text(AppStrings.makanGridTitle), findsNothing);
    expect(find.text(AppStrings.asiExclusiveTitle), findsOneWidget);
    // Tombol catat ASI tetap bisa dipakai.
    expect(find.text(AppStrings.makanAsiActionLog), findsOneWidget);
  });

  testWidgets('tips hari ini tampil saat kelompok belum tercapai', (tester) async {
    final child = fakeChild();
    await _pumpApp(
      tester,
      child: child,
      logs: [
        fakeFoodLog(
          id: 'log-1',
          childId: child.id,
          eatenAt: DateTime.now(),
          groups: const ['grains_tubers'],
        ),
      ],
    );

    // Tips tampil (satu tips dari aturan palsu) — di bawah lipatan → scroll beranda.
    await _scrollTo(
      tester,
      find.text(AppStrings.tipTitle),
      scrollable: _berandaScrollable,
    );
    expect(find.text(AppStrings.tipTitle), findsOneWidget);
  });

  testWidgets(
    'ketuk ulang kelompok yang sudah tercatat tidak menambah log duplikat',
    (tester) async {
      final child = fakeChild();
      await _pumpApp(
        tester,
        child: child,
        logs: [
          fakeFoodLog(
            id: 'seed-1',
            childId: child.id,
            eatenAt: DateTime.now(),
            groups: const ['grains_tubers'],
          ),
        ],
      );

      await tester.tap(find.text(AppStrings.navMakan));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.makanTodayProgress(1, 8)), findsOneWidget);

      await _scrollTo(tester, find.text(AppStrings.groupGrainsTubersShort));
      await tester.tap(find.text(AppStrings.groupGrainsTubersShort));
      await tester.pumpAndSettle();

      // Bukan catatan baru — tawaran menghapus.
      expect(
        find.text(
          AppStrings.makanGroupAlreadyLogged(AppStrings.groupGrainsTubers),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.makanDeleteLog), findsOneWidget);

      await tester.tap(find.text(AppStrings.makanDeleteLog));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text(AppStrings.makanTodayEmpty), delta: -240);
      expect(find.text(AppStrings.makanTodayEmpty), findsOneWidget);

      await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
      expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);
    },
  );

  testWidgets('hari sebelumnya dilipat; catatan terbuka setelah diketuk', (
    tester,
  ) async {
    final child = fakeChild();
    await _pumpApp(
      tester,
      child: child,
      logs: [
        fakeFoodLog(
          id: 'yesterday-1',
          childId: child.id,
          eatenAt: DateTime.now().subtract(const Duration(days: 1)),
          groups: const ['eggs'],
          items: const [
            FoodLogItem(name: 'Telur dadar kemarin', groups: ['eggs']),
          ],
        ),
      ],
    );

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text(AppStrings.makanYesterday));
    expect(find.text(AppStrings.makanYesterday), findsOneWidget);
    // Item hari sebelumnya belum dibangun sebelum lipatan dibuka.
    expect(find.text('Telur dadar kemarin'), findsNothing);

    await tester.tap(find.text(AppStrings.makanYesterday));
    await tester.pumpAndSettle();
    expect(find.text('Telur dadar kemarin'), findsOneWidget);
  });

  testWidgets('usia 24–59 bulan: semesta 7 kelompok & ASI jadi sekunder', (
    tester,
  ) async {
    final child = fakeChild(
      birthDate: DateTime.now().subtract(const Duration(days: 900)),
    );
    const groups = [
      'grains_tubers',
      'legumes_nuts',
      'dairy',
      'flesh',
      'eggs',
    ];
    await _pumpApp(
      tester,
      child: child,
      logs: [
        for (var i = 0; i < groups.length; i++)
          fakeFoodLog(
            id: 'log-$i',
            childId: child.id,
            eatenAt: DateTime.now(),
            groups: [groups[i]],
          ),
      ],
    );

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Semesta target 7 (tanpa ASI), bukan 8.
    expect(find.text(AppStrings.makanTodayProgress(5, 7)), findsOneWidget);
    expect(find.text(AppStrings.makanAsiSecondaryNote), findsOneWidget);
    final asiButton = tester.widget<TextButton>(
      find
          .ancestor(
            of: find.text(AppStrings.makanAsiActionLog),
            matching: find.byWidgetPredicate((widget) => widget is TextButton),
          )
          .first,
    );
    expect(asiButton.onPressed, isNotNull);
  });

  testWidgets('hero tetap menampilkan status protein hewani saat tercapai', (
    tester,
  ) async {
    final child = fakeChild();
    const groups = [
      'grains_tubers',
      'legumes_nuts',
      'dairy',
      'flesh',
      'eggs',
    ];
    await _pumpApp(
      tester,
      child: child,
      logs: [
        for (var i = 0; i < groups.length; i++)
          fakeFoodLog(
            id: 'log-$i',
            childId: child.id,
            eatenAt: DateTime.now(),
            groups: [groups[i]],
          ),
      ],
    );

    await _scrollTo(
      tester,
      find.text(AppStrings.piringTargetReached),
      scrollable: _berandaScrollable,
    );
    // Satu status capaian (tidak ganda) + protein hewani tetap terlihat.
    expect(find.text(AppStrings.piringTargetReached), findsOneWidget);
    expect(find.text(AppStrings.piringAnimalProteinPresent), findsOneWidget);
  });
}
