import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/features/account/data/repositories/account_repository_impl.dart';
import 'package:cekgizi/features/account/domain/repositories/account_exceptions.dart';
import 'package:cekgizi/features/account/domain/repositories/account_repository.dart';
import 'package:cekgizi/features/account/domain/use_cases/delete_account.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Logout (sepasang lampu, dipisahkan agar tes tidak menyentuh plugin auth).
typedef AccountSignOutCallback = Future<void> Function();

final accountSignOutProvider = Provider<AccountSignOutCallback>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.signOut;
});

/// State hapus akun: idle → deleting → done | error.
@immutable
final class DeleteAccountState {
  const DeleteAccountState({
    this.isBusy = false,
    this.isDone = false,
    this.error = false,
  });

  static const idle = DeleteAccountState();
  static const deleting = DeleteAccountState(isBusy: true);
  static const done = DeleteAccountState(isDone: true);
  static const failed = DeleteAccountState(error: true);

  final bool isBusy;
  final bool isDone;
  final bool error;
}

final deleteAccountProvider =
    NotifierProvider<DeleteAccountNotifier, DeleteAccountState>(
      DeleteAccountNotifier.new,
    );

class DeleteAccountNotifier extends Notifier<DeleteAccountState> {
  @override
  DeleteAccountState build() => DeleteAccountState.idle;

  Future<void> delete() async {
    final useCase = DeleteAccount(ref.read(accountRepositoryProvider));
    final store = ref.read(childPhotoStoreProvider);
    final prefs = ref.read(localPrefsProvider);
    final signOut = ref.read(accountSignOutProvider);

    state = DeleteAccountState.deleting;
    try {
      // Pastikan daftar anak termuat walau user menekan hapus sangat cepat.
      final loadedChildren = ref.read(childrenListProvider).hasValue
          ? ref.read(childrenListProvider).value ?? const <ChildProfile>[]
          : await ref.read(childrenListProvider.future);
      final childIds = [for (final child in loadedChildren) child.id];

      await useCase.call();

      // Hapus foto lokal per anak (best-effort, tidak membatalkan).
      for (final id in childIds) {
        try {
          await store.delete(id);
        } catch (_) {
          // Foto biasanya sudah tidak ada; jangan block penghapusan akun.
        }
      }

      await prefs.clearAll();

      try {
        await signOut();
      } catch (_) {
        // Sesi sudah terhapus; lanjutkan.
      }
      state = DeleteAccountState.done;
    } on AccountException {
      state = DeleteAccountState.failed;
    } catch (_) {
      state = DeleteAccountState.failed;
    }
  }
}
