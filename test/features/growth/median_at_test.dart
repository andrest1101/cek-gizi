import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/growth/presentation/chart/sd_series.dart';

void main() {
  final points = <SdPoint>[(x: 0, y: 50), (x: 12, y: 70), (x: 24, y: 80)];

  test('medianAt: titik tepat dikembalikan apa adanya', () {
    expect(medianAt(points, 12), 70);
  });

  test('medianAt: interpolasi linear di antara dua titik', () {
    expect(medianAt(points, 6), closeTo(60, 1e-9));
    expect(medianAt(points, 18), closeTo(75, 1e-9));
  });

  test('medianAt: di luar rentang pakai titik ujung', () {
    expect(medianAt(points, -5), 50);
    expect(medianAt(points, 60), 80);
  });

  test('medianAt: list kosong → NaN', () {
    expect(medianAt(const [], 1).isNaN, isTrue);
  });
}
