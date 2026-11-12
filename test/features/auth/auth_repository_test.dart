import 'package:cekgizi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthRepositoryImpl', () {
    // Client standalone (belum initialize) - sesi kosong; test ini TIDAK
    // memanggil signInAnonymously (butuh jaringan).
    late SupabaseClient client;
    late AuthRepositoryImpl repository;

    setUp(() {
      client = SupabaseClient(
        'https://hvjqjjqgwpmpqnchnxts.supabase.co',
        'sb_publishable_3w4BFh1oJuGbXz4g4FXyOQ_fU8Ro_9S',
      );
      repository = AuthRepositoryImpl(client);
    });

    test('isSignedIn is false without a session', () {
      expect(repository.isSignedIn, isFalse);
    });

    test('currentUserId is null without a session', () {
      expect(repository.currentUserId, isNull);
    });
  });
}
