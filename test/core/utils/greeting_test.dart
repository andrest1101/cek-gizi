import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/utils/greeting.dart';

void main() {
  group('Greeting.of', () {
    test('pagi: 00.00–10.59', () {
      expect(Greeting.of(DateTime(2026, 11, 11, 0, 0)), AppStrings.greetingMorning);
      expect(Greeting.of(DateTime(2026, 11, 11, 10, 59)), AppStrings.greetingMorning);
    });

    test('siang: 11.00–14.59', () {
      expect(Greeting.of(DateTime(2026, 11, 11, 11, 0)), AppStrings.greetingNoon);
      expect(Greeting.of(DateTime(2026, 11, 11, 14, 59)), AppStrings.greetingNoon);
    });

    test('sore: 15.00–17.59', () {
      expect(Greeting.of(DateTime(2026, 11, 11, 15, 0)), AppStrings.greetingEvening);
      expect(Greeting.of(DateTime(2026, 11, 11, 17, 59)), AppStrings.greetingEvening);
    });

    test('malam: 18.00–23.59', () {
      expect(Greeting.of(DateTime(2026, 11, 11, 18, 0)), AppStrings.greetingNight);
      expect(Greeting.of(DateTime(2026, 11, 11, 23, 59)), AppStrings.greetingNight);
    });
  });
}
