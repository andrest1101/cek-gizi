import 'package:cekgizi/features/growth/domain/entities/growth_measurement_point.dart';

/// Hasil evaluasi tren pertumbuhan (PRD §3.6).
enum GrowthTrend {
  insufficientData,
  tracked,
  needsAttention,
}

final class GrowthTrendResult {
  const GrowthTrendResult({required this.trend, this.reasonCode});

  final GrowthTrend trend;

  /// 'weight_drop' | 'haz_worsened' | null (bukan diagnosis; hanya ajakan
  /// memeriksakan ke Posyandu/puskesmas — copy ramah di AppStrings §3.9).
  final String? reasonCode;
}

/// Tren pertumbuhan: minimal 2 pengukuran (PRD §3.6).
///
/// "perlu perhatian" bila berat turun / tidak naik dibanding pengukuran
/// sebelumnya, atau kategori HAZ memburuk. Copy bersifat ajakan — bukan
/// vonis diagnosis.
abstract final class GrowthTrendEvaluator {
  const GrowthTrendEvaluator._();

  static const _hazRank = <String, int>{
    'very_short': 0,
    'short': 1,
    'normal': 2,
    'tall': 3,
  };

  static GrowthTrendResult evaluate(List<GrowthMeasurementPoint> points) {
    if (points.length < 2) {
      return const GrowthTrendResult(trend: GrowthTrend.insufficientData);
    }
    final sorted = [...points]..sort((a, b) => a.measuredOn.compareTo(b.measuredOn));
    final prev = sorted[sorted.length - 2];
    final curr = sorted[sorted.length - 1];

    if (curr.weightKg < prev.weightKg) {
      return const GrowthTrendResult(
        trend: GrowthTrend.needsAttention,
        reasonCode: 'weight_drop',
      );
    }

    final prevRank = prev.hazStatusCode == null ? null : _hazRank[prev.hazStatusCode];
    final currRank = curr.hazStatusCode == null ? null : _hazRank[curr.hazStatusCode];
    if (prevRank != null && currRank != null && currRank < prevRank) {
      return const GrowthTrendResult(
        trend: GrowthTrend.needsAttention,
        reasonCode: 'haz_worsened',
      );
    }

    return const GrowthTrendResult(trend: GrowthTrend.tracked);
  }
}
