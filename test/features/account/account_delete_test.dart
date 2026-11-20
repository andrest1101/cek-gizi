import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/account/domain/repositories/account_exceptions.dart';
import 'package:cekgizi/features/account/domain/repositories/account_repository.dart';
import 'package:cekgizi/features/account/presentation/providers/account_providers.dart';
import 'package:cekgizi/features/children/data/datasources/child_photo_store.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

import '../../fakes.dart';

final class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository({this.error});

  final Object? error;
  bool invoked = false;

  @override
  Future<void> deleteAccount() async {
    invoked = true;
    if (error != null) throw error!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalPrefs> prefsFor(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return LocalPrefs.load();
  }

  Future<Directory> tempDirectory() async {
    final directory = await Directory.systemTemp.createTemp('account_delete');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    return directory;
  }

  test('hapus akun sukses: foto lokal, prefs, dan sesi dibersihkan', () async {
    final child = fakeChild();
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
      'piring_tour_seen': true,
      'reminder_daily_enabled': true,
    });
    final directory = await tempDirectory();
    final store = LocalChildPhotoStore(
      directoryResolver: () async => directory,
    );
    await store.save(child.id, Uint8List.fromList([1, 2, 3]));
    expect(await store.pathFor(child.id), isNotNull);

    final repo = _FakeAccountRepository();
    var signedOut = false;
    final container = ProviderContainer(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
        childPhotoStoreProvider.overrideWithValue(store),
        accountRepositoryProvider.overrideWithValue(repo),
        accountSignOutProvider.overrideWithValue(() async {
          signedOut = true;
        }),
      ],
    );
    addTearDown(container.dispose);

    // Pastikan daftar anak terisi sebelum delete() mengambil childIds.
    await container.read(childrenListProvider.future);
    expect(container.read(childrenListProvider).value, hasLength(1));

    await container.read(deleteAccountProvider.notifier).delete();

    final state = container.read(deleteAccountProvider);
    expect(state.isDone, isTrue);
    expect(state.error, isFalse);
    expect(repo.invoked, isTrue);
    expect(await store.pathFor(child.id), isNull);
    expect(prefs.isOnboardingCompleted, isFalse);
    expect(prefs.isConsentAccepted, isFalse);
    expect(prefs.isPiringTourSeen, isFalse);
    expect(prefs.reminderDailyEnabled, isFalse);
    expect(signedOut, isTrue);
  });

  test('hapus akun gagal: data lokal tidak tersentuh', () async {
    final child = fakeChild();
    final prefs = await prefsFor({
      'onboarding_completed': true,
      'consent_version_accepted': '2',
    });
    final directory = await tempDirectory();
    final store = LocalChildPhotoStore(
      directoryResolver: () async => directory,
    );
    await store.save(child.id, Uint8List.fromList([9, 9]));

    final repo = _FakeAccountRepository(
      error: const AccountException('delete_account_error'),
    );
    var signedOut = false;
    final container = ProviderContainer(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        childRepositoryProvider.overrideWithValue(FakeChildRepository([child])),
        childPhotoStoreProvider.overrideWithValue(store),
        accountRepositoryProvider.overrideWithValue(repo),
        accountSignOutProvider.overrideWithValue(() async {
          signedOut = true;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(childrenListProvider.future);
    await container.read(deleteAccountProvider.notifier).delete();

    final state = container.read(deleteAccountProvider);
    expect(state.error, isTrue);
    expect(state.isDone, isFalse);
    expect(await store.pathFor(child.id), isNotNull);
    expect(prefs.isOnboardingCompleted, isTrue);
    expect(signedOut, isFalse);
  });
}
