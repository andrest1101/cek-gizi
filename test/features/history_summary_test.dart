import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';

const _mpasi = DiversityProfile(
  minAgeMonths: 6,
  maxAgeMonths: 23,
  targetGroups: 5,
  countWithoutBreastMilk: false,
);

const _balita = DiversityProfile(
  minAgeMonths: 24,
  maxAgeMonths: 59,
  targetGroups: 5,
  countWithoutBreastMilk: true,
);

const _profiles = [_mpasi, _balita];

FoodLog _log({
  required DateTime at,
  required List<String> groups,
  String id = 'log',
}) {
  return FoodLog(
    id: id,
    childId: 'child-1',
    eatenAt: at,
    mealType: MealType.lunch,
    source: FoodLogSource.manual,
    items: [
      for (final group in groups)
        FoodLogItem(name: group, groups: [group]),
    ],
    groups: groups,
  );
}

void main() {
  group('HistoryEvaluator', () {
    test('selalu 30 hari, terbaru dulu, hari kosong tetap disertakan', () {
      final today = DateTime(2026, 11, 13, 10);
      final summary = HistoryEvaluator.build(
        logs: const [],
        today: today,
        ageMonthsAt: (_) => 12,
        profiles: _profiles,
      );

      expect(summary.windowDays, 30);
      expect(summary.days.first.day, DateTime(2026, 11, 13));
      expect(summary.days.last.day, DateTime(2026, 10, 15));
      expect(summary.windowStart, DateTime(2026, 10, 15));
      expect(summary.windowEnd, DateTime(2026, 11, 14));
      expect(summary.daysWithLogs, 0);
      expect(summary.targetReachedDays, 0);
      expect(summary.animalProteinDays, 0);
      expect(summary.latestWithLogs, isNull);
    });

    test('union kelompok dalam satu hari dan hari dengan target tercapai', () {
      final today = DateTime(2026, 11, 13, 10);
      final summary = HistoryEvaluator.build(
        logs: [
          _log(
            id: 'a',
            at: DateTime(2026, 11, 13, 7),
            groups: const ['grains_tubers'],
          ),
          _log(
            id: 'b',
            at: DateTime(2026, 11, 13, 12),
            groups: const ['eggs'],
          ),
          _log(
            id: 'c',
            at: DateTime(2026, 11, 13, 18),
            groups: const ['eggs'],
          ),
          _log(
            id: 'd',
            at: DateTime(2026, 11, 12, 12),
            groups: const ['grains_tubers', 'legumes_nuts', 'dairy', 'flesh', 'eggs'],
          ),
        ],
        today: today,
        ageMonthsAt: (_) => 12,
        profiles: _profiles,
      );

      final hariIni = summary.dayOf(today)!;
      expect(hariIni.hasLogs, isTrue);
      expect(hariIni.metCount, 2);
      expect(hariIni.targetCount, 8);
      expect(hariIni.targetReached, isFalse);
      expect(hariIni.animalProteinPresent, isTrue);
      expect(hariIni.logs.length, 3);

      final kemarin = summary.dayOf(DateTime(2026, 11, 12))!;
      expect(kemarin.metCount, 5);
      expect(kemarin.targetReached, isTrue);

      expect(summary.daysWithLogs, 2);
      expect(summary.targetReachedDays, 1);
      expect(summary.animalProteinDays, 2);
      expect(summary.latestWithLogs?.day, DateTime(2026, 11, 13));
    });

    test('batas hari lokal: 23.59 masuk kemarin, 00.00 masuk hari ini', () {
      final today = DateTime(2026, 11, 13, 9);
      final summary = HistoryEvaluator.build(
        logs: [
          _log(
            id: 'late',
            at: DateTime(2026, 11, 12, 23, 59),
            groups: const ['eggs'],
          ),
          _log(
            id: 'early',
            at: DateTime(2026, 11, 13, 0, 0),
            groups: const ['grains_tubers'],
          ),
        ],
        today: today,
        ageMonthsAt: (_) => 12,
        profiles: _profiles,
      );

      expect(summary.dayOf(DateTime(2026, 11, 12))!.metCount, 1);
      expect(
        summary.dayOf(DateTime(2026, 11, 12))!.piring.groups,
        {'eggs'},
      );
      expect(
        summary.dayOf(DateTime(2026, 11, 13))!.piring.groups,
        {'grains_tubers'},
      );
    });

    test('target mengikuti usia saat itu (ASI dihitung sebelum 24 bulan)', () {
      final today = DateTime(2026, 11, 13, 9);
      final cutover = DateTime(2026, 11, 1);
      final summary = HistoryEvaluator.build(
        logs: [
          _log(
            id: 'oktober',
            at: DateTime(2026, 10, 20, 8),
            groups: const ['breast_milk'],
          ),
          _log(
            id: 'november',
            at: DateTime(2026, 11, 5, 8),
            groups: const ['breast_milk'],
          ),
        ],
        today: today,
        ageMonthsAt: (day) => day.isBefore(cutover) ? 23 : 24,
        profiles: _profiles,
      );

      final oktober = summary.dayOf(DateTime(2026, 10, 20))!;
      expect(oktober.targetCount, 8);
      expect(oktober.metCount, 1);

      final november = summary.dayOf(DateTime(2026, 11, 5))!;
      expect(november.targetCount, 7);
      expect(november.metCount, 0);
    });

    test('catatan di luar jendela 30 hari diabaikan', () {
      final today = DateTime(2026, 11, 13, 9);
      final summary = HistoryEvaluator.build(
        logs: [
          _log(
            id: 'terlalu-lama',
            at: DateTime(2026, 9, 1, 8),
            groups: const ['eggs'],
          ),
          _log(
            id: 'batas-tertua',
            at: DateTime(2026, 10, 15, 0, 1),
            groups: const ['grains_tubers'],
          ),
        ],
        today: today,
        ageMonthsAt: (_) => 12,
        profiles: _profiles,
      );

      expect(summary.daysWithLogs, 1);
      expect(summary.dayOf(DateTime(2026, 10, 15))!.metCount, 1);
      expect(summary.dayOf(DateTime(2026, 9, 1)), isNull);
    });

    test('strip 7 hari mengambil hari terbaru lebih dulu', () {
      final today = DateTime(2026, 11, 13, 9);
      final summary = HistoryEvaluator.build(
        logs: const [],
        today: today,
        ageMonthsAt: (_) => 12,
        profiles: _profiles,
      );

      final recent = summary.recent(7);
      expect(recent.length, 7);
      expect(recent.first.day, DateTime(2026, 11, 13));
      expect(recent.last.day, DateTime(2026, 11, 7));
      expect(summary.recent(0), isEmpty);
    });

    test('windowDays tidak valid ditolak', () {
      expect(
        () => HistoryEvaluator.build(
          logs: const [],
          today: DateTime(2026, 11, 13),
          ageMonthsAt: (_) => 12,
          profiles: _profiles,
          windowDays: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
