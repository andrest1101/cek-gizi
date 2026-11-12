import 'dart:convert';
import 'dart:io';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/domain_ref/nutrition_rules.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _decoded() =>
    jsonDecode(File('assets/rules/nutrition_rules.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('Loader — berkas seed proyek (assets/rules/nutrition_rules.json)', () {
    late NutritionRules rules;

    setUpAll(() {
      rules = NutritionRulesLoader.fromJsonString(
        File('assets/rules/nutrition_rules.json').readAsStringSync(),
      );
    });

    test('version = 1, groups persis 8 kode PRD', () {
      expect(rules.version, '1');
      expect(rules.groups, FoodGroup.allCodes.toSet());
    });

    test('animal_source persis [dairy, flesh, eggs]', () {
      expect(rules.animalSource, {'dairy', 'flesh', 'eggs'});
    });

    test('tanpa tumpang tindih, urut menurut usia', () {
      expect(rules.profiles.length, 2);
      expect(rules.profiles[0].minAgeMonths, lessThanOrEqualTo(rules.profiles[1].minAgeMonths));
    });

    test('profil mpasi_6_23 sesuai lampiran A PRD', () {
      final mpasi = rules.profileForAge(11)!;
      expect(mpasi.minAgeMonths, 6);
      expect(mpasi.maxAgeMonths, 23);
      expect(mpasi.targetGroups, 5);
      expect(mpasi.countWithoutBreastMilk, isFalse);
    });

    test('profil balita_24_59 sesuai lampiran A PRD', () {
      final balita = rules.profileForAge(30)!;
      expect(balita.minAgeMonths, 24);
      expect(balita.maxAgeMonths, 59);
      expect(balita.targetGroups, 5);
      expect(balita.countWithoutBreastMilk, isTrue);
    });

    test('isReviewed false — konten belum ditinjau ahli gizi (PRD 9.1)', () {
      expect(rules.isReviewed, isFalse);
      expect(rules.reviewedBy, isNull);
      expect(rules.reviewedOn, isNull);
    });

    test('tips kunci valid & tipsForMissing mengembalikan tips terurut', () {
      expect(rules.tips.length, 7);
      for (final key in rules.tips.keys) {
        expect(FoodGroup.fromCode(key), isNotNull);
      }
      final tips = rules.tipsForMissing({'flesh', 'other_fruit_veg', 'dairy'});
      expect(tips.length, 3);
      expect(tips.join(), contains('hati')); // tips flesh (urut kode groups)
    });

    test('semua tips seed wajar: ≤140 karakter, satu baris', () {
      for (final entry in rules.tips.entries) {
        expect(
          entry.value.length,
          lessThanOrEqualTo(NutritionRulesLoader.maxTipLength),
          reason: 'tips "${entry.key}" kepanjangan / korup',
        );
        expect(entry.value, isNot(contains('\n')));
      }
      // Regresi: tips makanan pokok pernah tersisipi lirik lagu.
      expect(rules.tips['grains_tubers'], isNot(contains('Sometimes')));
      expect(rules.tips['grains_tubers'], contains('nasi'));
    });

    test('missingCodesWithTips mengembalikan kode, bukan teks bebas', () {
      expect(
        rules.missingCodesWithTips({'flesh', 'dairy'}),
        ['dairy', 'flesh'],
      );
      expect(rules.tipFor('flesh'), contains('hati'));
      expect(rules.tipFor('breast_milk'), isNull);
    });

    test('integrasi DietaryDiversity: pemilihan profil + evaluasi', () {
      final rules = NutritionRulesLoader.fromJsonString(
        File('assets/rules/nutrition_rules.json').readAsStringSync(),
      );
      expect(DietaryDiversity.profileForAge(5, rules.profiles), isNull);
      expect(DietaryDiversity.profileForAge(6, rules.profiles),
          isA<DiversityProfile>());
      expect(DietaryDiversity.profileForAge(23, rules.profiles)!.maxAgeMonths,
          23);
      expect(DietaryDiversity.profileForAge(24, rules.profiles)!.minAgeMonths,
          24);
      expect(DietaryDiversity.profileForAge(59, rules.profiles),
          isA<DiversityProfile>());
      expect(DietaryDiversity.profileForAge(60, rules.profiles), isNull);

      final summary = DietaryDiversity.evaluate(
        groupCodes: const {
          'grains_tubers',
          'flesh',
          'vit_a_fruit_veg',
          'eggs',
          'legumes_nuts',
        },
        profile: rules.profileForAge(11)!,
      );
      expect(summary.isTargetReached, isTrue);
      expect(summary.animalProteinPresent, isTrue);
    });
  });

  group('Loader — penolakan berkas korup (tidak boleh lolos)', () {
    test('version hilang', () {
      final json = _decoded()..remove('version');
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('groups kurang dari 8', () {
      final json = _decoded();
      (json['groups'] as List).removeLast();
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('groups berisi kode tak dikenal', () {
      final json = _decoded();
      (json['groups'] as List)[0] = 'kode_ngasal';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('groups duplikat sehingga bukan persis 8 unik', () {
      final json = _decoded();
      (json['groups'] as List)[7] = 'eggs';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('animal_source kosong', () {
      final json = _decoded()..['animal_source'] = <String>[];
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('animal_source berisi kode yang bukan kelompok protein hewani', () {
      final json = _decoded()..['animal_source'] = ['dairy', 'flesh', 'grains_tubers'];
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('target_groups di luar 1–8', () {
      final json = _decoded();
      json['profiles']['mpasi_6_23']['target_groups'] = 9;
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('target_groups melebihi semesta tanpa ASI (>7)', () {
      final json = _decoded();
      json['profiles']['balita_24_59']['target_groups'] = 8;
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('count bukan all / without_breast_milk', () {
      final json = _decoded();
      json['profiles']['mpasi_6_23']['count'] = 'bogus';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('rentang usia min > max', () {
      final json = _decoded();
      json['profiles']['mpasi_6_23']['min_age_months'] = 30;
      json['profiles']['mpasi_6_23']['max_age_months'] = 20;
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('profil tumpang tindih', () {
      final json = _decoded();
      (json['profiles'] as Map)['mpasi_duplikat'] = {
        'min_age_months': 6,
        'max_age_months': 23,
        'target_groups': 5,
        'count': 'all',
      };
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('tips kunci kode kelompok tidak dikenal', () {
      final json = _decoded();
      json['tips']['makanan_gaib'] = 'tip ngasal';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('tips nilai kosong', () {
      final json = _decoded();
      json['tips']['flesh'] = '   ';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('tips terlalu panjang (indikasi teks korup) ditolak', () {
      final json = _decoded();
      json['tips']['grains_tubers'] =
          'Pastikan ada ${'lirik tersisip ' * 12}makanan pokok.';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('tips berisi baris baru ditolak', () {
      final json = _decoded();
      json['tips']['flesh'] = 'Baris pertama.\nBaris kedua.';
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });

    test('reviewed_by bukan string', () {
      final json = _decoded()..['reviewed_by'] = 123;
      expect(
        () => NutritionRulesLoader.fromJson(json),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    });
  });
}
