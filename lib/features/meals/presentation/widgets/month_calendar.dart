import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';

/// Tinggi satu sel tanggal. Isinya: lingkaran 36 dp + jarak 2 dp + jalur
/// status 12 dp = 50 dp, menyisakan 6 dp agar target ketuk tetap tinggi.
/// Angka dan status menempati jalur berbeda sehingga tidak pernah bertumpuk.
const double _dayCellHeight = 56;
const double _dayCircleSize = 36;
const double _dayStatusLane = 12;

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
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendItem(
                color: colors.primary,
                label: AppStrings.makanHistoryLegendLogged,
              ),
              _LegendItem(
                color: colors.primary,
                icon: Icons.check_circle_rounded,
                label: AppStrings.makanHistoryLegendReached,
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
      return const SizedBox(height: _dayCellHeight);
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
            : colors.textSecondary.withValues(alpha: 0.55);

    final dayKey = '${day.year}-${day.month}-${day.day}';

    // Status punya jalur sendiri di bawah lingkaran (pola yang sama dengan
    // WeekStrip) supaya tidak pernah menimpa angka. Status tetap ditampilkan
    // pada tanggal terpilih agar informasinya tidak hilang.
    final status = data?.targetReached == true
        ? Icon(
            Icons.check_circle_rounded,
            key: ValueKey('calendar-day-status-$dayKey'),
            size: 12,
            color: colors.primary,
          )
        : data?.hasLogs == true
            ? Container(
                key: ValueKey('calendar-day-status-$dayKey'),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null;

    return Semantics(
      button: canSelect,
      selected: isSelected,
      label: AppStrings.makanHistoryDaySemantics(
        IdDateFormat.full(day),
        data?.metCount ?? 0,
        data?.targetCount ?? 0,
        data?.hasLogs ?? false,
        reached: data?.targetReached ?? false,
      ),
      excludeSemantics: true,
      child: SizedBox(
        height: _dayCellHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: canSelect ? () => onSelect(day) : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: _dayCircleSize,
                  height: _dayCircleSize,
                  // `Ink` menaruh latar lingkaran di lapisan Material,
                  // sehingga ripple berada di bawah teks dan angka tetap
                  // terbaca saat tanggal ditekan.
                  child: Ink(
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: colors.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        key: ValueKey('calendar-day-number-$dayKey'),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: _dayStatusLane,
                  child: status == null ? null : Center(child: status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
  });

  final Color color;
  final String label;

  /// Bila null, dipakai titik ([_LegendDot]) sebagai penanda "ada catatan".
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == null)
          _LegendDot(color: color)
        else
          Icon(icon, size: 12, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.colorsOf(context).textSecondary,
            ),
          ),
        ),
      ],
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
