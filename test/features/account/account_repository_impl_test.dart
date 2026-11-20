import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/account/data/repositories/account_repository_impl.dart';
import 'package:cekgizi/features/account/domain/repositories/account_exceptions.dart';

/// Fakes untuk menguji mapping error Edge Function → [AccountException].
final class _FakeFunctions implements AccountEdgeFunctions {
  _FakeFunctions({this.error});

  final Object? error;
  bool invoked = false;

  @override
  Future<void> invokeDeleteAccount() async {
    invoked = true;
    if (error != null) throw error!;
  }
}

void main() {
  final client = SupabaseClient('https://example.supabase.co', 'anon-key');

  test('sukses: memanggil Edge Function delete-account', () async {
    final functions = _FakeFunctions();
    final repo = AccountRepositoryImpl(client, functions: functions);

    await repo.deleteAccount();

    expect(functions.invoked, isTrue);
  });

  test('FunctionException (server error) → AccountException', () async {
    final functions = _FakeFunctions(
      error: const FunctionException(status: 500, details: 'boom'),
    );
    final repo = AccountRepositoryImpl(client, functions: functions);

    expect(
      repo.deleteAccount(),
      throwsA(
        isA<AccountException>().having(
          (error) => error.code,
          'code',
          'delete_account_error',
        ),
      ),
    );
  });

  test('galat jaringan → AccountException', () async {
    final functions = _FakeFunctions(error: StateError('offline'));
    final repo = AccountRepositoryImpl(client, functions: functions);

    expect(repo.deleteAccount(), throwsA(isA<AccountException>()));
  });
}
