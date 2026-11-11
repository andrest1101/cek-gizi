import 'package:cekgizi/core/errors/domain_exceptions.dart';

/// Kalkulasi usia dalam bulan penuh (PRD §3.1).
abstract final class AgeCalculator {
  const AgeCalculator._();

  /// Usia dalam bulan penuh pada tanggal ukur.
  /// Di luar 0–60 bulan → [OutOfSupportedRangeException].
  /// Tanggal sebelum lahir → [InvalidMeasurementException].
  static int inCompletedMonths({
    required DateTime birthDate,
    required DateTime measuredOn,
  }) {
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final measured = DateTime(measuredOn.year, measuredOn.month, measuredOn.day);

    if (measured.isBefore(birth)) {
      throw const InvalidMeasurementException(
        'Tanggal ukur sebelum tanggal lahir.',
      );
    }

    var age = (measured.year - birth.year) * 12 + measured.month - birth.month;
    if (measured.day < birth.day) {
      age -= 1;
    }

    if (age < 0 || age > 60) {
      throw OutOfSupportedRangeException(
        'Usia $age bulan di luar rentang tabel (0–60 bulan).',
      );
    }
    return age;
  }
}
