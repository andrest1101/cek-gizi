import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/auth/domain/repositories/auth_repository.dart';

/// Implementasi [AuthRepository] di atas `supabase_flutter`.
/// Session dikelola SDK (secure storage); tidak ada data anak yang dikirim.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInAnonymously() async {
    if (_client.auth.currentSession != null) return;
    await _client.auth.signInAnonymously();
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;
}
