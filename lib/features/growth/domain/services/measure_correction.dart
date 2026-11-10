import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';

/// Koreksi cara ukur untuk panjang/tinggi (PRD §3.2).
///
/// Nilai MENTAH selalu disimpan apa adanya; koreksi dihitung saat evaluasi.
abstract final class MeasureCorrection {
  const MeasureCorrection._();

  static const double correctionCm = 0.7;

  /// Usia < 24 bulan diukur berdiri → +0,7 cm.
  /// Usia ≥ 24 bulan diukur terlentang → −0,7 cm.
  static double corrected({
    required double lengthHeightCm,
    required MeasureMode mode,
    required int ageMonths,
  }) {
    if (ageMonths < 24 && mode == MeasureMode.standing) {
      return lengthHeightCm + correctionCm;
    }
    if (ageMonths >= 24 && mode == MeasureMode.lying) {
      return lengthHeightCm - correctionCm;
    }
    return lengthHeightCm;
  }
}
