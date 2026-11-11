import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_exceptions.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_repository.dart';
import 'package:cekgizi/features/growth/domain/services/measurement_evaluator.dart';

/// Simpan pengukuran: duplikat dicek, z-score & status dihitung di Domain,
/// lalu disimpan ke repository (PRD §6.5).
final class SaveMeasurement {
  const SaveMeasurement._();

  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static Future<GrowthMeasurement> add({
    required GrowthRepository repository,
    required ChildProfile child,
    required DateTime measuredOn,
    required double weightKg,
    required double lengthHeightCm,
    required MeasureMode mode,
    required AnthropometryReferenceTables tables,
    String? note,
  }) async {
    final date = DateTime(measuredOn.year, measuredOn.month, measuredOn.day);
    final existing = await repository.findOnDate(
      childId: child.id,
      date: date,
    );
    if (existing != null) {
      throw const DuplicateMeasurementException();
    }
    final evaluation = MeasurementEvaluator.evaluate(
      child: child,
      measuredOn: date,
      weightKg: weightKg,
      lengthHeightCm: lengthHeightCm,
      mode: mode,
      tables: tables,
    );
    return repository.insert(
      GrowthMeasurement(
        id: '',
        childId: child.id,
        measuredOn: date,
        weightKg: weightKg,
        lengthHeightCm: lengthHeightCm,
        measureMode: mode,
        ageMonths: evaluation.ageMonths,
        haz: evaluation.haz,
        waz: evaluation.waz,
        whz: evaluation.whz,
        statusHaz: evaluation.statusHaz,
        statusWaz: evaluation.statusWaz,
        statusWhz: evaluation.statusWhz,
        refVersion: AppConfig.permenkesRefVersion,
        note: _cleanNote(note),
      ),
    );
  }

  static Future<GrowthMeasurement> update({
    required GrowthRepository repository,
    required ChildProfile child,
    required GrowthMeasurement existing,
    required double weightKg,
    required double lengthHeightCm,
    required MeasureMode mode,
    required AnthropometryReferenceTables tables,
    String? note,
  }) async {
    final evaluation = MeasurementEvaluator.evaluate(
      child: child,
      measuredOn: existing.measuredOn,
      weightKg: weightKg,
      lengthHeightCm: lengthHeightCm,
      mode: mode,
      tables: tables,
    );
    return repository.update(
      GrowthMeasurement(
        id: existing.id,
        childId: child.id,
        measuredOn: existing.measuredOn,
        weightKg: weightKg,
        lengthHeightCm: lengthHeightCm,
        measureMode: mode,
        ageMonths: evaluation.ageMonths,
        haz: evaluation.haz,
        waz: evaluation.waz,
        whz: evaluation.whz,
        statusHaz: evaluation.statusHaz,
        statusWaz: evaluation.statusWaz,
        statusWhz: evaluation.statusWhz,
        refVersion: AppConfig.permenkesRefVersion,
        note: _cleanNote(note),
      ),
    );
  }
}
