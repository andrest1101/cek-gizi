import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:flutter_test/flutter_test.dart';

const _mpasiProfile = DiversityProfile(
  minAgeMonths: 6,
  maxAgeMonths: 23,
  targetGroups: 5,
  countWithoutBreastMilk: false,
);

const _balitaProfile = DiversityProfile(
  minAgeMonths: 24,
  maxAgeMonths: 59,
  targetGroups: 5,
  countWithoutBreastMilk: true,
);

void main() {
  group('DietaryDiversity.evaluate (PRD 3.7)', () {
    test('5 dari 8 kelompok = target MPASI tercapai', () {
      final summary = DietaryDiversity.evaluate(
        groupCodes: const {
          'grains_tubers',
          'flesh',
          'vit_a_fruit_veg',
          'eggs',
          'legumes_nuts',
        },
        profile: _mpasiProfile,
      );
      expect(summary.groupCount, 5);
      expect(summary.isTargetReached, isTrue);
      expect(summary.target, 5);
      expect(summary.animalProteinPresent, isTrue);
      expect(summary.missingGroups,
          {'breast_milk', 'dairy', 'other_fruit_veg'});
    });

    test('4 dari 8 kelompok = belum tercapai', () {
      final summary = DietaryDiversity.evaluate(
        groupCodes: const {
          'grains_tubers',
          'flesh',
          'eggs',
          'other_fruit_veg',
        },
        profile: _mpasiProfile,
      );
      expect(summary.groupCount, 4);
      expect(summary.isTargetReached, isFalse);
    });

    test('gabungan kelompok dari beberapa catatan (sarapan+siang+malam) = union', () {
      final sarapan = ['grains_tubers'];
      final siang = ['flesh', 'vit_a_fruit_veg'];
      final malam = ['eggs', 'grains_tubers'];
      // Lapisan data menggabungkan kelompok dari semua log hari itu:
      final union = {...sarapan, ...siang, ...malam};
      final summary = DietaryDiversity.evaluate(
        groupCodes: union,
        profile: _mpasiProfile,
      );
      expect(summary.groupCount, 4);
      expect(summary.metGroups,
          {'grains_tubers', 'flesh', 'vit_a_fruit_veg', 'eggs'});
    });

    test('profil 24–59 bulan TIDAK menghitung ASI (5 dari 7)', () {
      final summary = DietaryDiversity.evaluate(
        groupCodes: const {
          'breast_milk',
          'grains_tubers',
          'flesh',
          'eggs',
          'dairy',
        },
        profile: _balitaProfile,
      );
      // Tanpa ASI: 4 dari 7 → belum tercapai; ASI tidak dihitung target.
      expect(summary.groupCount, 4);
      expect(summary.isTargetReached, isFalse);
      expect(summary.missingGroups.contains('breast_milk'), isFalse);
    });

    test('profil 24–59 bulan dengan ASI + 4 kelompok lain = 4/7', () {
      final summary = DietaryDiversity.evaluate(
        groupCodes: const {
          'breast_milk',
          'grains_tubers',
          'flesh',
          'eggs',
          'vit_a_fruit_veg',
        },
        profile: _balitaProfile,
      );
      expect(summary.groupCount, 4);
      expect(summary.metGroups.contains('breast_milk'), isFalse);
    });

    test('protein hewani: dairy/flesh/eggs masing-masing memicu flag', () {
      for (final code in ['dairy', 'flesh', 'eggs']) {
        final summary = DietaryDiversity.evaluate(
          groupCodes: {code},
          profile: _mpasiProfile,
        );
        expect(summary.animalProteinPresent, isTrue, reason: code);
      }
      final none = DietaryDiversity.evaluate(
        groupCodes: const {'grains_tubers', 'other_fruit_veg'},
        profile: _mpasiProfile,
      );
      expect(none.animalProteinPresent, isFalse);
    });

    test('kode kelompok tidak dikenal → ArgumentError (data korup)', () {
      expect(
        () => DietaryDiversity.evaluate(
          groupCodes: const {'kode_ngasal'},
          profile: _mpasiProfile,
        ),
        throwsArgumentError,
      );
    });

    test('profilForAge memilih profil sesuai usia', () {
      const profiles = [_mpasiProfile, _balitaProfile];
      expect(DietaryDiversity.profileForAge(6, profiles), _mpasiProfile);
      expect(DietaryDiversity.profileForAge(23, profiles), _mpasiProfile);
      expect(DietaryDiversity.profileForAge(24, profiles), _balitaProfile);
      expect(DietaryDiversity.profileForAge(59, profiles), _balitaProfile);
      expect(DietaryDiversity.profileForAge(60, profiles), isNull);
    });

    test('scanner hanya untuk usia ≥ 6 bulan (PRD 3.7)', () {
      expect(DietaryDiversity.isScanSupportedForAge(5), isFalse);
      expect(DietaryDiversity.isScanSupportedForAge(6), isTrue);
      expect(DietaryDiversity.isScanSupportedForAge(24), isTrue);
    });
  });
}
