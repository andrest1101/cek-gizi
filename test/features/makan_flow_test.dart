import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
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

/// Cari scrollable layar yang sedang aktif (Makan hari ini / Makan Riwayat /
/// Beranda). Cabang yang offstage tidak dipilih.
Finder? _firstShellScrollable(WidgetTester tester) {
  for (final key in const [
    Key('makan-list'),
    Key('makan-history-list'),
    Key('home-list'),
  ]) {
    final candidate = find.descendant(
      of: find.byKey(key),
      matching: find.byType(Scrollable),
    );
    if (tester.any(candidate)) return candidate;
  }
  return null;
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  final effective = scrollable ?? _firstShellScrollable(tester);
  if (effective == null) {
    await tester.pumpAndSettle();
    return;
  }
  final viewport = tester.getRect(effective);
  // Reset ke bagian paling atas, lalu maju selangkah-selangkah sampai
  // elemen benar-benar masuk viewport. `scrollUntilVisible` tidak memeriksa
  // batas viewport, jadi elemen bisa "ditemukan" padahal terpotong.
  await tester.drag(effective, const Offset(0, -10000));
  await tester.pumpAndSettle();
  for (var i = 0; i < 90; i++) {
    if (tester.any(finder)) {
      final rect = tester.getRect(finder);
      if (rect.center.dy >= viewport.top && rect.center.dy <= viewport.bottom) {
        break;
      }
    }
    await tester.drag(effective, const Offset(0, 120));
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
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

      // Catat "Makanan pokok" - sekali tap langsung tersimpan.
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
        await _scrollTo(tester, find.text(shortLabel));
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

    // Baris ASI ada di bawah panel; gulir ke sana.
    await _scrollTo(tester, find.text(AppStrings.makanAsiActionLog));

    // Tap "Catat ASI" → tombol berubah menjadi "Tercatat".
    expect(find.text(AppStrings.makanAsiActionLog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-action-breast_milk')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.makanAsiLogged), findsOneWidget);
    expect(find.text(AppStrings.makanAsiLoggedFeedback), findsOneWidget);

    // Ketuk tombol "Hapus ASI" → catatan ASI dihapus (tanpa scroll).
    await tester.tap(find.byKey(const ValueKey('group-action-breast_milk')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.makanAsiActionLog), findsOneWidget);
    expect(find.text(AppStrings.makanAsiSubtitle), findsOneWidget);

    // Catat lagi → entri ASI tampil di diary (scroll ke bawah).
    await tester.tap(find.byKey(const ValueKey('group-action-breast_milk')));
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
    await _scrollTo(tester, find.text(AppStrings.makanAsiActionLog));
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

    // Tips tampil (satu tips dari aturan palsu) - di bawah lipatan → scroll beranda.
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

      // Bukan catatan baru - tawaran menghapus.
      expect(
        find.text(
          AppStrings.makanGroupAlreadyLogged(AppStrings.groupGrainsTubers),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.makanDeleteLog), findsOneWidget);

      await tester.tap(find.text(AppStrings.makanDeleteLog));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text(AppStrings.makanTodayEmpty));
      expect(find.text(AppStrings.makanTodayEmpty), findsOneWidget);

      await _scrollTo(tester, find.text(AppStrings.makanDiaryEmpty));
      expect(find.text(AppStrings.makanDiaryEmpty), findsOneWidget);
    },
  );

  testWidgets('riwayat: catatan kemarin tampil dan tidak menomori target hari ini', (
    tester,
  ) async {
    final child = fakeChild();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await _pumpApp(
      tester,
      child: child,
      logs: [
        fakeFoodLog(
          id: 'yesterday-1',
          childId: child.id,
          eatenAt: yesterday,
          groups: const ['eggs'],
          items: const [
            FoodLogItem(name: 'Telur dadar kemarin', groups: ['eggs']),
          ],
        ),
      ],
    );

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    // Hari ini tetap kosong; catatan kemarin tidak masuk hitungan.
    expect(find.text(AppStrings.makanTodayEmpty), findsOneWidget);
    expect(find.text('0/8'), findsOneWidget);
    // Item kemarin belum dibangun di bagian Hari ini.
    expect(find.text('Telur dadar kemarin'), findsNothing);

    // Buka Riwayat dan pilih kemarin di strip 7 hari.
    await tester.tap(find.text(AppStrings.makanSectionHistory));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.makanHistoryDaysWithLogs(1, 30)),
      findsOneWidget,
    );
    final yesterdayFinder = find.byKey(
      ValueKey('week-day-${yesterday.year}-${yesterday.month}-${yesterday.day}'),
    );
    await tester.ensureVisible(yesterdayFinder);
    await tester.pumpAndSettle();
    await tester.tap(yesterdayFinder);
    await tester.pumpAndSettle();
    expect(find.text('Telur dadar kemarin'), findsOneWidget);
    // Kemarin ditandai sebagai hari di luar hari ini.
    expect(find.text(AppStrings.makanYesterday), findsWidgets);
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
    await _scrollTo(tester, find.text(AppStrings.makanAsiSecondaryNote));
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

  testWidgets('catat satu kali makan: simpan beberapa kelompok sekaligus', (
    tester,
  ) async {
    final child = fakeChild();
    await _pumpApp(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text(AppStrings.makanComposerCta));
    await tester.tap(find.text(AppStrings.makanComposerCta));
    await tester.pumpAndSettle();

    // Sheet terbuka; memilih waktu makan ini opsional tapi harus bisa.
    expect(find.text(AppStrings.catatMakanTitle), findsOneWidget);
    // Simpan dinonaktifkan saat belum ada kelompok.
    var save = tester.widget<FilledButton>(
      find.byKey(const Key('catat-makan-save')),
    );
    expect(save.onPressed, isNull);

    // Ketuk kolom pertama dulu (masih terlihat di atas), lalu gulir ke telur.
    await tester.tap(
      find.byKey(const ValueKey('catat-makan-group-grains_tubers')),
    );
    final sheetScroll = find.byKey(const Key('catat-makan-sheet'));
    await _scrollTo(
      tester,
      find.byKey(const ValueKey('catat-makan-group-eggs')),
      scrollable: sheetScroll,
    );
    await tester.tap(find.byKey(const ValueKey('catat-makan-group-eggs')));
    await tester.pumpAndSettle();
    save = tester.widget<FilledButton>(
      find.byKey(const Key('catat-makan-save')),
    );
    expect(save.onPressed, isNotNull);
    expect(find.text(AppStrings.catatMakanSelectedCount(2)), findsOneWidget);

    await tester.tap(find.byKey(const Key('catat-makan-save')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.catatMakanSaved), findsOneWidget);
    // Kembali ke atas daftar: panel hari ini menampilkan 2 dari 8 kelompok.
    await _scrollTo(tester, find.text(AppStrings.makanTodayProgress(2, 8)));
    expect(find.text(AppStrings.makanTodayProgress(2, 8)), findsOneWidget);
    await _scrollTo(tester, find.text('Makanan pokok, Telur'));
    expect(find.text('Makanan pokok, Telur'), findsOneWidget);
  });

  testWidgets('Cara kerja: lembar penjelasan tampil dan bisa ditutup', (
    tester,
  ) async {
    final child = fakeChild();
    await _pumpApp(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text(AppStrings.piringInfoOpen));
    await tester.tap(find.text(AppStrings.piringInfoOpen));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.piringInfoTitle), findsOneWidget);
    expect(find.text(AppStrings.piringInfoResetBody), findsOneWidget);
    expect(find.text(AppStrings.piringInfoNotJudgingTitle), findsOneWidget);

    await _scrollTo(
      tester,
      find.text(AppStrings.piringInfoClose),
      scrollable: find.byKey(const Key('piring-info-sheet')),
    );
    await tester.tap(find.text(AppStrings.piringInfoClose));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.piringInfoTitle), findsNothing);
  });

  testWidgets('panduan singkat tampil lalu menutup; tersimpan di prefs', (
    tester,
  ) async {
    final child = fakeChild();
    await _pumpApp(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.piringTourTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.piringTourDismiss));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.piringTourTitle), findsNothing);
  });

  testWidgets('beranda: strip 7 hari menautkan ke riwayat Makan', (tester) async {
    final child = fakeChild();
    await _pumpApp(
      tester,
      child: child,
      logs: [
        fakeFoodLog(
          id: 'today-1',
          childId: child.id,
          eatenAt: DateTime.now(),
          groups: const ['eggs'],
        ),
      ],
    );

    expect(find.text(AppStrings.homeWeekTitle), findsOneWidget);
    final historyCta = find.text(AppStrings.homeWeekHistoryCta);
    await tester.ensureVisible(historyCta);
    await tester.pumpAndSettle();
    await tester.tap(historyCta);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.makanHistorySummaryTitle), findsOneWidget);
    expect(find.text(AppStrings.makanHistoryDaysWithLogs(1, 30)), findsOneWidget);
  });
}
