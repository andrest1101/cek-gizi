import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/account/domain/repositories/account_exceptions.dart';
import 'package:cekgizi/features/account/domain/repositories/account_repository.dart';

/// Antarmuka Edge Functions yang dipanggil repo — terisolasi untuk test.
abstract interface class AccountEdgeFunctions {
  Future<void> invokeDeleteAccount();
}

/// Implementasi memanggil Edge Function `delete-account` (PRD §6.8, §9.4).
final class EdgeFunctionAccountEdgeFunctions implements AccountEdgeFunctions {
  const EdgeFunctionAccountEdgeFunctions(this._client);

  final SupabaseClient _client;

  @override
  Future<void> invokeDeleteAccount() async {
    await _client.functions.invoke('delete-account');
  }
}

final class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._client, {AccountEdgeFunctions? functions})
    : _functions = functions;

  final SupabaseClient _client;
  final AccountEdgeFunctions? _functions;

  @override
  Future<void> deleteAccount() async {
    try {
      await (_functions ?? EdgeFunctionAccountEdgeFunctions(_client))
          .invokeDeleteAccount();
    } on FunctionException {
      throw const AccountException('delete_account_error');
    } catch (_) {
      throw const AccountException('delete_account_error');
    }
  }
}
