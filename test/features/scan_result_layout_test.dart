import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/meal_scan_result_sheet.dart';

import '../fakes.dart';

const _stressResult = MealScanResult(
  requestId: 'req-layout',
  isFood: true,
  imageQuality: MealScanImageQuality.ok,
  items: [
    MealScanItem(
      name: 'Bubur nasi dengan lauk ayam dan sayur',
      groups: ['grains_tubers', 'flesh', 'vit_a_fruit_veg'],
      confidence: 0.5,
    ),
    MealScanItem(
      name: 'Tempe goreng',
      groups: ['legumes_nuts'],
      confidence: 0.9,
    ),
    MealScanItem(
      name: 'Buah pisang',
      groups: ['other_fruit_veg'],
      confidence: 0.7,
    ),
  ],
);

class _Harness extends StatelessWidget {
  const _Harness({required this.theme, required this.child});

  final ThemeData theme;
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => MealScanResultSheet(
                  result: _stressResult,
                  childId: child.id,
                ),
              ),
              child: const Text('buka-sheet'),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required ThemeData theme,
  required Size logicalSize,
  required double textScale,
  required ChildProfile child,
}) async {
  tester.view.physicalSize = logicalSize * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues(const {
    'onboarding_completed': true,
    'consent_version_accepted': '2',
  });
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
        foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
        nutritionRulesProvider.overrideWith(
          (ref) => Future.value(fakeNutritionRules()),
        ),
      ],
      child: _Harness(theme: theme, child: child),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('buka-sheet'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectCleanSheet(
    WidgetTester tester, {
    required ThemeData theme,
    required Size size,
    required double textScale,
  }) async {
    await _pumpSheet(
      tester,
      theme: theme,
      logicalSize: size,
      textScale: textScale,
      child: fakeChild(),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.scanSheetTitle), findsOneWidget);
    // Tiga chip porsi per item, tidak ada yang meluber.
    expect(find.text(AppStrings.portionLittle), findsNWidgets(3));
    expect(find.text(AppStrings.portionMedium), findsNWidgets(3));
    expect(find.text(AppStrings.portionFinished), findsNWidgets(3));
    // Tombol simpan tetap terlihat tanpa perlu menggulir.
    expect(find.byKey(const Key('scan-save')).hitTestable(), findsOneWidget);
    // Pratinjau keragaman berasal dari aturan, bukan model.
    expect(find.text(AppStrings.scanDiversityPreview(5, 5)), findsOneWidget);
  }

  testWidgets('360dp @1.3 light: tidak ada overflow', (tester) async {
    await expectCleanSheet(
      tester,
      theme: AppTheme.light(),
      size: const Size(360, 800),
      textScale: 1.3,
    );
  });

  testWidgets('392dp @1.0 light: tidak ada overflow', (tester) async {
    await expectCleanSheet(
      tester,
      theme: AppTheme.light(),
      size: const Size(392, 852),
      textScale: 1.0,
    );
  });

  testWidgets('360dp @1.3 dark: tidak ada overflow', (tester) async {
    await expectCleanSheet(
      tester,
      theme: AppTheme.dark(),
      size: const Size(360, 800),
      textScale: 1.3,
    );
  });

  testWidgets('pemilih kelompok membatasi tiga kelompok per item', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      theme: AppTheme.light(),
      logicalSize: const Size(360, 800),
      textScale: 1.3,
      child: fakeChild(),
    );

    final edit = find.descendant(
      of: find.byKey(const ValueKey('scan-item-card-1')),
      matching: find.text(AppStrings.scanGroupEdit),
    );
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.scanGroupPickerTitle), findsOneWidget);
    expect(find.text(AppStrings.scanGroupPickerCount(1, 3)), findsOneWidget);

    // Tambah dua kelompok lagi → total tiga.
    await tester.tap(
      find.byKey(const ValueKey('scan-group-tile-grains_tubers')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-group-tile-dairy')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.scanGroupPickerCount(3, 3)), findsOneWidget);

    // Kelompok keempat ditolak dengan pesan, bukan ditambahkan diam-diam.
    await tester.tap(find.byKey(const ValueKey('scan-group-tile-flesh')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.scanGroupPickerFull), findsOneWidget);
    expect(find.text(AppStrings.scanGroupPickerCount(3, 3)), findsOneWidget);

    // Lepas satu lalu ganti → tetap tiga.
    await tester.tap(
      find.byKey(const ValueKey('scan-group-tile-legumes_nuts')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-group-tile-flesh')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan-group-done')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final card = find.byKey(const ValueKey('scan-item-card-1'));
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.groupShortLabel('grains_tubers')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.groupShortLabel('dairy')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.groupShortLabel('flesh')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.groupShortLabel('legumes_nuts')),
      ),
      findsNothing,
    );
  });
}
