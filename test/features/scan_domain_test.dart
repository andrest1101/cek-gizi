import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

Map<String, dynamic> _valid() => {
      'request_id': 'req-123',
      'is_food': true,
      'image_quality': 'ok',
      'items': [
        {
          'name': 'Bubur nasi',
          'groups': ['grains_tubers'],
          'confidence': 0.9,
        },
      ],
      'notes': null,
    };

void main() {
  group('MealScanResult.fromJson', () {
    test('parse hasil valid', () {
      final result = MealScanResult.fromJson(_valid());
      expect(result.requestId, 'req-123');
      expect(result.isFood, isTrue);
      expect(result.imageQuality, MealScanImageQuality.ok);
      expect(result.items.single.name, 'Bubur nasi');
      expect(result.items.single.groups, ['grains_tubers']);
      expect(result.items.single.confidence, 0.9);
    });

    test('nama item dipotong di 40 karakter', () {
      final json = _valid();
      (json['items'] as List).first['name'] = 'a' * 50;
      final result = MealScanResult.fromJson(json);
      expect(result.items.single.name.length, 40);
    });

    test('kelompok tak dikenal dibuang, bukan dibiarkan', () {
      final json = _valid();
      (json['items'] as List).first['groups'] = ['grains_tubers', 'wakadoodle'];
      final result = MealScanResult.fromJson(json);
      expect(result.items.single.groups, ['grains_tubers']);
    });

    test('item berisi hanya kelompok tak dikenal ditolak', () {
      final json = _valid();
      (json['items'] as List).first['groups'] = ['wakadoodle'];
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('lebih dari 12 item ditolak', () {
      final json = _valid();
      json['items'] = [
        for (var i = 0; i < 13; i++)
          {
            'name': 'Item $i',
            'groups': ['eggs'],
            'confidence': 0.5,
          },
      ];
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('confidence di luar 0..1 ditolak', () {
      final json = _valid();
      (json['items'] as List).first['confidence'] = 1.5;
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('request_id kosong ditolak', () {
      final json = _valid()..['request_id'] = '   ';
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('image_quality tidak dikenal ditolak', () {
      final json = _valid()..['image_quality'] = 'soggy';
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('is_food bukan bool ditolak', () {
      final json = _valid()..['is_food'] = 'true';
      expect(
        () => MealScanResult.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('image_quality no_food dikenali', () {
      final json = _valid()..['image_quality'] = 'no_food';
      final result = MealScanResult.fromJson(json);
      expect(result.imageQuality, MealScanImageQuality.noFood);
    });
  });

  test('semua kode kelompok valid untuk scan', () {
    expect(FoodGroup.allCodes.length, 8);
  });
}
