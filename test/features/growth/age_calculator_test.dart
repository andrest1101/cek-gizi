import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/growth/domain/services/age_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgeCalculator.inCompletedMonths', () {
    test('tanggal sama hari ini = usia 0 bulan', () {
      final birth = DateTime(2026, 3, 10);
      expect(
        AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 3, 10),
        ),
        0,
      );
    });

    test('bulan penuh dihitung hanya bila hari sudah lewat', () {
      final birth = DateTime(2025, 6, 20);
      expect(
        AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 1, 19),
        ),
        6,
      );
      expect(
        AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 1, 20),
        ),
        7,
      );
    });

    test('tepat 11 bulan', () {
      final birth = DateTime(2025, 1, 15);
      expect(
        AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2025, 12, 15),
        ),
        11,
      );
    });

    test('tepat 60 bulan diperbolehkan', () {
      final birth = DateTime(2021, 1, 10);
      expect(
        AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 1, 10),
        ),
        60,
      );
    });

    test('di atas 60 bulan ditolak', () {
      final birth = DateTime(2020, 6, 30);
      expect(
        () => AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 1, 10),
        ),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
    });

    test('sebelum tanggal lahir ditolak', () {
      final birth = DateTime(2026, 2, 1);
      expect(
        () => AgeCalculator.inCompletedMonths(
          birthDate: birth,
          measuredOn: DateTime(2026, 1, 31),
        ),
        throwsA(isA<InvalidMeasurementException>()),
      );
    });
  });
}
