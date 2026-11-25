import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_repository.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

import '../fakes.dart';

/// UX-23: daftar anak yang gagal/tertunda tidak boleh dilaporkan sebagai
/// "belum ada anak".
final class _FailThenSucceedRepository implements ChildRepository {
  _FailThenSucceedRepository(this.child);

  final ChildProfile child;
  bool fail = true;

  @override
  Future<List<ChildProfile>> listChildren() async {
    if (fail) {
      fail = false;
      throw StateError('jaringan tidak tersedia');
    }
    return [child];
  }

  @override
  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async =>
      child;

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async => child;

  @override
  Future<void> deleteChild(String id) async {}
}

final class _SlowChildRepository implements ChildRepository {
  _SlowChildRepository(this.child);

  final ChildProfile child;
  final Completer<List<ChildProfile>> completer = Completer();

  @override
  Future<List<ChildProfile>> listChildren() => completer.future;

  @override
  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async =>
      child;

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async => child;

  @override
  Future<void> deleteChild(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, ChildRepository repository) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    final prefs = await LocalPrefs.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childRepositoryProvider.overrideWithValue(repository),
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
  }

  testWidgets('Akun: gagal memuat menampilkan ErrorCard + Coba lagi', (
    tester,
  ) async {
    final child = fakeChild();
    await pumpApp(tester, _FailThenSucceedRepository(child));
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.childListLoadError), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(find.text(AppStrings.accountChildEmptyTitle), findsNothing);
  });

  testWidgets('Akun: tombol Coba lagi memuat daftar anak', (tester) async {
    final child = fakeChild(nickname: 'Arka');
    await pumpApp(tester, _FailThenSucceedRepository(child));
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.childListLoadError), findsNothing);
    expect(find.text('Arka'), findsWidgets);
  });

  testWidgets('Akun: saat memuat menampilkan skeleton, bukan "belum ada anak"', (
    tester,
  ) async {
    final child = fakeChild(nickname: 'Arka');
    final repository = _SlowChildRepository(child);
    await pumpApp(tester, repository);
    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('account-child-loading')), findsOneWidget);
    expect(find.text(AppStrings.accountChildEmptyTitle), findsNothing);

    repository.completer.complete([child]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-child-loading')), findsNothing);
    expect(find.text('Arka'), findsWidgets);
  });

  testWidgets('Makan & Tumbuh: galat menampilkan ErrorCard, bukan empty state', (
    tester,
  ) async {
    await pumpApp(tester, _FailThenSucceedRepository(fakeChild()));
    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('child-gate-error')), findsOneWidget);
    expect(find.text(AppStrings.childListLoadError), findsOneWidget);
    expect(find.text(AppStrings.growthNoChildTitle), findsNothing);

    await tester.tap(find.text(AppStrings.navGrowth));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('child-gate-error')), findsOneWidget);
    expect(find.text(AppStrings.growthNoChildTitle), findsNothing);
  });

  testWidgets('Makan: saat memuat menampilkan skeleton', (tester) async {
    final child = fakeChild();
    final repository = _SlowChildRepository(child);
    await pumpApp(tester, repository);
    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('child-gate-loading')), findsOneWidget);
    expect(find.text(AppStrings.growthNoChildTitle), findsNothing);

    repository.completer.complete([child]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('child-gate-loading')), findsNothing);
  });

  testWidgets('Benar-benar kosong tetap menampilkan empty state', (
    tester,
  ) async {
    await pumpApp(tester, FakeChildRepository(const []));

    await tester.tap(find.text(AppStrings.navMakan));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('child-gate-empty')), findsOneWidget);
    expect(find.text(AppStrings.growthNoChildTitle), findsOneWidget);
    expect(find.text(AppStrings.growthNoChildCta), findsOneWidget);

    await tester.tap(find.text(AppStrings.navAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountChildEmptyTitle), findsOneWidget);
  });
}
