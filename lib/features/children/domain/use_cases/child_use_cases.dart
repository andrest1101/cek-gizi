import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import '../repositories/child_exceptions.dart';
import '../repositories/child_repository.dart';
import '../entities/child_profile.dart';

/// Tambah/ubah anak dengan aturan batas 5 profil (PRD §2).
abstract final class ChildUseCases {
  const ChildUseCases._();

  static Future<ChildProfile> add(
    ChildRepository repository, {
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async {
    final existing = await repository.listChildren();
    if (existing.length >= 5) {
      throw const ChildLimitException();
    }
    return repository.addChild(
      nickname: nickname.trim(),
      birthDate: birthDate,
      sex: sex,
      avatarKey: avatarKey,
    );
  }
}
