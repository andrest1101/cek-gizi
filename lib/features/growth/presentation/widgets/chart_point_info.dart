import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Informasi ringkas untuk satu titik yang diketuk pada grafik pertumbuhan.
///
/// Semua angka berasal dari pengukuran pengguna dan tabel rujukan resmi;
/// tidak ada nilai yang dikarang atau dihasilkan AI.
final class ChartPointInfo {
  const ChartPointInfo({
    required this.dateLabel,
    required this.ageLabel,
    required this.valueLabel,
    required this.zLabel,
    required this.category,
    required this.tone,
    required this.medianLabel,
    required this.semanticsLabel,
  });

  final String dateLabel;
  final String ageLabel;
  final String valueLabel;
  final String zLabel;
  final String category;
  final StatusTone tone;
  final String medianLabel;
  final String semanticsLabel;

  factory ChartPointInfo.from({
    required GrowthMeasurement measurement,
    required AnthropometryIndex index,
    required double median,
  }) {
    final isHeight = index == AnthropometryIndex.haz;
    final value = isHeight ? measurement.lengthHeightCm : measurement.weightKg;
    final unit = isHeight ? 'cm' : 'kg';
    final valueLabel = '${GrowthStatusCopy.formatKgCm(value)} $unit';

    final delta = value - median;
    final direction = delta.abs() < 0.05
        ? AppStrings.growthPointMedianEqual
        : (delta > 0
              ? AppStrings.growthPointMedianAbove
              : AppStrings.growthPointMedianBelow);
    final medianLabel =
        '$direction ${GrowthStatusCopy.formatKgCm(delta.abs())} $unit';

    final status = switch (index) {
      AnthropometryIndex.haz => measurement.statusHaz,
      AnthropometryIndex.waz => measurement.statusWaz,
      AnthropometryIndex.whz => measurement.statusWhz,
    };
    final category = GrowthStatusCopy.categoryLabel(index, status);
    final tone = GrowthStatusCopy.toneOf(index, status);
    final zLabel = GrowthStatusCopy.formatZ(switch (index) {
      AnthropometryIndex.haz => measurement.haz,
      AnthropometryIndex.waz => measurement.waz,
      AnthropometryIndex.whz => measurement.whz,
    });
    final ageLabel = AppStrings.growthPointAgeValue(measurement.ageMonths);
    final dateLabel = IdDateFormat.short(measurement.measuredOn);

    return ChartPointInfo(
      dateLabel: dateLabel,
      ageLabel: ageLabel,
      valueLabel: valueLabel,
      zLabel: zLabel,
      category: category,
      tone: tone,
      medianLabel: medianLabel,
      semanticsLabel:
          '${AppStrings.growthPointTitle}. '
          '${AppStrings.growthPointDate}: $dateLabel. '
          '${AppStrings.growthPointAge}: $ageLabel. '
          '${AppStrings.growthPointValue}: $valueLabel. '
          '${AppStrings.growthPointZScore}: $zLabel. '
          '$category. $medianLabel.',
    );
  }
}
