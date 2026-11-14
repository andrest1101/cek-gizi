import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';

/// Kalender satu bulan untuk Riwayat. Hanya tanggal yang masuk jendela data
/// (30 hari terakhir) dan bukan masa depan yang bisa dipilih.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.summary,
    required this.selectedDay,
    required this.today,
    required this.onSelect,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.canGoPrevious,
    required this.canGoNext,
  });

  /// Awal bulan yang ditampilkan (hari pertama).
  final DateTime month;
  final HistorySummary summary;
  final DateTime? selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: AppStrings.makanHistoryPrevMonth,
                onPressed: canGoPrevious ? onPreviousMonth : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    IdDateFormat.monthYear(month),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.makanHistoryNextMonth,
                onPressed: canGoNext ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                Expanded(
                  child: Text(
                    IdDateFormat.weekdayShort(DateTime(2026, 1, weekday + 4)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var row = 0; row < cells ~/ 7; row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _DayCell(
                      key: ValueKey(
                        'calendar-day-${month.year}-${month.month}-${row * 7 + column - leading + 1}',
                      ),
                      index: row * 7 + column,
                      leading: leading,
                      daysInMonth: daysInMonth,
                      month: month,
                      summary: summary,
                      selectedDay: selectedDay,
                      today: today,
                      onSelect: onSelect,
                      colors: colors,
                      textTheme: textTheme,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  AppStrings.makanHistoryLegendLogged,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.check_circle_rounded, size: 12, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  AppStrings.makanHistoryLegendReached,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.index,
    required this.leading,
    required this.daysInMonth,
    required this.month,
    required this.summary,
    required this.selectedDay,
    required this.today,
    required this.onSelect,
    required this.colors,
    required this.textTheme,
  });

  final int index;
  final int leading;
  final int daysInMonth;
  final DateTime month;
  final HistorySummary summary;
  final DateTime? selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final dayNumber = index - leading + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 48);
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final data = summary.dayOf(day);
    final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));
    final canSelect = data != null && !isFuture;
    final isSelected = selectedDay != null &&
        selectedDay!.year == day.year &&
        selectedDay!.month == day.month &&
        selectedDay!.day == day.day;
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    final background = isSelected
        ? colors.primary
        : data?.hasLogs == true
            ? colors.primaryContainer
            : Colors.transparent;
    final foreground = isSelected
        ? colors.onPrimary
        : canSelect
            ? colors.textPrimary
            : colors.textSecondary.withValues(alpha: 0.45);

    return Semantics(
      button: canSelect,
      selected: isSelected,
      label: AppStrings.makanHistoryDaySemantics(
        IdDateFormat.full(day),
        data?.metCount ?? 0,
        data?.targetCount ?? 0,
        data?.hasLogs ?? false,
      ),
      excludeSemantics: true,
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: canSelect ? () => onSelect(day) : null,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight:
                            isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (data?.targetReached == true && !isSelected)
                      Positioned(
                        bottom: 2,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 9,
                          color: colors.primary,
                        ),
                      )
                    else if (data?.hasLogs == true && !isSelected)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
