import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/services/age_calculator.dart';

/// Profil anak (PRD §5.2, §6.1). Nama, tanggal lahir, jenis kelamin, avatar.
final class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    required this.birthDate,
    required this.sex,
    required this.avatarKey,
  });

  final String id;
  final String nickname;
  final DateTime birthDate;
  final Sex sex;
  final String avatarKey;

  /// Usia dalam bulan penuh pada suatu tanggal (PRD §3.1).
  int ageInCompletedMonths(DateTime at) =>
      AgeCalculator.inCompletedMonths(birthDate: birthDate, measuredOn: at);

  /// '3 tahun 4 bulan' atau '5 bulan'.
  String ageLabel(DateTime at) {
    final months = ageInCompletedMonths(at);
    if (months < 12) return '$months bulan';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem == 0 ? '$years tahun' : '$years tahun $rem bulan';
  }

  ChildProfile copyWith({
    String? id,
    String? nickname,
    DateTime? birthDate,
    Sex? sex,
    String? avatarKey,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      avatarKey: avatarKey ?? this.avatarKey,
    );
  }
}
