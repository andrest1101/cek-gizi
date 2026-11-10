import 'package:cekgizi/core/config/app_config.dart';

/// Semua copy UI terpusat di sini (Bahasa Indonesia, nada hangat dan
/// tidak menghakimi — PRD §7.6). Widget tidak boleh menulis string bebas.
abstract final class AppStrings {
  const AppStrings._();

  /// Disclaimer tetap (PRD §8.5) — wajib tampil di Tentang & onboarding.
  static const String disclaimer =
      '${AppConfig.appName} adalah alat bantu edukasi dan pemantauan. '
      'Hasilnya bukan diagnosis dan tidak menggantikan pemeriksaan tenaga '
      'kesehatan. Jika anak sakit atau kamu khawatir, hubungi Posyandu, '
      'puskesmas, atau dokter.';

  /// Label tombol coba lagi (PRD §6.9).
  static const String retry = 'Coba lagi';

  /// Judul umum kartu galat (PRD §6.9).
  static const String errorTitle = 'Ups, terjadi kesalahan';
}
