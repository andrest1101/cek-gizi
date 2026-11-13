import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/entities/z_score_result.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/services/growth_classification.dart';
import 'package:cekgizi/features/growth/domain/services/measure_correction.dart';
import 'package:cekgizi/features/growth/domain/services/z_score.dart';

/// Entry point evaluasi z-score - menggabungkan koreksi 0,7 cm (PRD §3.2),
/// pencarian baris tabel, rumus §3.3, batas §3.5, dan klasifikasi §3.4.
///
/// Dipakai oleh lapisan data/presentasi; seluruh logika dihitung di Domain.
abstract final class GrowthEvaluator {
  const GrowthEvaluator._();

  /// PB/U atau TB/U (indeks HAZ).
  static ZScoreResult evaluateHaz({
    required Sex sex,
    required int ageMonths,
    required double rawLengthHeightCm,
    required MeasureMode mode,
    required AnthropometryReferenceTables tables,
  }) {
    final corrected = MeasureCorrection.corrected(
      lengthHeightCm: rawLengthHeightCm,
      mode: mode,
      ageMonths: ageMonths,
    );
    final sd = tables.haz(sex: sex, ageMonths: ageMonths);
    return GrowthClassification.haz(ZScore.calculate(value: corrected, sd: sd));
  }

  /// BB/U (indeks WAZ) - tanpa koreksi cara ukur.
  static ZScoreResult evaluateWaz({
    required Sex sex,
    required int ageMonths,
    required double weightKg,
    required AnthropometryReferenceTables tables,
  }) {
    final sd = tables.waz(sex: sex, ageMonths: ageMonths);
    return GrowthClassification.waz(ZScore.calculate(value: weightKg, sd: sd));
  }

  /// BB/PB atau BB/TB (indeks WHZ) - panjang/tinggi dikoreksi dulu.
  static ZScoreResult evaluateWhz({
    required Sex sex,
    required int ageMonths,
    required double rawLengthHeightCm,
    required MeasureMode mode,
    required double weightKg,
    required AnthropometryReferenceTables tables,
  }) {
    final corrected = MeasureCorrection.corrected(
      lengthHeightCm: rawLengthHeightCm,
      mode: mode,
      ageMonths: ageMonths,
    );
    final step = LengthHeightStep.of(corrected);
    final sd = tables.whz(
      sex: sex,
      lengthHeightCmStep: step,
      ageMonths: ageMonths,
    );
    return GrowthClassification.whz(ZScore.calculate(value: weightKg, sd: sd));
  }
}
