import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/catat_makan_sheet.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_checklist.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_log_list.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_info_sheet.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_tour_card.dart';
import 'package:cekgizi/shared/illustrations/empty_plate_illustration.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Bagian "Hari ini" di layar Makan: panel progres, checklist kelompok, dan
/// catatan hari ini.
class MakanTodayView extends ConsumerWidget {
  const MakanTodayView({super.key, required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(foodLogsProvider(child.id));
    final piringAsync = ref.watch(piringTodayProvider(child.id));
    final now = ref.watch(clockProvider)();
    final ageMonths = child.ageInCompletedMonths(now);
    final isUnderSixMonths = ageMonths < 6;
    // 24–59 bulan: ASI tidak dihitung pada target (PRD §3.7).
    final asiCounted = ageMonths >= 6 && ageMonths < 24;

    return ListView(
      key: const Key('makan-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        const PiringTourCard(),
        if (isUnderSixMonths) ...[
          const _AsiExclusiveCard(),
          const SizedBox(height: AppSpacing.lg),
          FoodGroupChecklist(
            childId: child.id,
            piring: piringAsync.value,
            asiCounted: true,
            codes: const ['breast_milk'],
          ),
        ] else ...[
          _TodayPanel(
            piringAsync: piringAsync,
            onInfo: () => showPiringInfoSheet(
              context,
              profile: piringAsync.value?.profile,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _ChecklistHeader(
            onInfo: () => showPiringInfoSheet(
              context,
              profile: piringAsync.value?.profile,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          piringAsync.when(
            loading: () => const _ChecklistSkeleton(),
            error: (error, stackTrace) => ErrorCard(
              message: AppStrings.makanLoadError,
              onRetry: () => ref.invalidate(piringTodayProvider(child.id)),
            ),
            data: (piring) => FoodGroupChecklist(
              childId: child.id,
              piring: piring,
              asiCounted: asiCounted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ComposerButton(childId: child.id),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const SectionHeader(title: AppStrings.makanDiaryTodayTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.makanTimelineHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.colorsOf(context).textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        logsAsync.when(
          loading: () => const _DiarySkeleton(),
          error: (error, stackTrace) => ErrorCard(
            message: AppStrings.makanLoadError,
            onRetry: () => ref.invalidate(foodLogsProvider(child.id)),
          ),
          data: (logs) {
            final todays = PiringDayEvaluator.logsOn(logs, now).reversed.toList();
            if (todays.isEmpty) return const _DiaryEmpty();
            return FoodLogList(logs: todays, childId: child.id);
          },
        ),
      ],
    );
  }
}

/// Panel ringkasan "hari ini": ring progres berangka + status protein hewani.
class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.piringAsync, required this.onInfo});

  final AsyncValue<PiringDay?> piringAsync;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final piring = piringAsync.value;

    if (piring == null) {
      if (piringAsync.isLoading) return const _SummarySkeleton();
      return const SizedBox.shrink();
    }

    final met = piring.countedCount;
    final total = piring.targetCount;
    final animalPresent = piring.animalProteinPresent;
    final hasLogs = piring.logs.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PiringProgressRing(
            met: met,
            total: total,
            size: 56,
            strokeWidth: 8,
            semanticsLabel: AppStrings.piringGroupsMetSemantics(met, total),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLogs
                      ? AppStrings.makanTodayProgress(met, total)
                      : AppStrings.makanTodayEmpty,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  piring.profile == null
                      ? AppStrings.piringNoProfile
                      : AppStrings.piringTargetNote(
                          piring.profile!.targetGroups,
                          breastMilkNotCounted:
                              piring.profile!.countWithoutBreastMilk,
                        ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      animalPresent
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: animalPresent ? colors.primary : colors.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        animalPresent
                            ? AppStrings.piringAnimalProteinPresent
                            : AppStrings.piringAnimalProteinMissing,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: AppStrings.piringInfoOpenSemantics,
            onPressed: onInfo,
            icon: Icon(
              Icons.info_outline_rounded,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: const Row(
        children: [
          Skeleton(width: 56, height: 56, radius: 28),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 160, height: 16),
                SizedBox(height: AppSpacing.sm),
                Skeleton(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header checklist + tombol "Cara kerja".
class _ChecklistHeader extends StatelessWidget {
  const _ChecklistHeader({required this.onInfo});

  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  AppStrings.makanGridTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.makanGridHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: onInfo,
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text(AppStrings.piringInfoOpen),
        ),
      ],
    );
  }
}

/// Jalur alternatif untuk mencatat satu piring berisi banyak kelompok.
class _ComposerButton extends StatelessWidget {
  const _ComposerButton({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: AppSurfaces.sunken(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => showCatatMakanSheet(context, childId: childId),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.makanComposerCta,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      AppStrings.makanComposerHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsiExclusiveCard extends StatelessWidget {
  const _AsiExclusiveCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_rounded,
              size: 20,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.asiExclusiveTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.asiExclusiveBody,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSkeleton extends StatelessWidget {
  const _ChecklistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: const Column(
        children: [
          Skeleton(height: 48),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 48),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 48),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 48),
        ],
      ),
    );
  }
}

class _DiarySkeleton extends StatelessWidget {
  const _DiarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Skeleton(height: 56),
        SizedBox(height: AppSpacing.xs),
        Skeleton(height: 56),
      ],
    );
  }
}

class _DiaryEmpty extends StatelessWidget {
  const _DiaryEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.sunken(context),
      child: Column(
        children: [
          const EmptyPlateIllustration(size: 72),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.makanDiaryEmpty,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
