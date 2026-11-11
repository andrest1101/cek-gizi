import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/services/age_calculator.dart';
import 'package:cekgizi/features/growth/domain/services/growth_evaluator.dart';

/// Hasil evaluasi satu pengukuran (dipakai add & edit).
final class MeasurementEvaluation {
  const MeasurementEvaluation({
    required this.ageMonths,
    required this.haz,
    required this.waz,
    required this.whz,
    required this.statusHaz,
    required this.statusWaz,
    required this.statusWhz,
  });

  final int ageMonths;
  final double haz;
  final double waz;
  final double whz;
  final String? statusHaz;
  final String? statusWaz;
  final String? statusWhz;
}

abstract final class MeasurementEvaluator {
  const MeasurementEvaluator._();

  /// Validasi input + evaluasi z + klasifikasi (PRD §3.1–3.5).
  static MeasurementEvaluation evaluate({
    required ChildProfile child,
    required DateTime measuredOn,
    required double weightKg,
    required double lengthHeightCm,
    required MeasureMode mode,
    required AnthropometryReferenceTables tables,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(measuredOn.year, measuredOn.month, measuredOn.day);
    if (date.isAfter(today)) {
      throw const InvalidMeasurementException(
        'Tanggal ukur tidak boleh di masa depan.',
      );
    }

    if (weightKg < 1 || weightKg > 30) {
      throw const InvalidMeasurementException(
        'Berat harus antara 1 dan 30 kg.',
      );
    }
    if (lengthHeightCm < 35 || lengthHeightCm > 130) {
      throw const InvalidMeasurementException(
        'Panjang/tinggi harus antara 35 dan 130 cm.',
      );
    }

    final age = AgeCalculator.inCompletedMonths(
      birthDate: child.birthDate,
      measuredOn: date,
    );

    final haz = GrowthEvaluator.evaluateHaz(
      sex: child.sex,
      ageMonths: age,
      rawLengthHeightCm: lengthHeightCm,
      mode: mode,
      tables: tables,
    );
    final waz = GrowthEvaluator.evaluateWaz(
      sex: child.sex,
      ageMonths: age,
      weightKg: weightKg,
      tables: tables,
    );
    final whz = GrowthEvaluator.evaluateWhz(
      sex: child.sex,
      ageMonths: age,
      rawLengthHeightCm: lengthHeightCm,
      mode: mode,
      weightKg: weightKg,
      tables: tables,
    );

    return MeasurementEvaluation(
      ageMonths: age,
      haz: haz.zScore,
      waz: waz.zScore,
      whz: whz.zScore,
      statusHaz: haz.statusCode,
      statusWaz: waz.statusCode,
      statusWhz: whz.statusCode,
    );
  }
}
