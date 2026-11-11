/// Tingkat "red flag" untuk Tanya Gizi — PRD §3.8.
///
/// Dijalankan di server (Edge Function) untuk SEMUA pesan user — di sini
/// tersedia versi Dart agar aturan yang sama bisa dites unit dan dipakai
/// ulang di klien untuk pratinjau UI (kartu khusus safety).
///
/// emergency → arahkan ke IGD terdekat / 112 (kejang, sesak, tersedak, biru).
/// referDoctor → arahkan ke tenaga kesehatan / puskesmas.
enum RedFlagLevel {
  none,
  referDoctor,
  emergency,
}

abstract final class RedFlagChecker {
  const RedFlagChecker._();

  /// Kata kunci darurat (Ordo: cek emergency dulu). PRD §3.8.
  static const List<String> emergencyKeywords = <String>[
    'kejang',
    'sesak',
    'tersedak',
    'biru',
  ];

  /// Kata kunci gejala gawat yang mengarahkan ke tenaga kesehatan.
  static const List<String> referDoctorKeywords = <String>[
    'lemas',
    'tidak mau minum',
    'muntah terus',
    'diare',
    'berdarah',
    'bengkak setelah makan',
    'alergi',
    'demam',
  ];

  static RedFlagLevel check(String message) {
    final text = message.toLowerCase();
    for (final keyword in emergencyKeywords) {
      if (text.contains(keyword)) return RedFlagLevel.emergency;
    }
    for (final keyword in referDoctorKeywords) {
      if (text.contains(keyword)) return RedFlagLevel.referDoctor;
    }
    return RedFlagLevel.none;
  }
}
