import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';

/// Rumus z-score metode tabel SD Permenkes 2/2020 (PRD §3.3):
///
/// ```
/// jika X < median:  z = (X − median) / (median − SD(−1))
/// jika X ≥ median:  z = (X − median) / (SD(+1) − median)
/// ```
abstract final class ZScore {
  const ZScore._();

  static double calculate({required double value, required SdColumns sd}) {
    if (value < sd.median) {
      final divisor = sd.divisorBelow;
      if (divisor <= 0) {
        throw const InvalidReferenceDataException(
          'Tabel SD tidak valid: kolom −1 mesti di bawah median.',
        );
      }
      return (value - sd.median) / divisor;
    }

    final divisor = sd.divisorAbove;
    if (divisor <= 0) {
      throw const InvalidReferenceDataException(
        'Tabel SD tidak valid: kolom +1 mesti di atas median.',
      );
    }
    return (value - sd.median) / divisor;
  }
}
