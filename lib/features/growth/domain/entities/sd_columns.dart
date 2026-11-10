/// Kolom SD satu baris tabel referensi Permenkes 2/2020
/// (−3, −2, −1, median, +1, +2, +3).
final class SdColumns {
  const SdColumns({
    required this.sdNeg3,
    required this.sdNeg2,
    required this.sdNeg1,
    required this.median,
    required this.sdPos1,
    required this.sdPos2,
    required this.sdPos3,
  });

  final double sdNeg3;
  final double sdNeg2;
  final double sdNeg1;
  final double median;
  final double sdPos1;
  final double sdPos2;
  final double sdPos3;

  /// Pembagi untuk nilai < median (PRD §3.3).
  double get divisorBelow => median - sdNeg1;

  /// Pembagi untuk nilai >= median (PRD §3.3).
  double get divisorAbove => sdPos1 - median;
}
