import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/services/growth_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tabel fixture PALSU untuk menguji MEKANISME (koreksi, pembagi, step).
/// Bukan nilai Permenkes asli — verifikasi terhadap tabel resmi menyusul
/// setelah berkas resmi disediakan pemilik (docs/reference-notes.md).
final class _FakeTables implements AnthropometryReferenceTables {
  double? lastLengthHeightStep;

  static const _fixture = SdColumns(
    sdNeg3: 61,
    sdNeg2: 64,
    sdNeg1: 67,
    median: 70,
    sdPos1: 73,
    sdPos2: 76,
    sdPos3: 79,
  );

  @override
  SdColumns haz({required Sex sex, required int ageMonths}) => _fixture;

  @override
  SdColumns waz({required Sex sex, required int ageMonths}) => _fixture;

  @override
  SdColumns whz({required Sex sex, required double lengthHeightCmStep}) {
    lastLengthHeightStep = lengthHeightCmStep;
    return _fixture;
  }
}

const _male = Sex.male;

void main() {
  group('GrowthEvaluator.evaluateHaz', () {
    test('koreksi 0.7 cm diterapkan sebelum evaluasi (PRD 3.2)', () {
      final tables = _FakeTables();
      // Usia 11 bln, diukur berdiri: 69.3 + 0.7 = 70.0 → tepat median → z = 0
      final result = GrowthEvaluator.evaluateHaz(
        sex: _male,
        ageMonths: 11,
        rawLengthHeightCm: 69.3,
        mode: MeasureMode.standing,
        tables: tables,
      );
      expect(result.zScore, closeTo(0, 1e-9));
      expect(result.statusCode, 'normal');
    });

    test('tanpa koreksi: 69.3 terlentang → di bawah median', () {
      final tables = _FakeTables();
      final result = GrowthEvaluator.evaluateHaz(
        sex: _male,
        ageMonths: 11,
        rawLengthHeightCm: 69.3,
        mode: MeasureMode.lying,
        tables: tables,
      );
      expect(result.zScore, closeTo((69.3 - 70) / 3, 1e-9));
    });
  });

  group('GrowthEvaluator.evaluateWaz', () {
    test('BB/U tidak terpengaruh cara ukur', () {
      final tables = _FakeTables();
      final standing = GrowthEvaluator.evaluateWaz(
        sex: _male,
        ageMonths: 11,
        weightKg: 70,
        tables: tables,
      );
      final lying = GrowthEvaluator.evaluateWaz(
        sex: _male,
        ageMonths: 11,
        weightKg: 70,
        tables: tables,
      );
      expect(standing.zScore, lying.zScore);
      expect(standing.statusCode, 'normal');
    });
  });

  group('GrowthEvaluator.evaluateWhz', () {
    test('panjang dikoreksi & dibulatkan ke step 0.5 (half-up)', () {
      final tables = _FakeTables();
      // Usia 30 bln, terlentang: 70.7 − 0.7 = 70.0 → step 70.0
      GrowthEvaluator.evaluateWhz(
        sex: _male,
        ageMonths: 30,
        rawLengthHeightCm: 70.7,
        mode: MeasureMode.lying,
        weightKg: 70,
        tables: tables,
      );
      expect(tables.lastLengthHeightStep, 70.0);
    });

    test('weight tidak dikoreksi', () {
      final tables = _FakeTables();
      final result = GrowthEvaluator.evaluateWhz(
        sex: _male,
        ageMonths: 30,
        rawLengthHeightCm: 90,
        mode: MeasureMode.standing,
        weightKg: 70,
        tables: tables,
      );
      expect(result.zScore, closeTo(0, 1e-9));
    });
  });

  group('LengthHeightStep.of', () {
    test('half-up ke kelipatan 0.5', () {
      expect(LengthHeightStep.of(35.0), 35.0);
      expect(LengthHeightStep.of(35.24), 35.0);
      expect(LengthHeightStep.of(35.25), 35.5);
      expect(LengthHeightStep.of(35.74), 35.5);
      expect(LengthHeightStep.of(35.75), 36.0);
      expect(LengthHeightStep.of(85.28), 85.5);
    });

    test('nilai tidak valid ditolak', () {
      expect(() => LengthHeightStep.of(0), throwsArgumentError);
      expect(() => LengthHeightStep.of(-1), throwsArgumentError);
    });
  });
}
