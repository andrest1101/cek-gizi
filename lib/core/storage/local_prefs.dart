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

  Future<void> setPiringTourSeen() =>
      _prefs.setBool(_keyPiringTourSeen, true);

  /// Untuk tes: tulis flag mentah.
  Future<void> debugSetOnboardingCompleted(bool value) =>
      _prefs.setBool(_keyOnboardingCompleted, value);
}

/// Dikonfigurasi di `main()`; tes melakukan override dengan prefs dari
/// SharedPreferences mock.
final localPrefsProvider = Provider<LocalPrefs>(
  (ref) => throw UnimplementedError('Override localPrefsProvider di main().'),
);
