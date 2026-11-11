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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FAB sheet: inline validation then valid save updates UI', (
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
          childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith((ref) => Future.value(const FakeAnthropometryTables())),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Status kartu kosong di Beranda.

    // Buka sheet lewat FAB.
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();

    // Simpan tanpa mengisi apa pun → pesan wajib muncul.
    await tester.tap(find.text(AppStrings.growthMeasureSave));
    await tester.pumpAndSettle();

    // Berat di luar rentang.
    await tester.enterText(find.widgetWithText(TextFormField, 'Berat (kg)'), '99');
    await tester.ensureVisible(find.text(AppStrings.growthMeasureSave));
    await tester.tap(find.text(AppStrings.growthMeasureSave));
    await tester.pumpAndSettle();

    // Isi nilai valid lalu simpan.
    await tester.enterText(find.widgetWithText(TextFormField, 'Berat (kg)'), '8,2');
    await tester.enterText(find.widgetWithText(TextFormField, 'Panjang/tinggi (cm)'), '72,0');
    await tester.ensureVisible(find.text(AppStrings.growthMeasureSave));
    await tester.tap(find.text(AppStrings.growthMeasureSave));
    await tester.pumpAndSettle();

    // Hasil tersimpan tampil.
    expect(find.text('Sesuai umur'), findsWidgets);

    // Tutup dialog, pindah ke tab Tumbuh, tile muncul.
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.growthTabLengthHeight), findsOneWidget);

    // Scroll daftar ke riwayat (tile berada di bawah lipatan 600dp).
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('8,2 kg · 72,0 cm'), findsOneWidget);
  });
}
