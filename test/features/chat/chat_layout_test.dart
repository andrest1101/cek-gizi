import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../../fakes.dart';

/// PRD §7.7: Tanya Gizi harus muat di 360dp pada text scale 1,3, light & dark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const brightnesses = [Brightness.light, Brightness.dark];

  Future<LocalPrefs> prefs() async {
    SharedPreferences.setMockInitialValues(const {
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
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
    LocalPrefs localPrefs,
    FakeChatRepository chatRepo,
  ) async {
    final child = fakeChild();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(localPrefs),
          childRepositoryProvider.overrideWithValue(
            FakeChildRepository([child]),
          ),
          growthRepositoryProvider.overrideWithValue(FakeGrowthRepository()),
          permenkesTablesProvider.overrideWith(
            (ref) => Future.value(const FakeAnthropometryTables()),
          ),
          foodLogRepositoryProvider.overrideWithValue(FakeFoodLogRepository()),
          nutritionRulesProvider.overrideWith(
            (ref) => Future.value(fakeNutritionRules()),
          ),
          chatRepositoryProvider.overrideWithValue(chatRepo),
        ],
        child: const CekGiziApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTanya(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.tanyaBubbleLabel));
    await tester.pumpAndSettle();
  }

  for (final brightness in brightnesses) {
    testWidgets('empty state rapi di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      await pumpApp(tester, await prefs(), FakeChatRepository());
      await openTanya(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.tanyaEmptyTitle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.tanyaChipMpasi),
        120,
        scrollable: find.descendant(
          of: find.byKey(const Key('tanya-empty-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.tanyaChipMpasi), findsOneWidget);
      expect(find.text(AppStrings.tanyaDisclaimerBanner), findsOneWidget);
    });

    testWidgets('jawaban markdown tidak overflow (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      final now = DateTime.now();
      final chatRepo = FakeChatRepository(
        seed: [
          fakeChatMessage(
            id: 'u1',
            role: ChatRole.user,
            content: 'Anak saya susah makan sayur. Apa yang bisa saya coba?',
            createdAt: now.subtract(const Duration(minutes: 3)),
          ),
          fakeChatMessage(
            id: 'a1',
            role: ChatRole.assistant,
            content:
                '**Coba cara ini:**\n'
                '- Sajikan sayur dengan warna cerah.\n'
                '- Beri contoh makan bersama anak.\n\n'
                '1. Mulai dari porsi kecil.\n'
                '2. Jangan memaksa saat anak menolak.',
            createdAt: now.subtract(const Duration(minutes: 2)),
          ),
        ],
      );

      await pumpApp(tester, await prefs(), chatRepo);
      await openTanya(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Coba cara ini:'), findsOneWidget);
      expect(
        find.textContaining('Sajikan sayur dengan warna cerah'),
        findsOneWidget,
      );
      // Tidak ada penanda markdown mentah yang tampil.
      expect(find.textContaining('**'), findsNothing);
      expect(find.textContaining('- '), findsNothing);
      // Identitas asisten hanya di header, tidak diulang di tiap jawaban.
      expect(find.text(AppConfig.appName), findsNothing);
    });

    testWidgets('galat kirim tampil ringkas (${brightness.name})', (
      tester,
    ) async {
      useSmallScreen(tester, brightness);
      final chatRepo = FakeChatRepository(
        usageUsed: 30,
        askError: const ChatException('quota_daily'),
      );

      await pumpApp(tester, await prefs(), chatRepo);
      await openTanya(tester);

      await tester.enterText(find.byType(TextField), 'Ide MPASI hari ini?');
      await tester.pump();
      await tester.tap(find.byTooltip(AppStrings.tanyaSendSemantics));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.tanyaError('quota_daily')), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });
  }
}
