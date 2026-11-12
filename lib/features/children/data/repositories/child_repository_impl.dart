import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/children/data/models/child_model.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_repository.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';

/// CRUD anak di Supabase (tabel `children`, RLS aktif - PRD §5.3).
/// Penolakan oleh RLS dibiarkan muncul sebagai galat server (ditangani UI).
final class ChildRepositoryImpl implements ChildRepository {
  const ChildRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ChildProfile>> listChildren() async {
    final rows = await _client
        .from('children')
        .select('id, nickname, birth_date, sex, avatar_key')
        .order('created_at');
    return [for (final row in rows as List) ChildModel.fromMap(row as Map<String, dynamic>).child];
  }

  @override
  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async {
    final payload = ChildModel(
      ChildProfile(
        id: '',
        nickname: nickname.trim(),
        birthDate: birthDate,
        sex: sex,
        avatarKey: avatarKey,
      ),
    ).insertMap();
    final row = await _client
        .from('children')
        .insert(payload)
        .select('id, nickname, birth_date, sex, avatar_key')
        .single();
    return ChildModel.fromMap(row).child;
  }

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    final payload = ChildModel(child).updateMap();
    final row = await _client
        .from('children')
        .update(payload)
        .eq('id', child.id)
        .select('id, nickname, birth_date, sex, avatar_key')
        .single();
    return ChildModel.fromMap(row).child;
  }

  @override
  Future<void> deleteChild(String id) async {
    await _client.from('children').delete().eq('id', id);
    // growth_measurements terhapus berantai (FK on delete cascade).
  }
}
