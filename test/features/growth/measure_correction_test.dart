import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/services/measure_correction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasureCorrection.corrected (PRD 3.2)', () {
    test('<24 bulan diukur berdiri → +0.7 cm', () {
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 75.0,
          mode: MeasureMode.standing,
          ageMonths: 11,
        ),
        closeTo(75.7, 1e-9),
      );
    });

    test('<24 bulan diukur terlentang → tanpa koreksi', () {
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 75.0,
          mode: MeasureMode.lying,
          ageMonths: 11,
        ),
        75.0,
      );
    });

    test('>=24 bulan diukur terlentang → -0.7 cm', () {
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 91.0,
          mode: MeasureMode.lying,
          ageMonths: 30,
        ),
        closeTo(90.3, 1e-9),
      );
    });

    test('>=24 bulan diukur berdiri → tanpa koreksi', () {
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 91.0,
          mode: MeasureMode.standing,
          ageMonths: 30,
        ),
        91.0,
      );
    });

    test('batas 23 bulan masih pakai aturan balita; 24 bulan sebaliknya', () {
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 90.0,
          mode: MeasureMode.standing,
          ageMonths: 23,
        ),
        closeTo(90.7, 1e-9),
      );
      expect(
        MeasureCorrection.corrected(
          lengthHeightCm: 90.0,
          mode: MeasureMode.standing,
          ageMonths: 24,
        ),
        90.0,
      );
    });
  });
}
