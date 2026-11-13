/// Format tanggal Bahasa Indonesia (tanpa dependency intl).
abstract final class IdDateFormat {
  const IdDateFormat._();

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String full(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String short(DateTime d) =>
      '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';

  /// Eyebrow tanggal untuk header Beranda, mis. "Rabu, 11 Nov".
  static String eyebrow(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1].substring(0, 3)}';
}
