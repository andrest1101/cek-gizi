import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/presentation/widgets/chart_point_info.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

import '../../fakes.dart';

void main() {
  final measurement = fakeMeasurement(
    id: 'm1',
    childId: 'c1',
    weightKg: 9.0,
    lengthHeightCm: 75.0,
    ageMonths: 12,
  );

  test('info titik HAZ memakai tinggi badan & satuan cm', () {
    final info = ChartPointInfo.from(
      measurement: measurement,
      index: AnthropometryIndex.haz,
      median: 74.0,
    );
    expect(info.valueLabel, '75,0 cm');
    expect(info.ageLabel, AppStrings.growthPointAgeValue(12));
    expect(info.zLabel, '0,50');
    expect(info.medianLabel, contains(AppStrings.growthPointMedianAbove));
    expect(info.tone, StatusTone.good);
    expect(info.semanticsLabel, contains(AppStrings.growthPointTitle));
  });

  test('info titik WAZ memakai berat & satuan kg; di bawah median', () {
    final info = ChartPointInfo.from(
      measurement: measurement,
      index: AnthropometryIndex.waz,
      median: 10.0,
    );
    expect(info.valueLabel, '9,0 kg');
    expect(info.medianLabel, contains(AppStrings.growthPointMedianBelow));
  });

  test('selisih kecil dianggap sesuai median', () {
    final info = ChartPointInfo.from(
      measurement: measurement,
      index: AnthropometryIndex.waz,
      median: 9.01,
    );
    expect(info.medianLabel, contains(AppStrings.growthPointMedianEqual));
  });
}
