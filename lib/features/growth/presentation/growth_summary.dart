import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement_point.dart';
import 'package:cekgizi/features/growth/domain/services/growth_trend_evaluator.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Ringkasan status tumbuh yang siap dipakai widget (PRD §6.3, §6.5).
///
/// Logika murni: memilih status terburuk, mengurutkan pengukuran, dan
/// menghitung selisih berat — tidak ada UI di sini, sehingga mudah diuji.
final class GrowthStatusSummary {
  const GrowthStatusSummary({
    required this.title,
    required this.body,
    required this.action,
    required this.tone,
  });

  final String title;
  final String body;
  final String action;
  final StatusTone tone;

  /// Status terburuk dari HAZ/WAZ/WHZ pada [latest] (PRD §3.9).
  factory GrowthStatusSummary.worstOf(GrowthMeasurement latest) {
    final entries = <({AnthropometryIndex index, String? status})>[
      (index: AnthropometryIndex.haz, status: latest.statusHaz),
      (index: AnthropometryIndex.waz, status: latest.statusWaz),
      (index: AnthropometryIndex.whz, status: latest.statusWhz),
    ];
    entries.sort(
      (a, b) => GrowthStatusCopy.severity(b.index, b.status)
          .compareTo(GrowthStatusCopy.severity(a.index, a.status)),
    );
    final chosen = entries.first;
    final copy = GrowthStatusCopy.forIndex(chosen.index, chosen.status);
    return GrowthStatusSummary(
      title: copy.title,
      body: copy.body,
      action: copy.action,
      tone: copy.tone,
    );
  }
}

/// Pembantu murni untuk layar Beranda/Tumbuh.
abstract final class GrowthSummary {
  const GrowthSummary._();

  /// Urut naik menurut tanggal ukur (salinan; input tidak diubah).
  static List<GrowthMeasurement> sorted(
    List<GrowthMeasurement> measurements,
  ) {
    return [...measurements]
      ..sort((a, b) => a.measuredOn.compareTo(b.measuredOn));
  }

  /// Pengukuran terbaru, atau null bila belum ada.
  static GrowthMeasurement? latestOf(List<GrowthMeasurement> measurements) {
    if (measurements.isEmpty) return null;
    return sorted(measurements).last;
  }

  /// Tren pertumbuhan (PRD §3.6) dari data yang sudah diurutkan.
  static GrowthTrendResult trendOf(List<GrowthMeasurement> measurements) {
    return GrowthTrendEvaluator.evaluate([
      for (final measurement in sorted(measurements))
        GrowthMeasurementPoint(
          measuredOn: measurement.measuredOn,
          weightKg: measurement.weightKg,
          hazStatusCode: measurement.statusHaz,
        ),
    ]);
  }

  /// Selisih berat terhadap pengukuran sebelumnya; null bila < 2 data.
  static double? weightDeltaOf(List<GrowthMeasurement> measurements) {
    if (measurements.length < 2) return null;
    final ordered = sorted(measurements);
    final previous = ordered[ordered.length - 2];
    final current = ordered.last;
    return current.weightKg - previous.weightKg;
  }
}
