import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/recipes/data/models/recipe_model.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';

Map<String, dynamic> _base({String id = 'bubur-uji'}) => {
  'id': id,
  'title': 'Bubur Uji',
  'age_band': '6-8',
  'minutes': 30,
  'ingredients': [
    {'name': 'Beras putih', 'amount': '2 sdm'},
  ],
  'steps': ['Masak sampai lunak.'],
  'groups': ['grains_tubers', 'flesh'],
  'animal_protein': true,
  'texture_note': 'Lumat dan kental.',
  'allergen_note': '',
  'reviewed_by': null,
  'reviewed_on': null,
};

String _encode(List<Map<String, dynamic>> items) => jsonEncode(items);

void main() {
  group('RecipeCatalogLoader - berkas valid', () {
    test('mengurai resep lengkap dan mengurutkan kelompok canonical', () {
      final recipes = RecipeCatalogLoader.fromJsonString(_encode([_base()]));
      expect(recipes, hasLength(1));
      final recipe = recipes.single;
      expect(recipe.id, 'bubur-uji');
      expect(recipe.ageBand, RecipeAgeBand.months6to8);
      expect(recipe.minutes, 30);
      expect(recipe.groups, ['grains_tubers', 'flesh']);
      expect(recipe.animalProtein, isTrue);
      expect(recipe.isReviewed, isFalse);
      expect(recipe.hasAllergenNote, isFalse);
      expect(recipe.ingredients.single.amount, '2 sdm');
    });

    test('reviewed_by terisi menandai sudah ditinjau', () {
      final item = _base()
        ..['reviewed_by'] = 'Bidan Uji'
        ..['reviewed_on'] = '2026-11-23';
      final recipe = RecipeCatalogLoader.fromJsonString(_encode([item])).single;
      expect(recipe.isReviewed, isTrue);
      expect(recipe.reviewedBy, 'Bidan Uji');
    });

    test('allergen_note boleh kosong', () {
      final recipe = RecipeCatalogLoader.fromJsonString(
        _encode([_base()]),
      ).single;
      expect(recipe.allergenNote, '');
    });

    test('banyak resep diurutkan stabil (rentang lalu judul)', () {
      final a = _base(id: 'resep-a')
        ..['title'] = 'Zebra'
        ..['age_band'] = '24+'
        ..['groups'] = ['grains_tubers']
        ..['animal_protein'] = false;
      final b = _base(id: 'resep-b')..['title'] = 'Apel';
      final recipes = RecipeCatalogLoader.fromJsonString(_encode([a, b]));
      expect(recipes.map((r) => r.id), orderedEquals(['resep-b', 'resep-a']));
    });
  });

  group('RecipeCatalogLoader - menolak berkas korup', () {
    void expectInvalid(String contents) {
      expect(
        () => RecipeCatalogLoader.fromJsonString(contents),
        throwsA(isA<InvalidReferenceDataException>()),
      );
    }

    test('akar bukan array', () => expectInvalid('{"id":"x"}'));
    test('katalog kosong', () => expectInvalid('[]'));
    test('item bukan objek', () => expectInvalid('[1,2]'));

    test('id duplikat', () {
      expectInvalid(_encode([_base(), _base()]));
    });

    test('id bukan slug', () {
      expectInvalid(_encode([_base(id: 'Bubur Uji!')]));
    });

    test('age_band tidak dikenal', () {
      expectInvalid(_encode([_base()..['age_band'] = '0-6']));
    });

    test('title hilang', () {
      final item = _base()..remove('title');
      expectInvalid(_encode([item]));
    });

    test('minutes nol', () {
      expectInvalid(_encode([_base()..['minutes'] = 0]));
    });

    test('minutes bukan bilangan bulat', () {
      expectInvalid(_encode([_base()..['minutes'] = '30']));
    });

    test('ingredients kosong', () {
      expectInvalid(_encode([_base()..['ingredients'] = []]));
    });

    test('bahan tanpa amount', () {
      expectInvalid(
        _encode([
          _base()
            ..['ingredients'] = [
              {'name': 'Beras'},
            ],
        ]),
      );
    });

    test('steps kosong', () {
      expectInvalid(_encode([_base()..['steps'] = []]));
    });

    test('kode kelompok tidak dikenal', () {
      expectInvalid(
        _encode([
          _base()..['groups'] = ['sayur_hijau'],
        ]),
      );
    });

    test('kelompok duplikat', () {
      expectInvalid(
        _encode([
          _base()..['groups'] = ['flesh', 'flesh'],
        ]),
      );
    });

    test('animal_protein tidak cocok dengan kelompok', () {
      expectInvalid(
        _encode([
          _base()
            ..['groups'] = ['grains_tubers']
            ..['animal_protein'] = true,
        ]),
      );
    });

    test('animal_protein bukan boolean', () {
      expectInvalid(_encode([_base()..['animal_protein'] = 'yes']));
    });

    test('texture_note kosong', () {
      expectInvalid(_encode([_base()..['texture_note'] = '  ']));
    });

    test('reviewed_by bukan string', () {
      expectInvalid(_encode([_base()..['reviewed_by'] = 123]));
    });
  });
}
