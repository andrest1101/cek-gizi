/// Ausnahme domain murni (bukan Flutter). Pesan berbahasa Indonesia untuk
/// ditampilkan ke pengguna setelah dipetakan oleh lapisan presentasi.
sealed class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Input di luar cakupan tabel referensi (mis. umur di luar 0–60 bulan).
final class OutOfSupportedRangeException extends DomainException {
  const OutOfSupportedRangeException(super.message);
}

/// Nilai pengukuran tidak masuk akal (mis. PB/TB di luar 35–130 cm).
final class InvalidMeasurementException extends DomainException {
  const InvalidMeasurementException(super.message);
}

/// Tabel SD tidak valid (mis. kolom "−1" dan median sama → pembagi nol).
final class InvalidReferenceDataException extends DomainException {
  const InvalidReferenceDataException(super.message);
}
