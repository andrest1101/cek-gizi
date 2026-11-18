import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';

void main() {
  group('Copy UI tidak memakai glyph ambigu', () {
    test('teks antarmuka tidak memiliki mojibake umum', () {
      const uiCopy = [
        AppStrings.childBirthDateHint,
        AppStrings.growthLegendLimit,
        AppStrings.validationAgeRange,
        AppStrings.tanyaInputHint,
        AppStrings.hazLabel,
        AppStrings.whzLabel,
      ];
      for (final copy in uiCopy) {
        expect(copy, isNot(contains('Ã')));
        expect(copy, isNot(contains('Â')));
        expect(copy, isNot(contains('â')));
        expect(copy, isNot(contains('\uFFFD')));
      }
    });

    test('legenda batas grafik memakai teks yang jelas', () {
      expect(AppStrings.growthLegendLimit, 'Ambang -2 dan +2 SD');
      expect(AppStrings.growthLegendLimit, isNot(contains('±')));
    });

    test('hint input Tanya memakai elipsis ASCII yang didukung luas', () {
      expect(AppStrings.tanyaInputHint, 'Tulis pertanyaan...');
      expect(AppStrings.tanyaInputHint, isNot(contains('…')));
    });

    test('label rentang pertumbuhan tidak bergantung pada en dash', () {
      expect(AppStrings.childBirthDateHint, 'Usia 0 sampai 60 bulan.');
      expect(AppStrings.validationAgeRange, contains('0 sampai 60 bulan'));
      expect(AppStrings.hazLabel, 'PB/U atau TB/U');
      expect(AppStrings.whzLabel, 'BB/PB atau BB/TB');
    });
  });
}
