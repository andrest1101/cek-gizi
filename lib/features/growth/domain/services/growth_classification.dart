import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/z_score_result.dart';

/// Klasifikasi status tumbuh (PRD §3.4) & penolakan klasifikasi di luar
/// rentang masuk akal (PRD §3.5).
abstract final class GrowthClassification {
  const GrowthClassification._();

  /// Batas rentang masuk akal z (PRD §3.5, diverifikasi terhadap WHO Anthro):
  /// PB/U–TB/U: ±6 · BB/U: −6 s.d. +5 · BB/PB–BB/TB: −5 s.d. +5
  static ZScoreResult haz(double z) {
    if (z.abs() > 6) return _outOfRange(AnthropometryIndex.haz, z);
    final status = z < -3
        ? 'very_short'
        : z < -2
            ? 'short'
            : z <= 3
                ? 'normal'
                : 'tall';
    return ZScoreResult(index: AnthropometryIndex.haz, zScore: z, statusCode: status);
  }

  static ZScoreResult waz(double z) {
    if (z < -6 || z > 5) return _outOfRange(AnthropometryIndex.waz, z);
    final status = z < -3
        ? 'very_low'
        : z < -2
            ? 'low'
            : z <= 1
                ? 'normal'
                : 'risk_overweight';
    return ZScoreResult(index: AnthropometryIndex.waz, zScore: z, statusCode: status);
  }

  static ZScoreResult whz(double z) {
    if (z < -5 || z > 5) return _outOfRange(AnthropometryIndex.whz, z);
    final String status;
    if (z < -3) {
      status = 'severe_wasting';
    } else if (z < -2) {
      status = 'wasting';
    } else if (z <= 1) {
      status = 'normal';
    } else if (z <= 2) {
      status = 'risk_over';
    } else if (z <= 3) {
      status = 'overweight';
    } else {
      status = 'obese';
    }
    return ZScoreResult(
      index: AnthropometryIndex.whz,
      zScore: z,
      statusCode: status,
    );
  }

  static ZScoreResult _outOfRange(AnthropometryIndex index, double z) =>
      ZScoreResult(
        index: index,
        zScore: z,
        statusCode: null,
        isOutOfRange: true,
      );
}
