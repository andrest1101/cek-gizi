import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';

/// Sumber kolom SD tabel Permenkes 2/2020.
/// Implementasi konkret (asset JSON) berada di data layer; kontrak ini
/// di Domain agar murni Dart & mudah dites.
abstract interface class AnthropometryReferenceTables {
  /// Panjang/tinggi menurut umur, langkah 0–60 bulan (SEL pada bulan nyata).
  SdColumns haz({required Sex sex, required int ageMonths});

  /// Berat menurut umur, langkah 0–60 bulan.
  SdColumns waz({required Sex sex, required int ageMonths});

  /// Berat menurut panjang/tinggi, langkah 0,5 cm (PB untuk 0–23 bln,
  /// TB untuk 24–60 bln). [lengthHeightCmStep] sudah dibulatkan half-up
  /// oleh pemanggil — lihat [LengthHeightStep]. [ageMonths] dipakai untuk
  /// memilih tabel PB vs TB (PRD §3.3).
  SdColumns whz({
    required Sex sex,
    required double lengthHeightCmStep,
    required int ageMonths,
  });
}

/// Pembulatan panjang/tinggi ke baris step 0,5 (PRD §3.3: PB/BB per 0,5 cm).
///
/// CATATAN: aturan final mengikuti petunjuk lampiran Permenkes 2/2020 —
/// dikonfirmasi saat berkas tabel resmi tersedia (docs/reference-notes.md).
abstract final class LengthHeightStep {
  const LengthHeightStep._();

  /// Contoh: 85,28 → 85,5 ; 85,23 → 85,0 ; 85,25 → 85,5 (half-up).
  static double of(double cm) {
    if (cm <= 0) {
      throw ArgumentError.value(cm, 'cm', 'Panjang/tinggi harus positif');
    }
    return (cm * 2 + 0.5).floorToDouble() / 2;
  }
}
