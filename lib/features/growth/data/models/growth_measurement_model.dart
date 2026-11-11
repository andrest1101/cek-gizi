import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';

/// Model baris tabel `growth_measurements` (PRD §5.2).
final class GrowthMeasurementModel {
  const GrowthMeasurementModel(this.measurement);

  final GrowthMeasurement measurement;

  factory GrowthMeasurementModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map['measured_on'] as String;
    final iso = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    return GrowthMeasurementModel(
      GrowthMeasurement(
        id: map['id'] as String,
        childId: map['child_id'] as String,
        measuredOn: DateTime.parse(iso),
        weightKg: (map['weight_kg'] as num).toDouble(),
        lengthHeightCm: (map['length_height_cm'] as num).toDouble(),
        measureMode: MeasureMode.fromDbValue(map['measure_mode'] as String),
        ageMonths: (map['age_months'] as num).toInt(),
        haz: (map['haz'] as num).toDouble(),
        waz: (map['waz'] as num).toDouble(),
        whz: (map['whz'] as num).toDouble(),
        statusHaz: map['status_haz'] as String?,
        statusWaz: map['status_waz'] as String?,
        statusWhz: map['status_whz'] as String?,
        refVersion: map['ref_version'] as String,
        note: map['note'] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'child_id': measurement.childId,
        'measured_on': _isoDate(measurement.measuredOn),
        'weight_kg': measurement.weightKg,
        'length_height_cm': measurement.lengthHeightCm,
        'measure_mode': measurement.measureMode.dbValue,
        'age_months': measurement.ageMonths,
        'haz': measurement.haz,
        'waz': measurement.waz,
        'whz': measurement.whz,
        'status_haz': measurement.statusHaz,
        'status_waz': measurement.statusWaz,
        'status_whz': measurement.statusWhz,
        'ref_version': measurement.refVersion,
        'note': measurement.note,
      };

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
