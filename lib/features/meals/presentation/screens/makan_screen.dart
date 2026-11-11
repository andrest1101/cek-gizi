import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/meal_type_sheet.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/shared/widgets/child_identity_row.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Layar Makan (PRD §6.4): diary per hari, catat manual (ketuk kelompok
/// pangan), toggle ASI. Scanner menyusul di Batch 5 (butuh Cloud Billing).
class MakanScreen extends ConsumerWidget {
  const MakanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.makanTitle)),
      body: SafeArea(
        child: child == null
            ? const _NoChild()
            : _MakanBody(child: child),
      ),
    );
  }
}

class _NoChild extends StatelessWidget {
  const _NoChild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState(
          icon: Icons.restaurant_rounded,
          title: AppStrings.growthNoChildTitle,
          body: AppStrings.growthNoChildBody,
          action: FilledButton(
            onPressed: () => context.push('/children/add'),
            child: const Text(AppStrings.growthNoChildCta),
          ),
        ),
      ),
    );
  }
}

class _MakanBody extends ConsumerWidget {
  const _MakanBody({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(foodLogsProvider(child.id));
    final ageMonths = child.ageInCompletedMonths(DateTime.now());
    final isUnderSixMonths = ageMonths < 6;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        ChildIdentityRow(child: child),
        const SizedBox(height: AppSpacing.lg),
        _AsiToggleCard(childId: child.id, logsAsync: logsAsync),
        const SizedBox(height: AppSpacing.lg),
        if (isUnderSixMonths) ...[
          const _AsiExclusiveCard(),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          const _GroupSection(title: AppStrings.makanGridTitle, hint: AppStrings.makanGridHint),
          const SizedBox(height: AppSpacing.md),
          _GroupGrid(childId: child.id),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        const SectionHeader(title: AppStrings.makanDiaryTitle),
        const SizedBox(height: AppSpacing.md),
        logsAsync.when(
          loading: () => const _DiarySkeleton(),
          error: (error, stackTrace) => ErrorCard(
            message: AppStrings.makanLoadError,
            onRetry: () => ref.invalidate(foodLogsProvider(child.id)),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const _DiaryEmpty();
            }
            final days = PiringDayEvaluator.byDay(logs);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in days) ...[
                  _DayCard(day: day.day, logs: day.logs, childId: child.id),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hint,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _AsiToggleCard extends ConsumerStatefulWidget {
  const _AsiToggleCard({required this.childId, required this.logsAsync});

  final String childId;
  final AsyncValue<List<FoodLog>> logsAsync;

  @override
  ConsumerState<_AsiToggleCard> createState() => _AsiToggleCardState();
}

class _AsiToggleCardState extends ConsumerState<_AsiToggleCard> {
  bool _busy = false;

  bool _asiToday(List<FoodLog> logs) {
    final today = DateTime.now();
    for (final log in logs) {
      final local = log.eatenAt.toLocal();
      if (local.year == today.year &&
          local.month == today.month &&
          local.day == today.day &&
          log.groups.length == 1 &&
          log.groups.first == 'breast_milk') {
        return true;
      }
    }
    return false;
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(foodLogsProvider(widget.childId).notifier);
      if (value) {
        await notifier.addBreastMilkToday();
      } else {
        await notifier.removeBreastMilkToday();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text(AppStrings.makanSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final logs = widget.logsAsync.value;
    final asiToday = logs != null && _asiToday(logs);
    final isLoading = widget.logsAsync.isLoading;

    return DecoratedBox(
      decoration: AppSurfaces.card(context),
      child: SwitchListTile(
        value: asiToday,
        onChanged: isLoading || _busy ? null : _toggle,
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.water_drop_rounded, color: colors.primary),
        ),
        title: Text(
          AppStrings.makanAsiToday,
          style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
        ),
        subtitle: Text(
          AppStrings.makanAsiSubtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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
      decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop_rounded, color: colors.primary),
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

/// Grid 8 kelompok pangan (PRD §3.7). Ketuk → sheet pilih jenis makan.
class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.childId});

  final String childId;

  static const _items = <({String code, String label, String examples, IconData icon})>[
    (
      code: 'grains_tubers',
      label: AppStrings.groupGrainsTubers,
      examples: AppStrings.groupGrainsTubersExamples,
      icon: Icons.rice_bowl_rounded,
    ),
    (
      code: 'legumes_nuts',
      label: AppStrings.groupLegumesNuts,
      examples: AppStrings.groupLegumesNutsExamples,
      icon: Icons.grain_rounded,
    ),
    (
      code: 'dairy',
      label: AppStrings.groupDairy,
      examples: AppStrings.groupDairyExamples,
      icon: Icons.local_drink_rounded,
    ),
    (
      code: 'flesh',
      label: AppStrings.groupFlesh,
      examples: AppStrings.groupFleshExamples,
      icon: Icons.set_meal_rounded,
    ),
    (
      code: 'eggs',
      label: AppStrings.groupEggs,
      examples: AppStrings.groupEggsExamples,
      icon: Icons.egg_rounded,
    ),
    (
      code: 'vit_a_fruit_veg',
      label: AppStrings.groupVitAFruitVeg,
      examples: AppStrings.groupVitAFruitVegExamples,
      icon: Icons.eco_rounded,
    ),
    (
      code: 'other_fruit_veg',
      label: AppStrings.groupOtherFruitVeg,
      examples: AppStrings.groupOtherFruitVegExamples,
      icon: Icons.apple_rounded,
    ),
    (
      code: 'breast_milk',
      label: AppStrings.groupBreastMilk,
      examples: AppStrings.groupBreastMilkExamples,
      icon: Icons.water_drop_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 96,
      ),
      children: [
        for (final item in _items)
          _GroupCard(
            childId: childId,
            code: item.code,
            label: item.label,
            examples: item.examples,
            icon: item.icon,
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.childId,
    required this.code,
    required this.label,
    required this.examples,
    required this.icon,
  });

  final String childId;
  final String code;
  final String label;
  final String examples;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: AppStrings.makanLogGroupSemantics(label),
      excludeSemantics: true,
      child: Material(
        color: AppSurfaces.cardColor(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => showMealTypeSheet(
            context,
            childId: childId,
            groupCode: code,
            groupLabel: label,
          ),
          child: Container(
            decoration: AppSurfaces.card(context),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: colors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                          fontSize: 12,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        examples,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiarySkeleton extends StatelessWidget {
  const _DiarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Skeleton(height: 120),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 120),
      ],
    );
  }
}

class _DiaryEmpty extends StatelessWidget {
  const _DiaryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: AppSurfaces.sunken(context),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 32,
            color: AppTheme.colorsOf(context).textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.makanDiaryEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorsOf(context).textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.logs,
    required this.childId,
  });

  final DateTime day;
  final List<FoodLog> logs;
  final String childId;

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (_isSameDay(day, today)) return AppStrings.makanToday;
    if (_isSameDay(day, yesterday)) return AppStrings.makanYesterday;
    return IdDateFormat.full(day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Set<String> _dayGroups() {
    final groups = <String>{};
    for (final log in logs) {
      groups.addAll(log.groups);
    }
    return groups;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FoodLog log,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.makanDeleteLogTitle),
        content: const Text(AppStrings.makanDeleteLogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(foodLogsProvider(childId).notifier).deleteLog(log.id);
        messenger?.showSnackBar(
          const SnackBar(content: Text(AppStrings.makanLogDeleted)),
        );
      } catch (_) {
        messenger?.showSnackBar(
          const SnackBar(content: Text(AppStrings.makanSaveError)),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FoodLog log,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(foodLogsProvider(childId).notifier).deleteLog(log.id);
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanLogDeleted)),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final groups = _dayGroups();

    return DecoratedBox(
      decoration: AppSurfaces.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                PiringRing(
                  met: groups,
                  size: 56,
                  strokeWidth: 8,
                  showCount: false,
                  semanticsLabel: AppStrings.piringGroupsMetSemantics(
                    groups.length,
                    FoodGroup.allCodes.length,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayLabel(day),
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.piringCountLine(
                          groups.length,
                          FoodGroup.allCodes.length,
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
          ),
          Divider(height: 1, color: colors.outline),
          for (var i = 0; i < logs.length; i++) ...[
            _LogTile(
              log: logs[i],
              onDelete: () => _confirmDelete(context, ref, logs[i]),
              onSwipeDelete: () => _delete(context, ref, logs[i]),
            ),
            if (i < logs.length - 1)
              Divider(height: 1, color: colors.outline),
          ],
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.onDelete,
    required this.onSwipeDelete,
  });

  final FoodLog log;
  final VoidCallback onDelete;
  final VoidCallback onSwipeDelete;

  IconData _mealIcon() => switch (log.mealType) {
        MealType.breakfast => Icons.breakfast_dining_rounded,
        MealType.lunch => Icons.lunch_dining_rounded,
        MealType.dinner => Icons.dinner_dining_rounded,
        MealType.snack => Icons.cookie_rounded,
      };

  String _mealLabel() => switch (log.mealType) {
        MealType.breakfast => AppStrings.mealBreakfast,
        MealType.lunch => AppStrings.mealLunch,
        MealType.dinner => AppStrings.mealDinner,
        MealType.snack => AppStrings.mealSnack,
      };

  String _time(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey('log-${log.id}'),
      direction: DismissDirection.endToStart,
      background: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: colors.statusAlert.withValues(alpha: 0.18),
          child: Icon(Icons.delete_rounded, color: colors.statusAlert),
        ),
      ),
      onDismissed: (_) => onSwipeDelete(),
      child: ListTile(
        leading: Icon(_mealIcon(), color: colors.textSecondary),
        title: Text(
          log.items.map((item) => item.name).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        ),
        subtitle: Text(
          '${_mealLabel()} · ${_time(log.eatenAt)}',
          style: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
        ),
        trailing: IconButton(
          tooltip: AppStrings.makanDeleteLog,
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline_rounded, color: colors.textSecondary),
        ),
      ),
    );
  }
}
