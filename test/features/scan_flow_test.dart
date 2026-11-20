import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/presentation/providers/scan_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/meal_scan_result_sheet.dart';

import '../fakes.dart';

final _twoItemResult = const MealScanResult(
  requestId: 'req-test',
  isFood: true,
  imageQuality: MealScanImageQuality.ok,
  items: [
    MealScanItem(
      name: 'Bubur nasi',
      groups: ['grains_tubers'],
      confidence: 0.9,
    ),
    MealScanItem(name: 'Hati ayam', groups: ['flesh'], confidence: 0.8),
  ],
);

Future<LocalPrefs> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalPrefs.load();
}

/// Panel kamera v2.2 lebih tinggi (ilustrasi + langkah + privasi), jadi CTA
/// bisa berada di bawah lipatan pada viewport tes. Gulir dulu sebelum mengetuk.
Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Pump harness yang membuka sheet hasil scan dengan satu tombol.
class _SheetHarness extends StatelessWidget {
  const _SheetHarness({required this.result, required this.childId});

  final MealScanResult result;
  final String childId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    MealScanResultSheet(result: result, childId: childId),
              ),
              child: const Text('buka-sheet'),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required ChildProfile child,
  FakeFoodLogRepository? repo,
  List<CameraDescription> cameras = const [],
}) async {
  final prefs = await _prefs({
    'onboarding_completed': true,
    'consent_version_accepted': '2',
  });

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
          repo ?? FakeFoodLogRepository(),
        ),
        nutritionRulesProvider.overrideWith(
          (ref) => Future.value(fakeNutritionRules()),
        ),
        availableCamerasProvider.overrideWith(
          (ref) => Future<List<CameraDescription>>.value(cameras),
        ),
      ],
      child: const CekGiziApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required MealScanResult result,
  required ChildProfile child,
  required FakeFoodLogRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(
          await _prefs({
            'onboarding_completed': true,
            'consent_version_accepted': '2',
          }),
        ),
        childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
        growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
        permenkesTablesProvider.overrideWith(
          (ref) => Future.value(const FakeAnthropometryTables()),
        ),
        foodLogRepositoryProvider.overrideWithValue(repo),
        nutritionRulesProvider.overrideWith(
          (ref) => Future.value(fakeNutritionRules()),
        ),
      ],
      child: _SheetHarness(result: result, childId: child.id),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('buka-sheet'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Panel kamera disembunyikan untuk anak <6 bulan', (tester) async {
    final child = fakeChild(
      birthDate: DateTime.now().subtract(const Duration(days: 60)),
    );
    await _pumpHome(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.capturePanelTitle), findsNothing);
    expect(find.text(AppStrings.asiExclusiveTitle), findsOneWidget);
  });

  testWidgets('Panel kamera di Makan membuka layar scan', (tester) async {
    final child = fakeChild();
    await _pumpHome(tester, child: child);

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.capturePanelTitle), findsOneWidget);

    await _ensureVisible(tester, find.text(AppStrings.capturePanelCta));
    await tester.tap(find.text(AppStrings.capturePanelCta));
    await tester.pumpAndSettle();

    // Di lingkungan test plugin kamera tidak tersedia → layar fallback.
    expect(find.text(AppStrings.scanCameraUnavailableTitle), findsOneWidget);
  });

  testWidgets(
    'Catat manual dari pemindai: isi nama & kelompok, lalu tersimpan sebagai catatan manual',
    (tester) async {
      final child = fakeChild();
      final repo = FakeFoodLogRepository();
      await _pumpHome(tester, child: child, repo: repo);

      // Buka pemindai dari tab Makan → fallback kamera tampil.
      await tester.tap(find.text(AppStrings.navMakan));
      await tester.pumpAndSettle();
      await _ensureVisible(tester, find.text(AppStrings.capturePanelCta));
      await tester.tap(find.text(AppStrings.capturePanelCta));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.scanCameraUnavailableTitle), findsOneWidget);

      // Buka sheet "Catat manual" dari tombol fallback.
      await tester.tap(find.byKey(const ValueKey('scan-fallback-manual')));
      await tester.pumpAndSettle();
      // Sheet terbuka (judulnya sama dengan tombol fallback; scope ke sheet).
      expect(
        find.descendant(
          of: find.byKey(const Key('manual-food-sheet')),
          matching: find.text(AppStrings.manualFoodTitle),
        ),
        findsOneWidget,
      );

      // Simpan dinonaktifkan sebelum nama dan kelompok diisi.
      var save = tester.widget<FilledButton>(
        find.byKey(const Key('manual-food-save')),
      );
      expect(save.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('manual-food-name')),
        'Bubur ayam',
      );
      await tester.tap(
        find.byKey(const ValueKey('manual-food-group-grains_tubers')),
      );
      await tester.tap(find.byKey(const ValueKey('manual-food-group-flesh')));
      await tester.pumpAndSettle();
      save = tester.widget<FilledButton>(
        find.byKey(const Key('manual-food-save')),
      );
      expect(save.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('manual-food-save')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.manualFoodSaved), findsOneWidget);
      expect(repo.logCount, 1);
      final log = repo.logs(child.id).single;
      expect(log.source, FoodLogSource.manual);
      expect(log.items.single.name, 'Bubur ayam');
      expect(log.groups, ['grains_tubers', 'flesh']);
      // Kembali ke Beranda setelah menyimpan.
      expect(find.text(AppStrings.scanCameraUnavailableTitle), findsNothing);
    },
  );

  testWidgets('sheet hasil: hapus item lalu simpan tercatat', (tester) async {
    final child = fakeChild();
    final repo = FakeFoodLogRepository();
    await _pumpSheet(tester, result: _twoItemResult, child: child, repo: repo);

    expect(find.text(AppStrings.scanSheetTitle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    // Gulir ke bawah agar tombol Simpan terlihat penuh.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.scanSave), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.scanSaveError), findsNothing);
    expect(repo.logCount, 1);
    final log = repo.logs(child.id).single;
    expect(log.source, FoodLogSource.scan);
    expect(log.items.map((item) => item.name).toList(), ['Hati ayam']);
    expect(log.groups, ['flesh']);
  });

  testWidgets('sheet hasil: item baru wajib punya kelompok sebelum disimpan', (
    tester,
  ) async {
    final child = fakeChild();
    final repo = FakeFoodLogRepository();
    await _pumpSheet(tester, result: _twoItemResult, child: child, repo: repo);

    // Buka tile tambah item, isi nama, lalu tambahkan.
    final toggle = find.byKey(const Key('scan-add-item-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('scan-add-item-field')),
      'Pisang',
    );
    await tester.tap(find.byKey(const Key('scan-add-item-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scan-item-card-2')), findsOneWidget);

    // Item baru tanpa kelompok -> Simpan tetap dinonaktifkan.
    final disabledSave = tester.widget<FilledButton>(
      find.byKey(const Key('scan-save')),
    );
    expect(disabledSave.onPressed, isNull);

    // Pilih kelompok lewat sheet pemilih kelompok.
    final editGroups = find.descendant(
      of: find.byKey(const ValueKey('scan-item-card-2')),
      matching: find.text(AppStrings.scanGroupEdit),
    );
    await tester.ensureVisible(editGroups);
    await tester.pumpAndSettle();
    await tester.tap(editGroups);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.scanGroupPickerTitle), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('scan-group-tile-other_fruit_veg')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-group-done')));
    await tester.pumpAndSettle();

    final enabledSave = tester.widget<FilledButton>(
      find.byKey(const Key('scan-save')),
    );
    expect(enabledSave.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('scan-save')));
    await tester.pumpAndSettle();
    expect(repo.logCount, 1);
    final log = repo.logs(child.id).single;
    final pisang = log.items.firstWhere((item) => item.name == 'Pisang');
    expect(pisang.groups, ['other_fruit_veg']);
  });
}
