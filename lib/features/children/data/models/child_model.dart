import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';

/// Model baris tabel `children` (PRD §5.2). Snake_case kolom, camelCase Dart.
final class ChildModel {
  const ChildModel(this.child);

  final ChildProfile child;

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    final birthRaw = map['birth_date'] as String;
    final iso = birthRaw.length >= 10 ? birthRaw.substring(0, 10) : birthRaw;
    return ChildModel(
      ChildProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String,
        birthDate: DateTime.parse(iso),
        sex: Sex.fromDbValue(map['sex'] as String),
        avatarKey: (map['avatar_key'] as String?) ?? 'sprout',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': child.nickname,
      'birth_date': _isoDate(child.birthDate),
      'sex': child.sex.dbValue,
      'avatar_key': child.avatarKey,
    };
  }

  Map<String, dynamic> insertMap() => toMap();

  Map<String, dynamic> updateMap() => {
        'nickname': child.nickname,
        'birth_date': _isoDate(child.birthDate),
        'sex': child.sex.dbValue,
        'avatar_key': child.avatarKey,
      };

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
