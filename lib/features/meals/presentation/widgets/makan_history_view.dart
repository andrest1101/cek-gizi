import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/core/time/local_dates.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';
import 'package:cekgizi/features/meals/presentation/providers/makan_section.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_log_list.dart';
import 'package:cekgizi/features/meals/presentation/widgets/month_calendar.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/features/meals/presentation/widgets/week_strip.dart';
import 'package:cekgizi/shared/illustrations/empty_plate_illustration.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Bagian "Riwayat" di layar Makan: ringkasan 30 hari, strip 7 hari, kalender,
/// dan detail hari yang dipilih.
class MakanHistoryView extends ConsumerWidget {
  const MakanHistoryView({super.key, required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `foodLogsProvider` autoDispose: jaga notifier tetap hidup agar aksi
    // hapus/urungkan di daftar riwayat berjalan.
    ref.watch(foodLogsProvider(child.id));
    final now = ref.watch(clockProvider)();
    final today = startOfLocalDay(now);
    final selectedDay =
        startOfLocalDay(ref.watch(historySelectedDayProvider) ?? today);
    final summaryAsync = ref.watch(historySummaryProvider(child.id));

    final body = summaryAsync.when(
      loading: () => const _HistorySkeleton(),
      error: (error, stackTrace) => ErrorCard(
        title: AppStrings.errorTitle,
        message: AppStrings.makanHistoryLoadError,
        onRetry: () {
          ref.invalidate(historyLogsProvider(child.id));
          ref.invalidate(historySummaryProvider(child.id));
        },
      ),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return _HistoryData(
          summary: summary,
          selectedDay: selectedDay,
          today: today,
          childId: child.id,
        );
      },
    );

    return ListView(
      key: const Key('makan-history-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [body],
    );
  }
}

class _HistoryData extends ConsumerWidget {
  const _HistoryData({
    required this.summary,
    required this.selectedDay,
    required this.today,
    required this.childId,
  });

  final HistorySummary summary;
  final DateTime selectedDay;
  final DateTime today;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleMonth = startOfLocalMonth(selectedDay);
    final windowStartMonth = startOfLocalMonth(summary.windowStart);
    final currentMonth = startOfLocalMonth(today);
    final canGoPrevious = visibleMonth.isAfter(windowStartMonth);
    final canGoNext = visibleMonth.isBefore(currentMonth);

    void selectDay(DateTime day) {
      ref.read(historySelectedDayProvider.notifier).select(startOfLocalDay(day));
    }

    void previousMonth() => selectDay(addLocalMonths(visibleMonth, -1));

    void nextMonth() {
      final next = addLocalMonths(visibleMonth, 1);
      selectDay(
        next.year == today.year && next.month == today.month ? today : next,
      );
    }

    final day = summary.dayOf(selectedDay);
    final isToday = localDayDifference(selectedDay, today) == 0;
    final isYesterday = localDayDifference(selectedDay, today) == 1;
    final relativeLabel =
        isToday ? AppStrings.makanToday : (isYesterday ? AppStrings.makanYesterday : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(summary: summary),
        if (summary.daysWithLogs == 0) ...[
          const SizedBox(height: AppSpacing.xxl),
          _NoHistoryCard(onCta: () => focusToday(ref)),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: AppStrings.homeWeekTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.homeWeekHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorsOf(context).textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          WeekStrip(
            days: summary.recent(7),
            selectedDay: selectedDay,
            today: today,
            onSelect: selectDay,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: AppStrings.makanHistoryCalendarTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.makanHistoryCalendarHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorsOf(context).textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MonthCalendar(
            month: visibleMonth,
            summary: summary,
            selectedDay: selectedDay,
            today: today,
            onSelect: selectDay,
            onPreviousMonth: previousMonth,
            onNextMonth: nextMonth,
            canGoPrevious: canGoPrevious,
            canGoNext: canGoNext,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(
            title: IdDateFormat.full(selectedDay),
            trailing: relativeLabel == null
                ? null
                : _RelativePill(label: relativeLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          _DayDetail(day: day, childId: childId),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppStrings.makanHistoryWindowNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.colorsOf(context).textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TonalIconCircle(
                icon: Icons.calendar_month_rounded,
                iconSemantics: AppStrings.makanHistorySummaryTitle,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.makanHistorySummaryTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            icon: Icons.edit_calendar_rounded,
            text: AppStrings.makanHistoryDaysWithLogs(
              summary.daysWithLogs,
              summary.windowDays,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.check_circle_rounded,
            text: AppStrings.makanHistoryTargetDays(
              summary.targetReachedDays,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.egg_alt_rounded,
            text: AppStrings.makanHistoryAnimalDays(
              summary.animalProteinDays,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _NoHistoryCard extends StatelessWidget {
  const _NoHistoryCard({required this.onCta});

  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.restaurant_rounded,
      illustration: const EmptyPlateIllustration(),
      title: AppStrings.makanHistoryEmptyTitle,
      body: AppStrings.makanHistoryEmptyBody,
      action: FilledButton(
        onPressed: onCta,
        child: const Text(AppStrings.makanHistoryEmptyCta),
      ),
    );
  }
}

class _RelativePill extends StatelessWidget {
  const _RelativePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.childId});

  /// Null bila tanggal tidak masuk jendela 30 hari terakhir.
  final HistoryDay? day;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    if (day == null) {
      return Text(
        AppStrings.makanHistoryWindowNote,
        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      );
    }

    if (!day!.hasLogs) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppSurfaces.sunken(context),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppStrings.makanHistoryDayEmpty,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final piring = day!.piring;
    final logs = piring.logs.reversed.toList();
    final profile = piring.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile != null) ...[
          Row(
            children: [
              PiringProgressRing(
                met: piring.countedCount,
                total: piring.targetCount,
                size: 52,
                strokeWidth: 7,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.makanHistoryDayProgress(
                        piring.countedCount,
                        piring.targetCount,
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.piringTargetNote(
                        profile.targetGroups,
                        breastMilkNotCounted: profile.countWithoutBreastMilk,
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                piring.animalProteinPresent
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: piring.animalProteinPresent
                    ? colors.primary
                    : colors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  piring.animalProteinPresent
                      ? AppStrings.piringAnimalProteinPresent
                      : AppStrings.piringAnimalProteinMissing,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: AppSurfaces.sunken(context),
            child: Text(
              AppStrings.piringNoProfile,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FoodLogList(logs: logs, childId: childId, showDividers: true),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 150, radius: AppRadius.card),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 18, width: 160),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 76, radius: AppRadius.card),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 230, radius: AppRadius.card),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 56),
        SizedBox(height: AppSpacing.sm),
        Skeleton(height: 56),
      ],
    );
  }
}
