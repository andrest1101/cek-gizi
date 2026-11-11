import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/presentation/chart/sd_series.dart';

import '../fakes.dart';

void main() {
  const tables = FakeAnthropometryTables();

  group('SdSeriesBuilder', () {
    test('HAZ: 0–60 bulan, pita atas +3 SD, tanpa pita luar', () {
      final series = SdSeriesBuilder.build(
        index: AnthropometryIndex.haz,
        sex: Sex.male,
        useTbTable: false,
        tables: tables,
      );

      expect(series.neg3, hasLength(61));
      expect(series.neg3.first, (x: 0.0, y: 55.0));
      expect(series.neg2.first.y, 62);
      expect(series.upper.first.y, 94); // +3 SD
      expect(series.outerUpper, isEmpty);
      expect(series.median.first.y, 75);
      expect(series.minX, 0);
      expect(series.maxX, 60);
      expect(series.xInterval, 12);
      expect(series.upperIsPos3, isTrue);
      expect(series.minY, 54); // −3 SD − 1
      expect(series.maxY, 95); // +3 SD + 1
    });

    test('WAZ: pita atas +1 SD, pita luar +3 SD', () {
      final series = SdSeriesBuilder.build(
        index: AnthropometryIndex.waz,
        sex: Sex.female,
        useTbTable: false,
        tables: tables,
      );

      expect(series.upper.first.y, 11);
      expect(series.outerUpper.first.y, 15);
      expect(series.upperIsPos3, isFalse);
      expect(series.minY, 1);
      expect(series.maxY, 16);
    });

    test('WHZ: rentang tabel 45–110 cm langkah 0,5', () {
      final series = SdSeriesBuilder.build(
        index: AnthropometryIndex.whz,
        sex: Sex.male,
        useTbTable: false,
        tables: tables,
      );

      expect(series.median, hasLength(131));
      expect(series.minX, 45);
      expect(series.maxX, 110);
      expect(series.xInterval, 10);
    });
  });

  group('GrowthMeasurementChartPoint', () {
    test('HAZ memakai tinggi terkoreksi (berdiri < 24 bulan → +0,7)', () {
      final lying = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        ageMonths: 11,
        lengthHeightCm: 72,
      );
      final standing = fakeMeasurement(
        id: 'm2',
        childId: 'c1',
        ageMonths: 11,
        lengthHeightCm: 72,
        measureMode: MeasureMode.standing,
      );

      expect(lying.chartY(AnthropometryIndex.haz), 72);
      expect(standing.chartY(AnthropometryIndex.haz), 72 + 0.7);
      expect(standing.chartX(AnthropometryIndex.haz), 11);
    });

    test('BB/TB: x = panjang terkoreksi, y = berat', () {
      final measurement = fakeMeasurement(
        id: 'm1',
        childId: 'c1',
        measureMode: MeasureMode.lying,
        ageMonths: 30,
        lengthHeightCm: 90,
        weightKg: 12.5,
      );

      expect(measurement.chartX(AnthropometryIndex.whz), 90 - 0.7);
      expect(measurement.chartY(AnthropometryIndex.whz), 12.5);
    });
  });
}
