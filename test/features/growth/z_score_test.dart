import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/services/z_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sd = SdColumns(
    sdNeg3: 60,
    sdNeg2: 64,
    sdNeg1: 67, // pembagi bawah = 70 - 67 = 3
    median: 70,
    sdPos1: 73, // pembagi atas = 73 - 70 = 3
    sdPos2: 76,
    sdPos3: 79,
  );

  group('ZScore.calculate (PRD 3.3)', () {
    test('tepat di median → z = 0', () {
      expect(ZScore.calculate(value: 70, sd: sd), 0);
    });

    test('di bawah median memakai pembagi median − SD(−1)', () {
      // (64 − 70) / (70 − 67) = −2.0 (kasus: nilai kolom −2SD → z ≈ −2)
      expect(ZScore.calculate(value: 64, sd: sd), closeTo(-2.0, 1e-9));
      expect(ZScore.calculate(value: 61, sd: sd), closeTo(-3.0, 1e-9));
      expect(ZScore.calculate(value: 67, sd: sd), closeTo(-1.0, 1e-9));
    });

    test('di atas median memakai pembagi SD(+1) − median', () {
      expect(ZScore.calculate(value: 73, sd: sd), closeTo(1.0, 1e-9));
      expect(ZScore.calculate(value: 76, sd: sd), closeTo(2.0, 1e-9));
      expect(ZScore.calculate(value: 79, sd: sd), closeTo(3.0, 1e-9));
    });

    test('angka aneh tidak ditolak di sini (itu tugas §3.5 di GrowthClassification)', () {
      // Walaupun z besar, rumus tetap jalan — klasifikasi yang menolak.
      final z = ZScore.calculate(value: 0, sd: sd);
      expect(z, closeTo(-23.333, 1e-2));
    });

    test('kolom −1 tidak valid (≥ median) → InvalidReferenceDataException', () {
      const broken = SdColumns(
        sdNeg3: 60,
        sdNeg2: 64,
        sdNeg1: 70,
        median: 70,
        sdPos1: 73,
        sdPos2: 76,
        sdPos3: 79,
      );
      expect(
        () => ZScore.calculate(value: 60, sd: broken),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('kolom +1 tidak valid (≤ median) → InvalidReferenceDataException', () {
      const broken = SdColumns(
        sdNeg3: 60,
        sdNeg2: 64,
        sdNeg1: 67,
        median: 70,
        sdPos1: 70,
        sdPos2: 76,
        sdPos3: 79,
      );
      expect(
        () => ZScore.calculate(value: 75, sd: broken),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });
  });
}
