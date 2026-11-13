import 'anthropometry_index.dart';

/// Hasil evaluasi z-score satu indeks.
///
/// [statusCode] bernilai null bila z di luar rentang yang masuk akal
/// (PRD §3.5) - UI menampilkan peringatan "Angka ini tampak tidak biasa…"
/// dan TIDAK menampilkan klasifikasi.
final class ZScoreResult {
  const ZScoreResult({
    required this.index,
    required this.zScore,
    required this.statusCode,
    this.isOutOfRange = false,
  });

  final AnthropometryIndex index;
  final double zScore;

  /// Kode status (snake_case, dipakai DB & AppStrings):
  /// HAZ: very_short|short|normal|tall
  /// WAZ: very_low|low|normal|risk_overweight
  /// WHZ: severe_wasting|wasting|normal|risk_over|overweight|obese
  final String? statusCode;

  /// z di luar rentang masuk akal (PRD §3.5/WHO Anthro).
  final bool isOutOfRange;
}
