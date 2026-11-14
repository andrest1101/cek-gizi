import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/time/local_dates.dart';

void main() {
  group('rentang tanggal lokal', () {
    test('satu hari melintasi akhir bulan', () {
      final range = localDayRange(DateTime(2026, 12, 31, 22, 30));
      expect(range.from, DateTime(2026, 12, 31));
      expect(range.to, DateTime(2027, 1, 1));
    });

    test('rentang 30 hari berakhir besok', () {
      final range = localRecentDaysRange(DateTime(2026, 11, 13, 10), 30);
      expect(range.from, DateTime(2026, 10, 15));
      expect(range.to, DateTime(2026, 11, 14));
    });

    test('rentang 30 hari melintasi akhir bulan dan tahun', () {
      final range = localRecentDaysRange(DateTime(2027, 1, 5, 8), 30);
      expect(range.from, DateTime(2026, 12, 7));
      expect(range.to, DateTime(2027, 1, 6));
    });

    test('rentang satu bulan, termasuk Desember ke Januari', () {
      final december = localMonthRange(DateTime(2026, 12, 18));
      expect(december.from, DateTime(2026, 12, 1));
      expect(december.to, DateTime(2027, 1, 1));

      final february = localMonthRange(DateTime(2028, 2, 29));
      expect(february.from, DateTime(2028, 2, 1));
      expect(february.to, DateTime(2028, 3, 1));
    });

    test('geser bulan mempertahankan hari pertama', () {
      expect(addLocalMonths(DateTime(2026, 1, 31), -1), DateTime(2025, 12, 1));
      expect(addLocalMonths(DateTime(2026, 12, 1), 1), DateTime(2027, 1, 1));
      expect(addLocalMonths(DateTime(2026, 3, 15), -2), DateTime(2026, 1, 1));
    });

    test('selisih hari kalender', () {
      expect(
        localDayDifference(DateTime(2026, 10, 15), DateTime(2026, 11, 13)),
        29,
      );
      expect(
        localDayDifference(DateTime(2027, 1, 1), DateTime(2026, 12, 31)),
        -1,
      );
    });

    test('jumlah hari tidak valid ditolak', () {
      expect(
        () => localRecentDaysRange(DateTime(2026, 11, 13), 0),
        throwsArgumentError,
      );
    });
  });
}
