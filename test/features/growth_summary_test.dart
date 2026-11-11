import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/services/growth_trend_evaluator.dart';
import 'package:cekgizi/features/growth/presentation/growth_summary.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

import '../fakes.dart';

void main() {
  group('GrowthStatusSummary.worstOf', () {
    test('memilih nada paling berat (alert mengalahkan watch/good)', () {
      final measurement = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        haz: 'short',
        waz: 'very_low',
        whz: 'normal',
      );

      final summary = GrowthStatusSummary.worstOf(measurement);

      expect(summary.title, AppStrings.statusAlertTitle);
      expect(summary.body, AppStrings.statusAlertBody);
      expect(summary.action, AppStrings.statusAlertAction);
      expect(summary.tone, StatusTone.alert);
    });

    test('semua normal → nada baik', () {
      final summary = GrowthStatusSummary.worstOf(
        fakeMeasurement(id: 'm1', childId: 'c1'),
      );

      expect(summary.title, AppStrings.statusNormalTitle);
      expect(summary.tone, StatusTone.good);
    });

    test('out-of-range (status null) diperlakukan perlu perhatian', () {
      final summary = GrowthStatusSummary.worstOf(
        fakeMeasurement(id: 'm1', childId: 'c1', haz: null),
      );

      expect(summary.title, AppStrings.statusOutOfRangeTitle);
      expect(summary.tone, StatusTone.watch);
    });
  });

  group('GrowthSummary', () {
    test('latestOf mengurutkan dulu, tidak bergantung urutan input', () {
      final older = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        measuredOn: DateTime(2026, 1, 10),
      );
      final newer = fakeMeasurement(
        id: 'm2',
        childId: 'c1',
        measuredOn: DateTime(2026, 3, 10),
      );

      expect(GrowthSummary.latestOf([newer, older])?.id, 'm2');
      expect(GrowthSummary.latestOf(const []), isNull);
    });

    test('weightDeltaOf = berat terakhir − sebelumnya', () {
      final older = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        measuredOn: DateTime(2026, 1, 10),
        weightKg: 8.2,
      );
      final newer = fakeMeasurement(
        id: 'm2',
        childId: 'c1',
        measuredOn: DateTime(2026, 2, 10),
        weightKg: 8.5,
      );

      expect(
        GrowthSummary.weightDeltaOf([newer, older]),
        closeTo(0.3, 1e-9),
      );
      expect(GrowthSummary.weightDeltaOf([newer]), isNull);
    });

    test('trendOf: berat turun → needsAttention', () {
      final older = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        measuredOn: DateTime(2026, 1, 10),
        weightKg: 8.6,
      );
      final newer = fakeMeasurement(
        id: 'm2',
        childId: 'c1',
        measuredOn: DateTime(2026, 2, 10),
        weightKg: 8.4,
      );

      final result = GrowthSummary.trendOf([newer, older]);

      expect(result.trend, GrowthTrend.needsAttention);
      expect(result.reasonCode, 'weight_drop');
    });

    test('trendOf: satu data → insufficientData', () {
      final result = GrowthSummary.trendOf([
        fakeMeasurement(id: 'm1', childId: 'c1'),
      ]);

      expect(result.trend, GrowthTrend.insufficientData);
    });
  });

  group('GrowthStatusCopy helper tampilan', () {
    test('categoryLabel null → "Di luar rentang wajar"', () {
      expect(
        GrowthStatusCopy.categoryLabel(AnthropometryIndex.haz, null),
        AppStrings.statusOutOfRangeShort,
      );
    });

    test('weightDeltaLabel memakai koma dan tanda +', () {
      expect(
        GrowthStatusCopy.weightDeltaLabel(0.3),
        '+0,3 kg ${AppStrings.growthDeltaSince}',
      );
      expect(
        GrowthStatusCopy.weightDeltaLabel(-0.4),
        '−0,4 kg ${AppStrings.growthDeltaSince}',
      );
      expect(GrowthStatusCopy.weightDeltaLabel(0), AppStrings.growthDeltaSame);
    });
  });
}
