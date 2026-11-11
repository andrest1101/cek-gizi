import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import '../entities/child_profile.dart';

/// Kontrak data anak (implementasi di data layer via Supabase).
abstract interface class ChildRepository {
  Future<List<ChildProfile>> listChildren();

  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  });

  Future<ChildProfile> updateChild(ChildProfile child);

  Future<void> deleteChild(String id);
}
