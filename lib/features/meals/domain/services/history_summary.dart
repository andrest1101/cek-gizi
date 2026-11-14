import 'package:cekgizi/core/time/local_dates.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';

/// Satu hari dalam riwayat: tanggal lokal + evaluasi Piring Hari Ini pada
/// tanggal tersebut (target mengikuti usia anak SAAT ITU, bukan usia hari
/// ini).
final class HistoryDay {
  const HistoryDay({required this.day, required this.piring});

  /// Awal hari lokal (00.00).
  final DateTime day;
  final PiringDay piring;

  bool get hasLogs => piring.logs.isNotEmpty;
  int get metCount => piring.countedCount;
  int get targetCount => piring.targetCount;
  bool get targetReached => piring.isTargetReached;
  bool get animalProteinPresent => piring.animalProteinPresent;
  List<FoodLog> get logs => piring.logs;
}

/// Ringkasan rentang hari untuk layar Riwayat (PRD §6.4 diary).
///
/// [days] selalu terbaru di urutan pertama dan panjangnya sama dengan
/// [windowDays], termasuk hari tanpa catatan. Hari kosong tetap disertakan
/// agar kalender/strip tidak "bolong".
final class HistorySummary {
  const HistorySummary({
    required this.days,
    required this.windowStart,
    required this.windowEnd,
  });

  final List<HistoryDay> days;

  /// Inklusif.
  final DateTime windowStart;

  /// Eksklusif.
  final DateTime windowEnd;

  int get windowDays => days.length;
  int get daysWithLogs => days.where((day) => day.hasLogs).length;
  int get targetReachedDays => days.where((day) => day.targetReached).length;
  int get animalProteinDays =>
      days.where((day) => day.animalProteinPresent).length;

  /// Hari terbaru yang punya catatan, atau null bila tidak ada.
  HistoryDay? get latestWithLogs =>
      days.where((day) => day.hasLogs).firstOrNull;

  /// Cari satu hari (dibandingkan hanya tanggal lokalnya).
  HistoryDay? dayOf(DateTime at) {
    for (final day in days) {
      if (day.day.year == at.year &&
          day.day.month == at.month &&
          day.day.day == at.day) {
        return day;
      }
    }
    return null;
  }

  /// [count] hari terbaru, terbaru dulu (untuk strip 7 hari).
  List<HistoryDay> recent(int count) {
    if (count <= 0) return const [];
    return days.take(count).toList();
  }
}

/// Bangun ringkasan riwayat dari kumpulan log.
///
/// Murni (tanpa Flutter) dan deterministik: [today] menentukan batas jendela,
/// [ageMonthsAt] menghitung usia anak pada tiap hari, dan [profiles] berasal
/// dari `nutrition_rules.json` (tidak ada target yang di-hardcode).
abstract final class HistoryEvaluator {
  const HistoryEvaluator._();

  static const int defaultWindowDays = 30;

  static HistorySummary build({
    required List<FoodLog> logs,
    required DateTime today,
    required int Function(DateTime day) ageMonthsAt,
    required List<DiversityProfile> profiles,
    int windowDays = defaultWindowDays,
  }) {
    final range = localRecentDaysRange(today, windowDays);
    final end = range.to;
    return HistorySummary(
      days: [
        for (var offset = 0; offset < windowDays; offset++)
          _evaluateDay(
            day: DateTime(end.year, end.month, end.day - 1 - offset),
            logs: logs,
            ageMonthsAt: ageMonthsAt,
            profiles: profiles,
          ),
      ],
      windowStart: range.from,
      windowEnd: range.to,
    );
  }

  static HistoryDay _evaluateDay({
    required DateTime day,
    required List<FoodLog> logs,
    required int Function(DateTime day) ageMonthsAt,
    required List<DiversityProfile> profiles,
  }) {
    return HistoryDay(
      day: startOfLocalDay(day),
      piring: PiringDayEvaluator.evaluate(
        logs: logs,
        today: day,
        ageMonths: ageMonthsAt(day),
        profiles: profiles,
      ),
    );
  }
}
