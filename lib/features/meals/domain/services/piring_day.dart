import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Keadaan Piring Hari Ini untuk satu anak & satu hari (waktu perangkat).
final class PiringDay {
  const PiringDay({
    required this.logs,
    required this.groups,
    required this.diversity,
    required this.profile,
  });

  /// Semua catatan hari itu, urut [FoodLog.eatenAt] naik.
  final List<FoodLog> logs;

  /// Union kelompok yang tercatat hari ini (bisa kosong).
  final Set<String> groups;

  /// Ringkasan keragaman; null bila profil usia tidak tersedia (mis. ≥60 bln).
  final DiversitySummary? diversity;

  /// Profil yang dipakai (untuk tampilan), bisa null.
  final DiversityProfile? profile;

  int get metCount => groups.length;

  bool get hasLogs => logs.isNotEmpty;

  bool get isTargetReached => diversity?.isTargetReached ?? false;

  bool get animalProteinPresent => diversity?.animalProteinPresent ?? false;
}

/// Evaluasi murni Piring Hari Ini (PRD §3.7).
///
/// [today] hanya dipakai tanggal (mode zona perangkat); catatan di luar
/// hari itu diabaikan. Kode tak dikenal = data korup → [ArgumentError].
abstract final class PiringDayEvaluator {
  const PiringDayEvaluator._();

  /// Union kelompok dari seluruh catatan pada hari [today].
  static Set<String> groupsOn(
    List<FoodLog> logs,
    DateTime today,
  ) {
    final day = DateTime(today.year, today.month, today.day);
    final groups = <String>{};
    for (final log in logs) {
      if (_isSameDay(log.eatenAt.toLocal(), day)) {
        groups.addAll(log.groups);
      }
    }
    return groups;
  }

  /// Catatan pada hari [today], urut naik menurut waktu.
  static List<FoodLog> logsOn(
    List<FoodLog> logs,
    DateTime today,
  ) {
    final day = DateTime(today.year, today.month, today.day);
    return [
      for (final log in logs)
        if (_isSameDay(log.eatenAt.toLocal(), day)) log,
    ]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
  }

  /// Evaluasi lengkap Piring Hari Ini.
  static PiringDay evaluate({
    required List<FoodLog> logs,
    required DateTime today,
    required int ageMonths,
    required List<DiversityProfile> profiles,
  }) {
    final todays = logsOn(logs, today);
    final groups = groupsOn(logs, today);
    final profile = DietaryDiversity.profileForAge(ageMonths, profiles);
    DiversitySummary? diversity;
    if (profile != null) {
      diversity = DietaryDiversity.evaluate(
        groupCodes: groups,
        profile: profile,
      );
    }
    return PiringDay(
      logs: todays,
      groups: groups,
      diversity: diversity,
      profile: profile,
    );
  }

  /// Kelompokkan seluruh catatan per hari (terbaru dulu), untuk diary.
  static List<({DateTime day, List<FoodLog> logs})> byDay(
    List<FoodLog> logs,
  ) {
    final buckets = <DateTime, List<FoodLog>>{};
    for (final log in logs) {
      final local = log.eatenAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      buckets.putIfAbsent(day, () => []).add(log);
    }
    return [
      for (final entry in buckets.entries)
        (
          day: entry.key,
          logs: entry.value..sort((a, b) => b.eatenAt.compareTo(a.eatenAt)),
        ),
    ]..sort((a, b) => b.day.compareTo(a.day));
  }

  /// Kelompok diurutkan sesuai acuan tetap (stabil & offline).
  static List<String> canonicalOrder(Iterable<String> groups) =>
      [for (final code in FoodGroup.allCodes) if (groups.contains(code)) code];

  static bool _isSameDay(DateTime a, DateTime day) =>
      a.year == day.year && a.month == day.month && a.day == day.day;
}
