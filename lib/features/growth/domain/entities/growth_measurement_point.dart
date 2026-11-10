/// Satu titik data pertumbuhan untuk evaluasi tren (PRD §3.6).
/// Status HAZ ("very_short"/"short"/"normal"/"tall") sudah terklasifikasi;
/// boleh kosong bila pengukuran belum dievaluasi.
final class GrowthMeasurementPoint {
  const GrowthMeasurementPoint({
    required this.measuredOn,
    required this.weightKg,
    this.hazStatusCode,
  });

  final DateTime measuredOn;
  final double weightKg;
  final String? hazStatusCode;
}
