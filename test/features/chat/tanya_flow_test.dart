import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../../fakes.dart';

/// Alur Tanya Gizi (PRD §6.7) dengan fake repository - tanpa jaringan.
Future<void> _pumpApp(
  WidgetTester tester, {
  required ChildProfile child,
  required FakeChatRepository chatRepo,
}) async {
  SharedPreferences.setMockInitialValues({
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
        chatRepositoryProvider.overrideWithValue(chatRepo),
      ],
      child: const CekGiziApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTanya(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.tanyaBubbleLabel));
  await tester.pumpAndSettle();
}

/// Chip pertanyaan berada di bawah fold saat viewport pendek - gulir dulu.
///
/// `scrollUntilVisible` berhenti begitu widget *terbangun* (masuk cache
/// extent), padahal masih bisa berada di bawah viewport dan tertutup bilah
/// input. Karena itu posisi chip diverifikasi terhadap rect viewport.
Future<void> _scrollToChip(WidgetTester tester, String chipText) async {
  final list = find.descendant(
    of: find.byKey(const Key('tanya-empty-list')),
    matching: find.byType(Scrollable),
  );
  final viewport = tester.getRect(list);
  final chip = find.text(chipText);

  // Kembali ke puncak dulu supaya arah gulir selalu konsisten.
  await tester.drag(list, const Offset(0, 2000));
  await tester.pumpAndSettle();

  for (var i = 0; i < 20; i++) {
    if (tester.any(chip)) {
      final rect = tester.getRect(chip);
      if (rect.top >= viewport.top && rect.bottom <= viewport.bottom) break;
    }
    await tester.drag(list, const Offset(0, -80));
    await tester.pumpAndSettle();
  }

  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tanya: empty state tampil, chip pertanyaan mengirim', (
    tester,
  ) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(usageUsed: 3);
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    expect(find.text(AppStrings.tanyaEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.tanyaQuotaRemaining(27)), findsOneWidget);

    await _scrollToChip(tester, AppStrings.tanyaChipMpasi);
    await tester.pumpAndSettle();

    expect(chatRepo.askCalls, 1);
    // Bubble user tampil dengan teks pertanyaan.
    expect(find.text(AppStrings.tanyaChipMpasi), findsOneWidget);
    expect(find.text('Contoh jawaban dari Tanya Gizi.'), findsOneWidget);
    // Follow-up chips tampil untuk jawaban terbaru.
    expect(find.text('Boleh diulang?'), findsOneWidget);
    expect(find.text('Bagaimana dengan susu?'), findsOneWidget);
  });

  testWidgets('Tanya: menulis pertanyaan manual lalu mengirim', (tester) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository();
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    await tester.enterText(find.byType(TextField), 'Ide MPASI hari ini?');
    await tester.pump();
    await tester.tap(find.byTooltip(AppStrings.tanyaSendSemantics));
    await tester.pumpAndSettle();

    expect(chatRepo.askCalls, 1);
    expect(find.text('Ide MPASI hari ini?'), findsOneWidget);
    expect(find.text('Contoh jawaban dari Tanya Gizi.'), findsOneWidget);
    // Field kosong lagi setelah kirim.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('Tanya: jawaban refer_doctor tampil sebagai kartu khusus', (
    tester,
  ) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(
      askResult: const AskNutritionResult(
        requestId: 'req-safety',
        answer: 'Gejala demam sebaiknya diperiksa dokter.',
        safetyFlag: ChatSafetyFlag.referDoctor,
        followups: [],
      ),
    );
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    await _scrollToChip(tester, AppStrings.tanyaChipPickyEater);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tanyaSafetyReferTitle), findsOneWidget);
    expect(find.text('Mengerti'), findsOneWidget);

    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tanyaSafetyReferTitle), findsNothing);
  });

  testWidgets('Tanya: jawaban emergency tampil kartu + tombol 112', (
    tester,
  ) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(
      askResult: const AskNutritionResult(
        requestId: 'req-emg',
        answer: 'Anak kejang, segera ke IGD.',
        safetyFlag: ChatSafetyFlag.emergency,
        followups: [],
      ),
    );
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    await _scrollToChip(tester, AppStrings.tanyaChipSnack);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tanyaSafetyEmergencyTitle), findsOneWidget);
    expect(find.text(AppStrings.tanyaSafetyEmergencyCall), findsOneWidget);
  });

  testWidgets('Tanya: kuota habis menampilkan kartu ramah + coba lagi', (
    tester,
  ) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(
      usageUsed: 30,
      askError: const ChatException('quota_daily'),
    );
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    expect(find.text(AppStrings.tanyaQuotaRemaining(0)), findsOneWidget);

    await _scrollToChip(tester, AppStrings.tanyaChipMpasi);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tanyaError('quota_daily')), findsOneWidget);
    expect(chatRepo.askCalls, 1);

    // Perbaiki layanan, lalu coba lagi.
    chatRepo.askError = null;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(chatRepo.askCalls, 2);
    expect(find.text('Contoh jawaban dari Tanya Gizi.'), findsOneWidget);
  });

  testWidgets('Tanya: hapus riwayat dengan konfirmasi', (tester) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(
      seed: [
        fakeChatMessage(
          id: 'm1',
          role: ChatRole.user,
          content: 'Pertanyaan lama',
          createdAt: DateTime(2026, 11, 16, 19, 0),
        ),
        fakeChatMessage(
          id: 'm2',
          role: ChatRole.assistant,
          content: 'Jawaban lama',
          createdAt: DateTime(2026, 11, 16, 19, 1),
        ),
      ],
    );
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    expect(find.text('Pertanyaan lama'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tanyaDeleteHistory));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tanyaDeleteConfirmTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.tanyaDeleteConfirm));
    await tester.pumpAndSettle();

    expect(chatRepo.stored, isEmpty);
    expect(find.text(AppStrings.tanyaEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.tanyaDeleteDone), findsOneWidget);
  });

  testWidgets('Tanya: riwayat gagal tersimpan menampilkan peringatan', (
    tester,
  ) async {
    final child = fakeChild();
    final chatRepo = FakeChatRepository(persistError: true);
    await _pumpApp(tester, child: child, chatRepo: chatRepo);
    await _openTanya(tester);

    await _scrollToChip(tester, AppStrings.tanyaChipMilk);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tanyaSyncFailed), findsOneWidget);

    // Pulihkan penyimpanan, lalu simpan lagi tanpa memanggil AI ulang.
    chatRepo.persistError = false;
    await tester.tap(find.text(AppStrings.tanyaSyncRetry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tanyaSyncFailed), findsNothing);
    expect(chatRepo.askCalls, 1);
    expect(chatRepo.persistCalls, 3); // 1 gagal + 2 simpan ulang
  });

  testWidgets('Tanya: tanpa anak, input disembunyikan dan CTA tampil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    final prefs = await LocalPrefs.load();
    final chatRepo = FakeChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(FakeChildRepository()),
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
    await _openTanya(tester);

    expect(find.text(AppStrings.tanyaNoChildTitle), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(AppStrings.tanyaNoChildCta), findsOneWidget);
  });
}
