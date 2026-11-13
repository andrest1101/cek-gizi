/// Konfigurasi global aplikasi.
///
/// Nama aplikasi TIDAK boleh di-hardcode di UI/file lain - selalu ambil dari
/// [AppConfig.appName] (PRD § "Instruksi untuk AI agent" #5). Nilai dapat
/// dioverride saat build dengan `--dart-define=APP_NAME=...`.
abstract final class AppConfig {
  const AppConfig._();

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CekGizi',
  );

  /// Versi referensi tabel Permenkes 2/2020 yang dipakai z-score.
  /// Diisi saat Batch 3 (tabel resmi disediakan pemilik proyek).
  static const String permenkesRefVersion = 'permenkes-2-2020';

  /// Supabase project URL (bukan rahasia).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hvjqjjqgwpmpqnchnxts.supabase.co',
  );

  /// Publishable key Supabase - dirancang PUBLIC untuk klien mobile dan
  /// dilindungi Row Level Security (PRD §8.4). Kunci service_role /
  /// sb_secret_* TIDAK PERNAH ada di aplikasi.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_3w4BFh1oJuGbXz4g4FXyOQ_fU8Ro_9S',
  );
}
