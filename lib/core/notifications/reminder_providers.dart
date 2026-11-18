import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/notifications/notification_service.dart';
import 'package:cekgizi/core/notifications/reminder_schedule.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';

/// Penjadwal produksi (Android/iOS). Tes mengoverride dengan fake.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationScheduler(),
);

/// Pengingat lokal (PRD §6.8): dua jenis, default MATI.
class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  late final LocalPrefs _prefs = ref.read(localPrefsProvider);

  @override
  ReminderSettings build() => ReminderSettings.fromPrefs(_prefs);

  /// Aktifkan/matikan pengingat bulanan. Mengembalikan `false` bila izin
  /// notifikasi ditolak ketika mengaktifkan.
  Future<bool> setMonthlyEnabled(bool enabled) =>
      _update((s) => s.copyWith(monthlyEnabled: enabled), enable: enabled);

  /// Ganti tanggal pengingat bulanan (1–28).
  Future<void> setMonthlyDay(int day) =>
      _update((s) => s.copyWith(monthlyDay: day.clamp(1, 28)), enable: false);

  /// Aktifkan/matikan pengingat harian. Mengembalikan `false` bila izin
  /// notifikasi ditolak ketika mengaktifkan.
  Future<bool> setDailyEnabled(bool enabled) =>
      _update((s) => s.copyWith(dailyEnabled: enabled), enable: enabled);

  /// Ganti jam pengingat harian; pengingat dijadwalkan ulang bila aktif.
  Future<void> setDailyTime(int hour, int minute) => _update(
    (s) => s.copyWith(dailyHour: hour, dailyMinute: minute),
    enable: false,
  );

  Future<bool> _update(
    ReminderSettings Function(ReminderSettings settings) change, {
    required bool enable,
  }) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    if (enable) {
      final granted = await scheduler.requestPermission();
      if (!granted) return false;
    }
    final previous = state;
    final next = change(previous);
    await _save(next);
    state = next;
    try {
      await scheduler.apply(next);
    } catch (_) {
      await _save(previous);
      state = previous;
      try {
        await scheduler.apply(previous);
      } catch (_) {
        // Diamkan: UI menampilkan galat generik; state sudah dikembalikan.
      }
      rethrow;
    }
    return true;
  }

  Future<void> _save(ReminderSettings settings) async {
    await _prefs.setReminderMonthlyEnabled(settings.monthlyEnabled);
    await _prefs.setReminderMonthlyDay(settings.monthlyDay);
    await _prefs.setReminderDailyEnabled(settings.dailyEnabled);
    await _prefs.setReminderDailyTime(settings.dailyHour, settings.dailyMinute);
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );
