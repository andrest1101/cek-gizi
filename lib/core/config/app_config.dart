/// Konfigurasi global aplikasi.
///
/// Nama aplikasi TIDAK boleh di-hardcode di UI/file lain — selalu ambil dari
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
}
