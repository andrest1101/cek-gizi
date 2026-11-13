import 'package:shared_preferences/shared_preferences.dart';

/// Flag lokal ringan (offline-safe): status onboarding & consent.
/// Bukan sumber kebenaran data anak - hanya gating UI pertama buka.
final class LocalPrefs {
  LocalPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyConsentVersion = 'consent_version_accepted';

  /// Versi teks consent terkini - bila dinaikkan, pengguna diminta setuju lagi.
  static const String consentVersion = '1';

  static Future<LocalPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalPrefs._(prefs);
  }

  bool get isOnboardingCompleted => _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted() => _prefs.setBool(_keyOnboardingCompleted, true);

  bool get isConsentAccepted =>
      (_prefs.getString(_keyConsentVersion) ?? '') == consentVersion;

  Future<void> setConsentAccepted() =>
      _prefs.setString(_keyConsentVersion, consentVersion);

  /// Untuk tes: tulis flag mentah.
  Future<void> debugSetOnboardingCompleted(bool value) =>
      _prefs.setBool(_keyOnboardingCompleted, value);
}
