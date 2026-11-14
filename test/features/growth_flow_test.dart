import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur ukur: CTA kartu → validasi → simpan → grafik & riwayat', (
    tester,
  ) async {
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
          growthRepositoryProvider
              .overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith((ref) => Future.value(fakeNutritionRules())),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Kartu status kosong di Beranda → buka sheet lewat CTA-nya
    // (konten Beranda sekarang lebih tinggi: hero Piring Hari Ini dll).
    expect(find.text(AppStrings.growthNoMeasurementsTitle), findsOneWidget);
    final measurementCta = find.text(AppStrings.growthNoMeasurementsCta);
    expect(measurementCta, findsOneWidget);
    await tester.ensureVisible(measurementCta);
    await tester.pumpAndSettle();
    await tester.tap(measurementCta);
    await tester.pumpAndSettle();

    // Simpan tanpa mengisi apa pun → pesan wajib muncul.
    final saveButton = find.text(AppStrings.growthMeasureSave);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.validationRequired), findsWidgets);

    // Berat di luar rentang.
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.growthMeasureWeight),
      '99',
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.validationWeightRange), findsOneWidget);

    // Isi nilai valid lalu simpan.
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.growthMeasureWeight),
      '8,2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.growthMeasureHeightLength),
      '72,0',
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Dialog hasil: z-score + kategori resmi.
    expect(find.textContaining(AppStrings.growthMeasureSaved), findsOneWidget);
    expect(find.text(AppStrings.hazLabel), findsOneWidget);
    expect(find.text(AppStrings.wazLabel), findsOneWidget);
    expect(find.text(AppStrings.whzLabel), findsOneWidget);

    // Tutup dialog, pindah ke tab Tumbuh.
    await tester.tap(find.text(AppStrings.actionClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.growthChartTitle), findsOneWidget);

    // Ganti indeks grafik ke Berat/Umur.
    await tester.tap(find.text(AppStrings.growthTabWeightShort));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.growthTabWeightShort), findsOneWidget);

    // Scroll daftar ke riwayat (tile berada di bawah lipatan 600dp).
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('8,2 kg · 72,0 cm'), findsOneWidget);
  });
}
