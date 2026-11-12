import 'dart:convert';
import 'dart:io';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/domain_ref/permenkes_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/services/z_score.dart';
import 'package:flutter_test/flutter_test.dart';

/// Berkas referensi ASLI hasil ekstraksi dari PDF resmi (689 baris).
/// Dijalankan terhadap file dari disk - bukan fixture palsu.
late final PermenkesReferenceTables tables;

void main() {
  setUpAll(() {
    final contents =
        File('assets/reference/permenkes_2_2020_sd.json').readAsStringSync();
    tables = PermenkesReferenceTables.fromJsonString(contents);
  });

  group('Loader - validasi parse', () {
    test('versi referensi sesuai konfigurasi', () {
      expect(tables.version, 'permenkes-2-2020');
    });

    test('menolak JSON yang korup (median di atas semua SD)', () {
      final decoded = jsonDecode(
        File('assets/reference/permenkes_2_2020_sd.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      decoded['tables']['waz']['male'][0][3] = 99.9; // median baris 0 bln
      expect(
        () => PermenkesReferenceTables.fromJson(decoded),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });
  });

  group('Anchor resmi (diverifikasi langsung dari PDF Permenkes 2/2020)', () {
    test('waz male umur 0 bulan = [2.1, 2.5, 2.9, 3.3, 3.9, 4.4, 5.0]', () {
      final sd = tables.waz(sex: Sex.male, ageMonths: 0);
      expect(sd.sdNeg3, 2.1);
      expect(sd.sdNeg2, 2.5);
      expect(sd.sdNeg1, 2.9);
      expect(sd.median, 3.3);
      expect(sd.sdPos1, 3.9);
      expect(sd.sdPos2, 4.4);
      expect(sd.sdPos3, 5.0);
    });

    test('haz female umur 0 bulan = [43.6, 45.4, 47.3, 49.1, 51.0, 52.9, 54.7]', () {
      final sd = tables.haz(sex: Sex.female, ageMonths: 0);
      expect(sd.median, 49.1);
      expect(sd.sdNeg3, 43.6);
    });

    test('haz male umur 24 bulan memakai tabel TB/U (median 87.1)', () {
      final sd = tables.haz(sex: Sex.male, ageMonths: 24);
      expect(sd.median, 87.1);
      expect(sd.sdNeg3, 78.0);
    });

    test('sel cacat whz_tb_female 69.5: sdNeg3 null, sisanya persis dari PDF', () {
      final sd = tables.whz(sex: Sex.female, lengthHeightCmStep: 69.5, ageMonths: 30);
      expect(sd.sdNeg3, isNull);
      expect(sd.sdNeg2, 6.9);
      expect(sd.sdNeg1, 7.5);
      expect(sd.median, 8.2);
      expect(sd.sdPos1, 9.0);
      expect(sd.sdPos2, 9.9);
      expect(sd.sdPos3, 10.9);
    });
  });

  group('Anchor matematis seluruh tabel (rumus PRD 3.3)', () {
    test('z(−1 SD) = −1, z(median) = 0, z(+1 SD) = +1 - seluruh baris', () {
      void check(SdColumns sd) {
        expect(ZScore.calculate(value: sd.sdNeg1, sd: sd), closeTo(-1.0, 1e-9));
        expect(ZScore.calculate(value: sd.median, sd: sd), closeTo(0.0, 1e-9));
        expect(ZScore.calculate(value: sd.sdPos1, sd: sd), closeTo(1.0, 1e-9));
      }

      for (final sex in Sex.values) {
        for (var month = 0; month <= 60; month++) {
          check(tables.haz(sex: sex, ageMonths: month));
          check(tables.waz(sex: sex, ageMonths: month));
        }
        for (var i = 0; i < 131; i++) {
          final cm = 45.0 + i * 0.5;
          check(tables.whz(sex: sex, lengthHeightCmStep: cm, ageMonths: 11));
        }
        for (var i = 0; i < 111; i++) {
          final cm = 65.0 + i * 0.5;
          check(tables.whz(sex: sex, lengthHeightCmStep: cm, ageMonths: 30));
        }
      }
    });

    test('kolom SD monoton naik (melupakan sel null rujukan)', () {
      void check(SdColumns sd) {
        final seq = [sd.sdNeg3, sd.sdNeg2, sd.sdNeg1, sd.median, sd.sdPos1, sd.sdPos2, sd.sdPos3];
        for (var i = 0; i < seq.length - 1; i++) {
          final a = seq[i];
          final b = seq[i + 1];
          if (a == null || b == null) continue;
          expect(a < b, isTrue, reason: 'kolom $i tidak naik: $a !< $b');
        }
      }

      for (final sex in Sex.values) {
        for (var month = 0; month <= 60; month++) {
          check(tables.haz(sex: sex, ageMonths: month));
          check(tables.waz(sex: sex, ageMonths: month));
        }
        for (var i = 0; i < 131; i++) {
          check(tables.whz(sex: sex, lengthHeightCmStep: 45.0 + i * 0.5, ageMonths: 11));
        }
        for (var i = 0; i < 111; i++) {
          check(tables.whz(sex: sex, lengthHeightCmStep: 65.0 + i * 0.5, ageMonths: 30));
        }
      }
    });
  });

  group('Batas cakupan', () {
    test('haz/waz umur di luar 0–60 → exception', () {
      expect(
        () => tables.haz(sex: Sex.male, ageMonths: 61),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
      expect(
        () => tables.waz(sex: Sex.female, ageMonths: 61),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
      expect(
        () => tables.haz(sex: Sex.male, ageMonths: -1),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
    });

    test('whz PB di bawah 45 cm → exception; TB di bawah 65 cm → exception', () {
      expect(
        () => tables.whz(sex: Sex.male, lengthHeightCmStep: 44.5, ageMonths: 11),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
      expect(
        () => tables.whz(sex: Sex.male, lengthHeightCmStep: 64.5, ageMonths: 30),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
      expect(
        () => tables.whz(sex: Sex.male, lengthHeightCmStep: 120.5, ageMonths: 30),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
    });

    test('whz memilih tabel PB untuk umur <24 dan TB untuk >=24', () {
      // Usia 11 → PB (45–110); usia 30 → TB (65–120).
      expect(
        tables.whz(sex: Sex.male, lengthHeightCmStep: 45.0, ageMonths: 11).median,
        tables.whz(sex: Sex.male, lengthHeightCmStep: 45.0, ageMonths: 11).median,
      );
      expect(
        () => tables.whz(sex: Sex.male, lengthHeightCmStep: 64.0, ageMonths: 11).median,
        returnsNormally,
      );
      expect(
        () => tables.whz(sex: Sex.male, lengthHeightCmStep: 64.0, ageMonths: 30),
        throwsA(isA<OutOfSupportedRangeException>()),
      );
    });
  });
}
