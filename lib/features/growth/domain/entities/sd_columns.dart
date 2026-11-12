/// Kolom SD satu baris tabel referensi Permenkes 2/2020.
///
/// `median`, `sdNeg1`, `sdPos1` wajib ada (dipakai rumus z PRD §3.3).
/// Kolom −3, −2, +2, +3 bersifat rujukan - nullable karena SATU sel di PDF
/// resmi tercetak tidak lengkap (whz_tb_female, panjang 69,5 cm, kolom −3 SD
/// tercetak "6."; didokumentasikan di docs/reference-notes.md). Kolom luar
/// tidak pernah dipakai rumus z.
final class SdColumns {
  const SdColumns({
    required this.sdNeg1,
    required this.median,
    required this.sdPos1,
    this.sdNeg3,
    this.sdNeg2,
    this.sdPos2,
    this.sdPos3,
  });

  /// −1 SD - wajib (pembagi bawah).
  final double sdNeg1;

  final double median;

  /// +1 SD - wajib (pembagi atas).
  final double sdPos1;

  final double? sdNeg3;
  final double? sdNeg2;
  final double? sdPos2;
  final double? sdPos3;

  /// Pembagi untuk nilai < median (PRD §3.3).
  double get divisorBelow => median - sdNeg1;

  /// Pembagi untuk nilai >= median (PRD §3.3).
  double get divisorAbove => sdPos1 - median;
}
