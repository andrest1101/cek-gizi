import 'package:cekgizi/features/growth/domain/services/growth_classification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GrowthClassification.haz (PRD 3.4 & 3.5)', () {
    test('sangat pendek: z < −3', () {
      expect(GrowthClassification.haz(-3.01).statusCode, 'very_short');
    });
    test('pendek: −3 s.d. < −2', () {
      expect(GrowthClassification.haz(-3.0).statusCode, 'short');
      expect(GrowthClassification.haz(-2.01).statusCode, 'short');
    });
    test('normal: −2 s.d. +3 (inklusif)', () {
      expect(GrowthClassification.haz(-2.0).statusCode, 'normal');
      expect(GrowthClassification.haz(0).statusCode, 'normal');
      expect(GrowthClassification.haz(3.0).statusCode, 'normal');
    });
    test('tinggi: z > +3', () {
      expect(GrowthClassification.haz(3.01).statusCode, 'tall');
    });
    test('z di luar ±6 → tanpa klasifikasi', () {
      expect(GrowthClassification.haz(6.01).isOutOfRange, isTrue);
      expect(GrowthClassification.haz(6.01).statusCode, isNull);
      expect(GrowthClassification.haz(-6.01).isOutOfRange, isTrue);
      expect(GrowthClassification.haz(-6.01).statusCode, isNull);
    });
  });

  group('GrowthClassification.waz (PRD 3.4 & 3.5)', () {
    test('sangat kurang: z < −3', () {
      expect(GrowthClassification.waz(-3.01).statusCode, 'very_low');
    });
    test('kurang: −3 s.d. < −2', () {
      expect(GrowthClassification.waz(-3.0).statusCode, 'low');
      expect(GrowthClassification.waz(-2.5).statusCode, 'low');
    });
    test('normal: −2 s.d. +1 (inklusif)', () {
      expect(GrowthClassification.waz(-2.0).statusCode, 'normal');
      expect(GrowthClassification.waz(1.0).statusCode, 'normal');
    });
    test('risiko berat badan lebih: z > +1', () {
      expect(GrowthClassification.waz(1.01).statusCode, 'risk_overweight');
    });
    test('z di luar −6..+5 → tanpa klasifikasi', () {
      expect(GrowthClassification.waz(-6.01).isOutOfRange, isTrue);
      expect(GrowthClassification.waz(-6.01).statusCode, isNull);
      expect(GrowthClassification.waz(5.01).isOutOfRange, isTrue);
      expect(GrowthClassification.waz(5.01).statusCode, isNull);
    });
  });

  group('GrowthClassification.whz (PRD 3.4 & 3.5)', () {
    test('gizi buruk: z < −3', () {
      expect(GrowthClassification.whz(-3.01).statusCode, 'severe_wasting');
    });
    test('gizi kurang: −3 s.d. < −2', () {
      expect(GrowthClassification.whz(-3.0).statusCode, 'wasting');
      expect(GrowthClassification.whz(-2.01).statusCode, 'wasting');
    });
    test('gizi baik: −2 s.d. +1 (inklusif)', () {
      expect(GrowthClassification.whz(-2.0).statusCode, 'normal');
      expect(GrowthClassification.whz(0).statusCode, 'normal');
      expect(GrowthClassification.whz(1.0).statusCode, 'normal');
    });
    test('berisiko gizi lebih: > +1 s.d. +2', () {
      expect(GrowthClassification.whz(1.01).statusCode, 'risk_over');
      expect(GrowthClassification.whz(2.0).statusCode, 'risk_over');
    });
    test('gizi lebih: > +2 s.d. +3', () {
      expect(GrowthClassification.whz(2.01).statusCode, 'overweight');
      expect(GrowthClassification.whz(3.0).statusCode, 'overweight');
    });
    test('obesitas: z > +3', () {
      expect(GrowthClassification.whz(3.01).statusCode, 'obese');
    });
    test('z di luar −5..+5 → tanpa klasifikasi', () {
      expect(GrowthClassification.whz(-5.01).isOutOfRange, isTrue);
      expect(GrowthClassification.whz(-5.01).statusCode, isNull);
      expect(GrowthClassification.whz(5.01).isOutOfRange, isTrue);
      expect(GrowthClassification.whz(5.01).statusCode, isNull);
    });
  });
}
