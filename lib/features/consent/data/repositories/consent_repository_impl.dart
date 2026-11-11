import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/consent/domain/repositories/consent_repository.dart';

/// Simpan persetujuan consent ke `user_consents` (RLS: hanya baris miliknya).
final class ConsentRepositoryImpl implements ConsentRepository {
  const ConsentRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> acceptConsent({required String version}) async {
    await _client.from('user_consents').upsert({'version': version});
  }
}
