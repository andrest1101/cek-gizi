import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Flag lokal ringan (offline-safe): status onboarding, consent, dan penanda
/// tur singkat. Bukan sumber kebenaran data anak - hanya gating UI pertama
/// buka.
final class LocalPrefs {
  LocalPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyConsentVersion = 'consent_version_accepted';
  static const _keyPiringTourSeen = 'piring_tour_seen';
  static const _keyReminderMonthlyEnabled = 'reminder_monthly_enabled';
  static const _keyReminderMonthlyDay = 'reminder_monthly_day';
  static const _keyReminderDailyEnabled = 'reminder_daily_enabled';
  static const _keyReminderDailyHour = 'reminder_daily_hour';
  static const _keyReminderDailyMinute = 'reminder_daily_minute';

  /// Versi teks consent terkini - bila dinaikkan, pengguna diminta setuju lagi.
  static const String consentVersion = '1';

  static Future<LocalPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalPrefs._(prefs);
  }

  bool get isOnboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted() =>
      _prefs.setBool(_keyOnboardingCompleted, true);

  bool get isConsentAccepted =>
      (_prefs.getString(_keyConsentVersion) ?? '') == consentVersion;

  Future<void> setConsentAccepted() =>
      _prefs.setString(_keyConsentVersion, consentVersion);

  /// Tur singkat "Piring Hari Ini" hanya tampil sekali. Pengguna tetap bisa
  /// membuka penjelasan lengkap lewat tombol "Cara kerja".
  bool get isPiringTourSeen => _prefs.getBool(_keyPiringTourSeen) ?? false;

  Future<void> setPiringTourSeen() => _prefs.setBool(_keyPiringTourSeen, true);

  /// Untuk tes: tulis flag mentah.
  Future<void> debugSetOnboardingCompleted(bool value) =>
      _prefs.setBool(_keyOnboardingCompleted, value);

  // ── Pengingat lokal (PRD §6.8): dua jenis, default MATI ───────────────

  /// Ukur anak bulanan pada tanggal pilihan (pukul 08.00).
  bool get reminderMonthlyEnabled =>
      _prefs.getBool(_keyReminderMonthlyEnabled) ?? false;

  Future<void> setReminderMonthlyEnabled(bool value) =>
      _prefs.setBool(_keyReminderMonthlyEnabled, value);

  /// Tanggal bulanan 1–28 (dibatasi agar selalu valid).
  int get reminderMonthlyDay {
    final day = _prefs.getInt(_keyReminderMonthlyDay) ?? 1;
    return day.clamp(1, 28);
  }

  Future<void> setReminderMonthlyDay(int value) =>
      _prefs.setInt(_keyReminderMonthlyDay, value.clamp(1, 28));

  bool get reminderDailyEnabled =>
      _prefs.getBool(_keyReminderDailyEnabled) ?? false;

  Future<void> setReminderDailyEnabled(bool value) =>
      _prefs.setBool(_keyReminderDailyEnabled, value);

  int get reminderDailyHour => _prefs.getInt(_keyReminderDailyHour) ?? 19;

  int get reminderDailyMinute => _prefs.getInt(_keyReminderDailyMinute) ?? 0;

  Future<void> setReminderDailyTime(int hour, int minute) async {
    await _prefs.setInt(_keyReminderDailyHour, hour.clamp(0, 23));
    await _prefs.setInt(_keyReminderDailyMinute, minute.clamp(0, 59));
  }
}

/// Dikonfigurasi di `main()`; tes melakukan override dengan prefs dari
/// SharedPreferences mock.
final localPrefsProvider = Provider<LocalPrefs>(
  (ref) => throw UnimplementedError('Override localPrefsProvider di main().'),
);
