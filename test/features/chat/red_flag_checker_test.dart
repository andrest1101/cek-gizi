import 'package:cekgizi/features/chat/domain/services/red_flag_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RedFlagChecker.check (PRD 3.8)', () {
    test('emergency keywords → emergency', () {
      for (final keyword in ['kejang', 'sesak', 'tersedak', 'biru']) {
        expect(RedFlagChecker.check('anak saya $keyword tadi pagi'),
            RedFlagLevel.emergency,
            reason: keyword);
      }
    });

    test('refer_doctor keywords → referDoctor', () {
      for (final keyword in [
        'lemas',
        'tidak mau minum',
        'muntah terus',
        'diare',
        'berdarah',
        'bengkak setelah makan',
        'alergi',
        'demam',
      ]) {
        expect(RedFlagChecker.check('anak saya $keyword sejak kemarin'),
            RedFlagLevel.referDoctor,
            reason: keyword);
      }
    });

    test('case insensitive', () {
      expect(RedFlagChecker.check('Anak KEJANG'), RedFlagLevel.emergency);
      expect(RedFlagChecker.check('DIARE terus'), RedFlagLevel.referDoctor);
    });

    test('emergency menang atas refer_doctor', () {
      expect(
        RedFlagChecker.check('anak demam dan kejang'),
        RedFlagLevel.emergency,
      );
    });

    test('pesan biasa → none', () {
      expect(
        RedFlagChecker.check('ide menu MPASI untuk usia 1 tahun'),
        RedFlagLevel.none,
      );
      expect(
        RedFlagChecker.check('berapa banyak ASI untuk bayi 3 bulan?'),
        RedFlagLevel.none,
      );
    });
  });
}
