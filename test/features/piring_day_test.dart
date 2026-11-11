import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

import '../fakes.dart';

void main() {
  final today = DateTime(2026, 11, 11, 12);
  final earlier = DateTime(2026, 11, 10, 18);

  List<DiversityProfile> profiles() => const [
        DiversityProfile(
          minAgeMonths: 6,
          maxAgeMonths: 23,
          targetGroups: 5,
          countWithoutBreastMilk: false,
        ),
        DiversityProfile(
          minAgeMonths: 24,
          maxAgeMonths: 59,
          targetGroups: 5,
          countWithoutBreastMilk: true,
        ),
      ];

  group('PiringDayEvaluator.evaluate', () {
    test('hanya catatan hari ini yang dihitung; urut naik', () {
      final logs = [
        fakeFoodLog(
          id: 'y1',
          childId: 'c',
          eatenAt: earlier,
          groups: const ['other_fruit_veg'],
        ),
        fakeFoodLog(
          id: 't1',
          childId: 'c',
          eatenAt: today.subtract(const Duration(hours: 5)),
          groups: const ['grains_tubers'],
        ),
        fakeFoodLog(
          id: 't2',
          childId: 'c',
          eatenAt: today.subtract(const Duration(hours: 1)),
          groups: const ['eggs', 'flesh'],
        ),
      ];

      final piring = PiringDayEvaluator.evaluate(
        logs: logs,
        today: today,
        ageMonths: 11,
        profiles: profiles(),
      );

      expect(piring.groups, {'grains_tubers', 'eggs', 'flesh'});
      expect(piring.logs.map((l) => l.id), ['t1', 't2']);
      expect(piring.metCount, 3);
      expect(piring.isTargetReached, isFalse);
      expect(piring.animalProteinPresent, isTrue);
    });

    test('target tercapai saat 5 kelompok (6–23 bln, ASI dihitung)', () {
      final logs = [
        for (final group in [
          'breast_milk',
          'grains_tubers',
          'legumes_nuts',
          'eggs',
          'flesh',
        ])
          fakeFoodLog(id: 'log-$group', childId: 'c', eatenAt: today, groups: [group]),
      ];

      final piring = PiringDayEvaluator.evaluate(
        logs: logs,
        today: today,
        ageMonths: 11,
        profiles: profiles(),
      );

      expect(piring.metCount, 5);
      expect(piring.isTargetReached, isTrue);
      expect(piring.diversity!.missingGroups, contains('dairy'));
    });

    test('balita 24–59 bln: ASI tidak dihitung menuju target 5/7', () {
      final logs = [
        for (final group in [
          'breast_milk',
          'grains_tubers',
          'legumes_nuts',
          'eggs',
          'flesh',
        ])
          fakeFoodLog(id: 'log-$group', childId: 'c', eatenAt: today, groups: [group]),
      ];

      final piring = PiringDayEvaluator.evaluate(
        logs: logs,
        today: today,
        ageMonths: 30,
        profiles: profiles(),
      );

      // Union 5 kelompok (termasuk ASI) tapi yang dihitung tanpa ASI = 4 → belum capai.
      expect(piring.groups.length, 5);
      expect(piring.diversity!.groupCount, 4);
      expect(piring.isTargetReached, isFalse);
    });

    test('profil tidak cocok (mis. 60 bulan) → diversity null', () {
      final piring = PiringDayEvaluator.evaluate(
        logs: const [],
        today: today,
        ageMonths: 60,
        profiles: profiles(),
      );

      expect(piring.diversity, isNull);
      expect(piring.profile, isNull);
      expect(piring.metCount, 0);
    });
  });

  group('PiringDayEvaluator.byDay', () {
    test('mengelompokkan per hari, terbaru dulu', () {
      final logs = [
        fakeFoodLog(id: 'a', childId: 'c', eatenAt: earlier, groups: const ['grains_tubers']),
        fakeFoodLog(id: 'b', childId: 'c', eatenAt: today, groups: const ['eggs']),
        fakeFoodLog(id: 'c', childId: 'c', eatenAt: today.add(const Duration(hours: 1)), groups: const ['dairy']),
      ];

      final days = PiringDayEvaluator.byDay(logs);

      expect(days, hasLength(2));
      expect(days.first.day, DateTime(today.year, today.month, today.day));
      expect(days.first.logs.map((l) => l.id), ['c', 'b']);
      expect(days.last.day, DateTime(earlier.year, earlier.month, earlier.day));
    });
  });

  group('PiringDayEvaluator.canonicalOrder', () {
    test('urut sesuai acuan tetap', () {
      expect(
        PiringDayEvaluator.canonicalOrder(const ['eggs', 'breast_milk', 'dairy']),
        ['breast_milk', 'dairy', 'eggs'],
      );
    });

    test('mengabaikan yang tidak dikenal tanpa melempar', () {
      expect(
        () => PiringDayEvaluator.canonicalOrder(const ['unknown_code']),
        returnsNormally,
      );
      expect(
        PiringDayEvaluator.canonicalOrder(const ['unknown_code']),
        isEmpty,
      );
    });
  });
}
