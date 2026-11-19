import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../../fakes.dart';

/// Perilaku inti tab Akun: kartu identitas anak + chip pemilih anak.
/// Tidak menyentuh kamera/galeri - foto diuji lewat unit test store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalPrefs> prefsFor(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalPrefs.load();
  }

  Future<void> pumpAccount(
    WidgetTester tester,
    List<ChildProfile> children,
  ) async {
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository(children),
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
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Akun menampilkan identitas, chip kedua anak, dan kartu privasi',
    (tester) async {
      final arka = fakeChild(id: 'child-1', nickname: 'Arka', sex: Sex.male);
      final bila = fakeChild(id: 'child-2', nickname: 'Bila', sex: Sex.female);
      await pumpAccount(tester, [arka, bila]);

      expect(tester.takeException(), isNull);
      // Tanpa ukuran: kartu identitas menampilkan empty state pengukuran.
      expect(find.text(AppStrings.accountNoMeasurement), findsOneWidget);
      // Belum ada ukuran untuk kedua anak; chip tampil berdua.
      expect(find.text('Arka'), findsNWidgets(2)); // identitas + chip
      expect(find.text('Bila'), findsOneWidget); // chip saja

      // Seksi Privasi & data ada di bawah (di luar viewport awal).
      await tester.scrollUntilVisible(
        find.text(AppStrings.accountPrivacyTitle),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('account-list')),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.accountPrivacyTitle), findsOneWidget);
    },
  );

  testWidgets('Mengetuk chip anak mengubah kartu identitas', (tester) async {
    final arka = fakeChild(id: 'child-1', nickname: 'Arka', sex: Sex.male);
    final bila = fakeChild(id: 'child-2', nickname: 'Bila', sex: Sex.female);
    await pumpAccount(tester, [arka, bila]);

    expect(find.text('Bila'), findsOneWidget);
    await tester.tap(find.text('Bila'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Sekarang identitas adalah Bila; Arka hanya tersisa di chip.
    expect(find.text('Arka'), findsOneWidget);
    expect(find.text('Bila'), findsNWidgets(2));
    expect(find.text(AppStrings.accountNoMeasurement), findsOneWidget);
  });
}
