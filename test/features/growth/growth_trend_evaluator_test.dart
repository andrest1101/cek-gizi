import 'package:cekgizi/features/growth/domain/entities/growth_measurement_point.dart';
import 'package:cekgizi/features/growth/domain/services/growth_trend_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

GrowthMeasurementPoint _point(
  String date,
  double weightKg, {
  String? haz,
}) =>
    GrowthMeasurementPoint(
      measuredOn: DateTime.parse(date),
      weightKg: weightKg,
      hazStatusCode: haz,
    );

void main() {
  group('GrowthTrendEvaluator (PRD 3.6)', () {
    test('kurang dari 2 pengukuran → insufficientData', () {
      expect(
        GrowthTrendEvaluator.evaluate([_point('2026-01-05', 7.4)]).trend,
        GrowthTrend.insufficientData,
      );
      expect(
        GrowthTrendEvaluator.evaluate([]).trend,
        GrowthTrend.insufficientData,
      );
    });

    test('berat turun → needsAttention/weight_drop', () {
      final result = GrowthTrendEvaluator.evaluate([
        _point('2026-01-05', 7.4, haz: 'normal'),
        _point('2026-02-05', 7.1, haz: 'normal'),
      ]);
      expect(result.trend, GrowthTrend.needsAttention);
      expect(result.reasonCode, 'weight_drop');
    });

    test('kategori HAZ memburuk → needsAttention/haz_worsened', () {
      final result = GrowthTrendEvaluator.evaluate([
        _point('2026-01-05', 7.0, haz: 'normal'),
        _point('2026-02-05', 7.6, haz: 'short'),
      ]);
      expect(result.trend, GrowthTrend.needsAttention);
      expect(result.reasonCode, 'haz_worsened');
    });

    test('naik → tracked', () {
      final result = GrowthTrendEvaluator.evaluate([
        _point('2026-01-05', 7.4, haz: 'normal'),
        _point('2026-02-05', 7.9, haz: 'normal'),
      ]);
      expect(result.trend, GrowthTrend.tracked);
    });

    test('urutan input tidak terurut pun diurutkan dulu', () {
      final result = GrowthTrendEvaluator.evaluate([
        _point('2026-02-05', 7.1, haz: 'normal'),
        _point('2026-01-05', 7.4, haz: 'normal'),
      ]);
      expect(result.trend, GrowthTrend.needsAttention);
      expect(result.reasonCode, 'weight_drop');
    });

    test('HAZ membaik bukan kebutuhan perhatian', () {
      final result = GrowthTrendEvaluator.evaluate([
        _point('2026-01-05', 7.1, haz: 'short'),
        _point('2026-02-05', 7.4, haz: 'normal'),
      ]);
      expect(result.trend, GrowthTrend.tracked);
    });
  });
}
