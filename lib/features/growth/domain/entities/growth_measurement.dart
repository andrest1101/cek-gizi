import 'measure_mode.dart';

/// Satu pengukuran anak (PRD §5.2, §6.5).
///
/// Nilai z disimpan untuk audit; `status_*` null berarti z di luar rentang
/// masuk akal (PRD §3.5) — UI menampilkan peringatan, bukan klasifikasi.
final class GrowthMeasurement {
  const GrowthMeasurement({
    required this.id,
    required this.childId,
    required this.measuredOn,
    required this.weightKg,
    required this.lengthHeightCm,
    required this.measureMode,
    required this.ageMonths,
    required this.haz,
    required this.waz,
    required this.whz,
    required this.statusHaz,
    required this.statusWaz,
    required this.statusWhz,
    required this.refVersion,
    this.note,
  });

  final String id;
  final String childId;
  final DateTime measuredOn;
  final double weightKg;
  final double lengthHeightCm;
  final MeasureMode measureMode;
  final int ageMonths;

  final double haz;
  final double waz;
  final double whz;

  final String? statusHaz;
  final String? statusWaz;
  final String? statusWhz;

  final String refVersion;
  final String? note;
}
