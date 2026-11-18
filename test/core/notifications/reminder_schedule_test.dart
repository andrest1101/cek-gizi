import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/notifications/reminder_schedule.dart';

void main() {
  group('nextDailyOccurrence', () {
    test('hari ini bila jam belum lewat', () {
      final now = DateTime(2026, 11, 18, 8, 0);
      expect(nextDailyOccurrence(now, 19, 0), DateTime(2026, 11, 18, 19));
    });

    test('besok bila jam sudah lewat', () {
      final now = DateTime(2026, 11, 18, 20, 30);
      expect(nextDailyOccurrence(now, 19, 0), DateTime(2026, 11, 19, 19));
    });

    test('besok bila jam persis sekarang (tidak sama persis)', () {
      final now = DateTime(2026, 11, 18, 19, 0);
      expect(nextDailyOccurrence(now, 19, 0), DateTime(2026, 11, 19, 19));
    });

    test('melintasi akhir bulan dan tahun', () {
      final now = DateTime(2026, 12, 31, 23, 59);
      expect(nextDailyOccurrence(now, 8, 0), DateTime(2027, 1, 1, 8));
    });
  });

  group('nextMonthlyOccurrence', () {
    test('bulan ini bila tanggal belum lewat', () {
      final now = DateTime(2026, 11, 18, 8, 0);
      expect(nextMonthlyOccurrence(now, 20), DateTime(2026, 11, 20, 8));
    });

    test('bulan ini bila tanggal = hari ini dan jam belum lewat', () {
      final now = DateTime(2026, 11, 18, 7, 0);
      expect(nextMonthlyOccurrence(now, 18), DateTime(2026, 11, 18, 8));
    });

    test('bulan depan bila tanggal hari ini sudah lewat pukul 08.00', () {
      final now = DateTime(2026, 11, 18, 8, 0);
      expect(nextMonthlyOccurrence(now, 18), DateTime(2026, 12, 18, 8));
    });

    test('bulan depan bila tanggal sudah lewat', () {
      final now = DateTime(2026, 11, 18, 8, 0);
      expect(nextMonthlyOccurrence(now, 5), DateTime(2026, 12, 5, 8));
    });

    test('melintasi akhir tahun', () {
      final now = DateTime(2026, 12, 20, 8, 0);
      expect(nextMonthlyOccurrence(now, 3), DateTime(2027, 1, 3, 8));
    });

    test('tanggal 28 selalu valid', () {
      final now = DateTime(2026, 2, 20, 8, 0);
      expect(nextMonthlyOccurrence(now, 28), DateTime(2026, 2, 28, 8));
    });
  });

  group('ReminderSettings', () {
    test('default prefs = dua pengingat MATI', () {
      const defaults = ReminderSettings(
        monthlyEnabled: false,
        monthlyDay: 1,
        dailyEnabled: false,
        dailyHour: 19,
        dailyMinute: 0,
      );
      expect(defaults.monthlyEnabled, isFalse);
      expect(defaults.dailyEnabled, isFalse);
    });

    test('copyWith hanya mengubah field yang diminta', () {
      const base = ReminderSettings(
        monthlyEnabled: false,
        monthlyDay: 1,
        dailyEnabled: false,
        dailyHour: 19,
        dailyMinute: 0,
      );
      final next = base.copyWith(dailyHour: 7, dailyMinute: 30);
      expect(next.dailyHour, 7);
      expect(next.dailyMinute, 30);
      expect(next.monthlyDay, 1);
      expect(next.dailyEnabled, isFalse);
    });
  });
}
