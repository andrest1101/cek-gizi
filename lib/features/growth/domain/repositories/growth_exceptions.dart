/// Pengukuran duplikat (PRD §6.5: satu pengukuran per anak per tanggal).
final class DuplicateMeasurementException implements Exception {
  const DuplicateMeasurementException();

  @override
  String toString() => 'Sudah ada pengukuran pada tanggal ini.';
}
