import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/services/z_score.dart';
import 'package:flutter_test/flutter_test.dart';

/// 30 kasus manual: ekspektasi z dihitung dari angka tabel resmi
/// (`assets/reference/permenkes_2_2020_sd.json`) dengan rumus PRD §3.3,
/// nilai X dibulatkan 0,1 (mengikuti nilai yang diinput pengguna).
/// Kolom −1, median, +1 dikutip persis dari berkas resminya.
final _cases = <(String, double, double, double, double, double)>[
  ('HAZ male 3 bln (pb_u)', 56.8, 59.4, 61.4, 63.5, -2.3),
  ('HAZ male 11 bln (pb_u)', 79.1, 72.2, 74.5, 76.9, 1.91667),
  ('HAZ male 18 bln (pb_u)', 76.1, 79.6, 82.3, 85.0, -2.29630),
  ('HAZ male 24 bln (tb_u)', 80.2, 84.1, 87.1, 90.2, -2.3),
  ('HAZ male 38 bln (tb_u)', 104.6, 93.6, 97.4, 101.2, 1.89474),
  ('HAZ male 51 bln (tb_u)', 95.1, 100.7, 105.0, 109.3, -2.30233),
  ('HAZ female 6 bln (pb_u)', 60.6, 63.5, 65.7, 68.0, -2.31818),
  ('HAZ female 15 bln (pb_u)', 82.6, 74.8, 77.5, 80.2, 1.88889),
  ('HAZ female 21 bln (pb_u)', 76.6, 80.6, 83.7, 86.7, -2.29032),
  ('HAZ female 27 bln (tb_u)', 80.5, 84.9, 88.3, 91.7, -2.29412),
  ('HAZ female 44 bln (tb_u)', 108.3, 96.2, 100.3, 104.5, 1.90476),
  ('HAZ female 60 bln (tb_u)', 98.6, 104.7, 109.4, 114.2, -2.29787),
  ('WAZ male 0 bln', 2.6, 2.9, 3.3, 3.9, -1.75),
  ('WAZ male 8 bln', 10.8, 7.7, 8.6, 9.6, 2.2),
  ('WAZ male 16 bln', 8.7, 9.4, 10.5, 11.7, -1.63636),
  ('WAZ male 33 bln', 17.8, 12.3, 13.8, 15.6, 2.22222),
  ('WAZ female 5 bln', 5.6, 6.1, 6.9, 7.8, -1.625),
  ('WAZ female 22 bln', 14.2, 9.8, 11.1, 12.5, 2.21429),
  ('WAZ female 41 bln', 11.8, 13.0, 14.8, 16.9, -1.66667),
  ('WAZ female 55 bln', 23.5, 15.1, 17.3, 20.1, 2.21429),
  ('WHZ male 48.5 cm (pb)', 2.7, 2.8, 3.0, 3.3, -1.5),
  ('WHZ male 63.0 cm (pb)', 7.6, 6.2, 6.8, 7.4, 1.33333),
  ('WHZ male 78.5 cm (pb)', 9.0, 9.4, 10.2, 11.1, -1.5),
  ('WHZ female 55.0 cm (pb)', 4.1, 4.2, 4.5, 5.0, -1.33333),
  ('WHZ female 71.0 cm (pb)', 9.5, 7.7, 8.4, 9.2, 1.375),
  ('WHZ female 84.0 cm (pb)', 9.7, 10.1, 11.0, 12.0, -1.44444),
  ('WHZ male 75.0 cm (tb)', 8.6, 8.9, 9.6, 10.5, -1.42857),
  ('WHZ male 91.5 cm (tb)', 14.8, 12.2, 13.2, 14.4, 1.33333),
  ('WHZ male 108.0 cm (tb)', 15.8, 16.4, 17.8, 19.5, -1.42857),
  ('WHZ female 97.0 cm (tb)', 12.7, 13.2, 14.4, 15.8, -1.41667),
];

void main() {
  group('30 kasus manual vs tabel resmi (selisih ≤ 0.01, PRD §9.2)', () {
    for (final (label, value, sdNeg1, median, sdPos1, expected) in _cases) {
      test(label, () {
        final sd = SdColumns(sdNeg1: sdNeg1, median: median, sdPos1: sdPos1);
        expect(
          ZScore.calculate(value: value, sd: sd),
          closeTo(expected, 0.01),
        );
      });
    }

    test('30 kasus ter-parse semua', () {
      expect(_cases.length, 30);
    });
  });
}
