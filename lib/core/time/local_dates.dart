/// Aritmetika tanggal lokal tanpa dependensi Flutter (aman dipakai lapisan
/// domain).
///
/// Batas hari/bulan selalu dihitung ulang dari komponen tahun-bulan-hari,
/// sehingga aman melewati akhir bulan, akhir tahun, dan tahun kabisat.
library;

/// Awal hari lokal (00.00) untuk [at].
DateTime startOfLocalDay(DateTime at) => DateTime(at.year, at.month, at.day);

/// Awal hari berikutnya (eksklusif) untuk [at].
DateTime startOfNextLocalDay(DateTime at) =>
    DateTime(at.year, at.month, at.day + 1);

/// Awal bulan lokal yang memuat [at].
DateTime startOfLocalMonth(DateTime at) => DateTime(at.year, at.month);

/// Awal bulan berikutnya (eksklusif) untuk [at].
DateTime startOfNextLocalMonth(DateTime at) => DateTime(at.year, at.month + 1);

/// Geser bulan kalender dari [at], mempertahankan hari ke-1 (dipakai untuk
/// navigasi kalender).
DateTime addLocalMonths(DateTime at, int months) =>
    DateTime(at.year, at.month + months, 1);

/// Selisih hari kalender penuh dari [from] ke [to] (bisa negatif).
int localDayDifference(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Rentang satu hari lokal: [from] inklusif, [to] eksklusif.
({DateTime from, DateTime to}) localDayRange(DateTime at) => (
      from: startOfLocalDay(at),
      to: startOfNextLocalDay(at),
    );

/// Rentang [days] hari terakhir yang berakhir hari ini (termasuk hari ini).
///
/// Contoh: [at] = 13 Nov, [days] = 30 → 15 Okt 00.00 sampai 14 Nov 00.00.
({DateTime from, DateTime to}) localRecentDaysRange(DateTime at, int days) {
  if (days <= 0) {
    throw ArgumentError.value(days, 'days', 'Harus > 0');
  }
  final to = startOfNextLocalDay(at);
  final from = DateTime(to.year, to.month, to.day - days);
  return (from: from, to: to);
}

/// Rentang satu bulan kalender lokal: [from] inklusif, [to] eksklusif.
({DateTime from, DateTime to}) localMonthRange(DateTime at) => (
      from: startOfLocalMonth(at),
      to: startOfNextLocalMonth(at),
    );
