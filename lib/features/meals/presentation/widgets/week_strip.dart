import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';
import 'package:cekgizi/features/meals/presentation/providers/makan_section.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Strip 7 hari yang bisa diketuk. Dipakai sendirian di Riwayat dan dibungkus
/// [HomeWeekStrip] di Beranda.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.onSelect,
  });

  /// Hari terbaru lebih dulu (seperti [HistorySummary.days]).
  final List<HistoryDay> days;
  final DateTime? selectedDay;

  /// Tanggal hari ini menurut jam aplikasi (bukan `DateTime.now()` langsung).
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final ordered = days.reversed.toList();

    return Row(
      children: [
        for (final day in ordered)
          Expanded(
            child: _DayCell(
              key: ValueKey(
                'week-day-${day.day.year}-${day.day.month}-${day.day.day}',
              ),
              day: day,
              isToday: _isSameDay(day.day, today),
              isSelected:
                  selectedDay != null && _isSameDay(day.day, selectedDay!),
              colors: colors,
              textTheme: textTheme,
              onTap: () => onSelect(day.day),
            ),
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.colors,
    required this.textTheme,
    required this.onTap,
  });

  final HistoryDay day;
  final bool isToday;
  final bool isSelected;
  final AppColors colors;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isToday
        ? AppStrings.homeWeekToday
        : IdDateFormat.weekdayShort(day.day);

    final circleColor = isSelected
        ? colors.primary
        : day.hasLogs
            ? colors.primaryContainer
            : colors.surfaceVariant;
    final numberColor = isSelected
        ? colors.onPrimary
        : day.hasLogs
            ? colors.primary
            : colors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: AppStrings.homeWeekDaySemantics(
        isToday ? AppStrings.homeWeekToday : IdDateFormat.full(day.day),
        day.metCount,
        day.targetCount,
        hasLogs: day.hasLogs,
        reached: day.targetReached,
      ),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: isSelected ? colors.primary : colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: colors.primary, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '${day.day.day}',
                    style: textTheme.labelLarge?.copyWith(
                      color: numberColor,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 14,
                  child: day.targetReached
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: colors.primary,
                        )
                      : day.hasLogs
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Strip 7 hari + tautan "Lihat riwayat" untuk Beranda.
class HomeWeekStrip extends ConsumerWidget {
  const HomeWeekStrip({super.key, required this.childId});

  final String childId;

  Future<void> _openHistory(
    BuildContext context,
    WidgetRef ref, {
    DateTime? day,
  }) async {
    if (day != null) {
      focusHistoryDay(ref, day);
    } else {
      ref.read(historySelectedDayProvider.notifier).select(null);
      ref.read(makanSectionProvider.notifier).show(MakanSection.history);
    }
    context.go('/makan');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final selectedDay = ref.watch(historySelectedDayProvider);
    final summaryAsync = ref.watch(historySummaryProvider(childId));
    final now = ref.watch(clockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.homeWeekTitle,
          trailing: TextButton(
            onPressed: () => _openHistory(context, ref),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text(AppStrings.homeWeekHistoryCta),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.homeWeekHint,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        summaryAsync.when(
          loading: () => const Skeleton(height: 76, radius: AppRadius.card),
          error: (error, stackTrace) => Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.homeWeekLoadError,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(historySummaryProvider(childId)),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
          data: (summary) {
            if (summary == null || summary.daysWithLogs == 0) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Text(
                  AppStrings.homeWeekEmpty,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              );
            }
            return WeekStrip(
              days: summary.recent(7),
              selectedDay: selectedDay,
              today: now,
              onSelect: (day) => _openHistory(context, ref, day: day),
            );
          },
        ),
      ],
    );
  }
}
