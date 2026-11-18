import 'package:cekgizi/core/storage/local_prefs.dart';

/// Nilai pengingat lokal (PRD §6.8). Dibaca dari [LocalPrefs]; dipakai oleh
/// provider dan servis notifikasi. Default: dua pengingat MATI.
class ReminderSettings {
  const ReminderSettings({
    required this.monthlyEnabled,
    required this.monthlyDay,
    required this.dailyEnabled,
    required this.dailyHour,
    required this.dailyMinute,
  }) : assert(monthlyDay >= 1 && monthlyDay <= 28),
       assert(dailyHour >= 0 && dailyHour <= 23),
       assert(dailyMinute >= 0 && dailyMinute <= 59);

  /// Ukur anak bulanan, tanggal [monthlyDay] (1–28), pukul 08.00.
  final bool monthlyEnabled;
  final int monthlyDay;

  /// Catat makan harian, pukul [dailyHour]:[dailyMinute].
  final bool dailyEnabled;
  final int dailyHour;
  final int dailyMinute;

  factory ReminderSettings.fromPrefs(LocalPrefs prefs) => ReminderSettings(
    monthlyEnabled: prefs.reminderMonthlyEnabled,
    monthlyDay: prefs.reminderMonthlyDay,
    dailyEnabled: prefs.reminderDailyEnabled,
    dailyHour: prefs.reminderDailyHour,
    dailyMinute: prefs.reminderDailyMinute,
  );

  ReminderSettings copyWith({
    bool? monthlyEnabled,
    int? monthlyDay,
    bool? dailyEnabled,
    int? dailyHour,
    int? dailyMinute,
  }) => ReminderSettings(
    monthlyEnabled: monthlyEnabled ?? this.monthlyEnabled,
    monthlyDay: monthlyDay ?? this.monthlyDay,
    dailyEnabled: dailyEnabled ?? this.dailyEnabled,
    dailyHour: dailyHour ?? this.dailyHour,
    dailyMinute: dailyMinute ?? this.dailyMinute,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.monthlyEnabled == monthlyEnabled &&
      other.monthlyDay == monthlyDay &&
      other.dailyEnabled == dailyEnabled &&
      other.dailyHour == dailyHour &&
      other.dailyMinute == dailyMinute;

  @override
  int get hashCode => Object.hash(
    monthlyEnabled,
    monthlyDay,
    dailyEnabled,
    dailyHour,
    dailyMinute,
  );
}

/// Waktu berikutnya untuk pengingat harian ([hour]:[minute]) setelah [now].
DateTime nextDailyOccurrence(DateTime now, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

/// Waktu berikutnya untuk pengingat bulanan pada [day] (1–28) pukul 08.00
/// setelah [now].
DateTime nextMonthlyOccurrence(DateTime now, int day) {
  assert(day >= 1 && day <= 28);
  var candidate = DateTime(now.year, now.month, day, 8);
  if (!candidate.isAfter(now)) {
    candidate = DateTime(now.year, now.month + 1, day, 8);
  }
  return candidate;
}
