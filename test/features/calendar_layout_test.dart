import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/widgets/month_calendar.dart';

/// UX-22: kalender Riwayat tidak boleh menutupi angka tanggal dengan ripple
/// atau indikator status, termasuk saat tanggal dipilih dan pada
/// text scale 1,3 di layar 360 dp.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Hari ini 24 Nov 2026 → jendela 30 hari mulai 26 Okt 2026, jadi tanggal
  // 1–24 November bisa dipilih dan 25–30 tidak (masa depan).
  final today = DateTime(2026, 11, 24);
  final month = DateTime(2026, 11);

  const profile = DiversityProfile(
    minAgeMonths: 6,
    maxAgeMonths: 23,
    targetGroups: 5,
    countWithoutBreastMilk: false,
  );

  const reachedGroups = <String>{
    'grains_tubers',
    'legumes_nuts',
    'eggs',
    'flesh',
    'dairy',
  };

  HistoryDay buildDay(
    int dayNumber, {
    bool logged = false,
    bool reached = false,
  }) {
    final date = DateTime(2026, 11, dayNumber);
    final groups = reached
        ? reachedGroups
        : logged
        ? const <String>{'eggs'}
        : const <String>{};
    return HistoryDay(
      day: date,
      piring: PiringDay(
        logs: logged
            ? [
                FoodLog(
                  id: 'log-$dayNumber',
                  childId: 'child-1',
                  eatenAt: DateTime(2026, 11, dayNumber, 8),
                  mealType: MealType.breakfast,
                  source: FoodLogSource.manual,
                  items: [
                    for (final group in groups)
                      FoodLogItem(name: group, groups: [group]),
                  ],
                  groups: groups.toList(),
                ),
              ]
            : const [],
        groups: groups,
        diversity: logged
            ? DiversitySummary(
                metGroups: groups,
                missingGroups: const <String>{},
                target: 5,
                animalProteinPresent: true,
              )
            : null,
        profile: profile,
      ),
    );
  }

  /// Ringkasan November 2026 dengan hari khusus 12 (target tercapai) dan
  /// 16 (ada catatan, target belum tercapai).
  HistorySummary buildSummary() {
    final special = {
      12: buildDay(12, logged: true, reached: true),
      16: buildDay(16, logged: true),
    };
    final days = [
      for (var dayNumber = 1; dayNumber <= 30; dayNumber++)
        special[dayNumber] ?? buildDay(dayNumber),
    ]..sort((a, b) => b.day.compareTo(a.day));
    return HistorySummary(
      days: days,
      windowStart: DateTime(2026, 10, 26),
      windowEnd: DateTime(2026, 11, 25),
    );
  }

  Future<void> pumpCalendar(
    WidgetTester tester, {
    required Brightness brightness,
    DateTime? selected,
  }) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MonthCalendar(
                month: month,
                summary: buildSummary(),
                selectedDay: selected ?? today,
                today: today,
                onSelect: (_) {},
                onPreviousMonth: () {},
                onNextMonth: () {},
                canGoPrevious: true,
                canGoNext: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder numberKey(int dayNumber) =>
      find.byKey(ValueKey('calendar-day-number-2026-11-$dayNumber'));

  Finder statusKey(int dayNumber) =>
      find.byKey(ValueKey('calendar-day-status-2026-11-$dayNumber'));

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

  for (final brightness in Brightness.values) {
    group('360dp @1,3 (${brightness.name})', () {
      testWidgets('angka & indikator status tidak bertumpuk', (tester) async {
        await pumpCalendar(tester, brightness: brightness);
        expect(tester.takeException(), isNull);

        // 12 = target tercapai (ikon centang), 16 = ada catatan (titik).
        for (final dayNumber in [12, 16]) {
          expect(numberKey(dayNumber), findsOneWidget);
          expect(statusKey(dayNumber), findsOneWidget);

          final number = rectOf(tester, numberKey(dayNumber));
          final status = rectOf(tester, statusKey(dayNumber));
          expect(
            number.bottom,
            lessThanOrEqualTo(status.top),
            reason:
                'Angka tanggal $dayNumber harus berada di atas indikator '
                'status tanpa bertumpuk.',
          );
          expect(
            number.overlaps(status),
            isFalse,
            reason: 'Kotak angka & status tanggal $dayNumber tidak boleh '
                'beririsan.',
          );
        }
      });

      testWidgets('status tetap tampil saat tanggal dipilih', (tester) async {
        await pumpCalendar(
          tester,
          brightness: brightness,
          selected: DateTime(2026, 11, 12),
        );
        expect(tester.takeException(), isNull);
        expect(statusKey(12), findsOneWidget);

        final number = rectOf(tester, numberKey(12));
        final status = rectOf(tester, statusKey(12));
        expect(number.overlaps(status), isFalse);
      });

      testWidgets('semantik tanggal menyebut target tercapai', (tester) async {
        await pumpCalendar(tester, brightness: brightness);
        final labels = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((widget) => widget.properties.label)
            .whereType<String>();
        final target = labels.where(
          (label) =>
              label.contains('12') &&
              label.contains(AppStrings.makanHistoryLegendReached),
        );
        expect(
          target,
          isNotEmpty,
          reason: 'Label tanggal 12 harus menyebut target tercapai.',
        );
      });

      testWidgets('target ketuk tanggal tinggi ≥ 48dp', (tester) async {
        await pumpCalendar(tester, brightness: brightness);
        final inkWell = tester.widget<InkWell>(
          find
              .ancestor(of: numberKey(12), matching: find.byType(InkWell))
              .first,
        );
        expect(inkWell.onTap, isNotNull);

        final size = tester.getSize(
          find
              .ancestor(of: numberKey(12), matching: find.byType(InkWell))
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('tanggal masa depan tidak bisa dipilih', (tester) async {
        await pumpCalendar(tester, brightness: brightness);
        final inkWell = tester.widget<InkWell>(
          find
              .ancestor(of: numberKey(30), matching: find.byType(InkWell))
              .first,
        );
        expect(inkWell.onTap, isNull);
      });
    });
  }
}
