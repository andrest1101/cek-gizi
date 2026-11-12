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
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/shared/widgets/child_identity_row.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Layar Makan (PRD §6.4): diary per hari, catat manual (ketuk kelompok
/// pangan — langsung tersimpan, bisa diurungkan), kontrol ASI.
/// Scanner menyusul di Batch 5 (butuh Cloud Billing + Gemini key).
class MakanScreen extends ConsumerWidget {
  const MakanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.makanTitle)),
      body: SafeArea(
        child: child == null ? const _NoChild() : _MakanBody(child: child),
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
      key: const Key('makan-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        ChildIdentityRow(child: child),
        const SizedBox(height: AppSpacing.md),
        _TodaySummary(logsAsync: logsAsync),
        const SizedBox(height: AppSpacing.sm),
        _AsiActionRow(childId: child.id, logsAsync: logsAsync),
        const SizedBox(height: AppSpacing.lg),
        if (isUnderSixMonths) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppSurfaces.sunken(
              context,
              radius: AppRadius.control,
            ),
            child: const _AsiExclusiveNote(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (!isUnderSixMonths) ...[
          const _GroupSectionHeader(),
          const SizedBox(height: AppSpacing.sm),
          _GroupGrid(childId: child.id, logsAsync: logsAsync),
          const SizedBox(height: AppSpacing.lg),
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
                  _DaySection(day: day.day, logs: day.logs, childId: child.id),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Ringkasan hari ini yang tipis (bukan kartu): ring mini + jumlah kelompok.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.logsAsync});

  final AsyncValue<List<FoodLog>> logsAsync;

  Set<String> _todayGroups(List<FoodLog> logs) {
    final today = DateTime.now();
    final groups = <String>{};
    for (final log in logs) {
      final local = log.eatenAt.toLocal();
      if (local.year == today.year &&
          local.month == today.month &&
          local.day == today.day) {
        groups.addAll(log.groups);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final logs = logsAsync.value;
    if (logs == null) return const _SummarySkeleton();
    final groups = _todayGroups(logs);
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final label = groups.isEmpty
        ? AppStrings.piringEmpty
        : AppStrings.piringPartial(groups.length, FoodGroup.allCodes.length);

    return Semantics(
      label:
          '${AppStrings.piringGroupsMetSemantics(groups.length, FoodGroup.allCodes.length)} $label',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: PiringRing(
              met: groups,
              size: 52,
              strokeWidth: 7,
              showCount: false,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
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
    return const SizedBox(
      height: 56,
      child: Row(
        children: [
          Skeleton(width: 52, height: 52, radius: 26),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Skeleton(height: 12)),
        ],
      ),
    );
  }
}

/// Kontrol ASI hari ini — baris tanpa kartu. Tombol bermakna:
/// "Catat ASI" saat belum tercatat, "Tercatat" (ketuk untuk menghapus) saat sudah.
class _AsiActionRow extends ConsumerStatefulWidget {
  const _AsiActionRow({required this.childId, required this.logsAsync});

  final String childId;
  final AsyncValue<List<FoodLog>> logsAsync;

  @override
  ConsumerState<_AsiActionRow> createState() => _AsiActionRowState();
}

class _AsiActionRowState extends ConsumerState<_AsiActionRow> {
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

  Future<void> _act(bool logged) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final notifier = ref.read(foodLogsProvider(widget.childId).notifier);
      if (logged) {
        await notifier.removeBreastMilkToday();
        messenger?.showSnackBar(
          const SnackBar(content: Text(AppStrings.makanAsiRemovedFeedback)),
        );
      } else {
        await notifier.addBreastMilkToday();
        messenger?.showSnackBar(
          const SnackBar(content: Text(AppStrings.makanAsiLoggedFeedback)),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanSaveError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final logs = widget.logsAsync.value;
    final logged = logs != null && _asiToday(logs);
    final isLoading = widget.logsAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
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
                  AppStrings.makanAsiToday,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  logged
                      ? AppStrings.makanAsiLogged
                      : AppStrings.makanAsiSubtitle,
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
          if (_busy)
            const SizedBox(
              width: 32,
              height: 32,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (logged)
            Semantics(
              button: true,
              label: AppStrings.makanAsiActionRemove,
              excludeSemantics: true,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () => _act(true),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(AppStrings.makanAsiActionRemove),
              ),
            )
          else
            FilledButton.icon(
              onPressed: isLoading ? null : () => _act(false),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(AppStrings.makanAsiActionLog),
            ),
        ],
      ),
    );
  }
}

class _AsiExclusiveNote extends StatelessWidget {
  const _AsiExclusiveNote();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.water_drop_rounded, size: 20, color: colors.onPrimary),
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
    );
  }
}

class _GroupSectionHeader extends StatelessWidget {
  const _GroupSectionHeader();

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
    );
  }
}

/// Grid quick-add kelompok pangan (PRD §6.4): 2 kolom slab ikon + label
/// pendek, tanpa contoh makanan. Satu ketukan = langsung tersimpan + snackbar
/// "Urungkan". Tanda hijau = kelompok sudah tercatat hari ini.
class _GroupGrid extends ConsumerWidget {
  const _GroupGrid({required this.childId, required this.logsAsync});

  final String childId;
  final AsyncValue<List<FoodLog>> logsAsync;

  static const _items =
      <({String code, String groupLabel, String shortLabel, IconData icon})>[
    (
      code: 'grains_tubers',
      groupLabel: AppStrings.groupGrainsTubers,
      shortLabel: AppStrings.groupGrainsTubersShort,
      icon: Icons.rice_bowl_rounded,
    ),
    (
      code: 'legumes_nuts',
      groupLabel: AppStrings.groupLegumesNuts,
      shortLabel: AppStrings.groupLegumesNutsShort,
      icon: Icons.grain_rounded,
    ),
    (
      code: 'dairy',
      groupLabel: AppStrings.groupDairy,
      shortLabel: AppStrings.groupDairyShort,
      icon: Icons.local_drink_rounded,
    ),
    (
      code: 'flesh',
      groupLabel: AppStrings.groupFlesh,
      shortLabel: AppStrings.groupFleshShort,
      icon: Icons.set_meal_rounded,
    ),
    (
      code: 'eggs',
      groupLabel: AppStrings.groupEggs,
      shortLabel: AppStrings.groupEggsShort,
      icon: Icons.egg_rounded,
    ),
    (
      code: 'vit_a_fruit_veg',
      groupLabel: AppStrings.groupVitAFruitVeg,
      shortLabel: AppStrings.groupVitAFruitVegShort,
      icon: Icons.eco_rounded,
    ),
    (
      code: 'other_fruit_veg',
      groupLabel: AppStrings.groupOtherFruitVeg,
      shortLabel: AppStrings.groupOtherFruitVegShort,
      icon: Icons.apple_rounded,
    ),
  ];

  Future<void> _quickAdd(
    BuildContext context,
    WidgetRef ref,
    String code,
    String label,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final log = await ref
          .read(foodLogsProvider(childId).notifier)
          .addManualGroup(groupCode: code, groupLabel: label);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(AppStrings.makanLogAdded(label)),
          action: SnackBarAction(
            label: AppStrings.makanUndoAction,
            onPressed: () => ref
                .read(foodLogsProvider(childId).notifier)
                .deleteLog(log.id),
          ),
        ),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanSaveError)),
      );
    }
  }

  Set<String> _todayGroups(List<FoodLog> logs) {
    final today = DateTime.now();
    final groups = <String>{};
    for (final log in logs) {
      final local = log.eatenAt.toLocal();
      if (local.year == today.year &&
          local.month == today.month &&
          local.day == today.day) {
        groups.addAll(log.groups);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logged = logsAsync.value != null
        ? _todayGroups(logsAsync.value!)
        : const <String>{};

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 64,
      ),
      children: [
        for (final item in _items)
          _GroupTile(
            icon: item.icon,
            label: item.shortLabel,
            logged: logged.contains(item.code),
            onTap: () => _quickAdd(context, ref, item.code, item.groupLabel),
          ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.icon,
    required this.label,
    required this.logged,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool logged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: logged ? '$label, sudah tercatat hari ini' : 'Catat $label',
      excludeSemantics: true,
      child: Material(
        color: logged ? colors.primaryContainer : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: logged ? colors.primary : colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: logged ? colors.onPrimary : colors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
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
    return const Column(
      children: [
        Skeleton(height: 28),
        SizedBox(height: AppSpacing.sm),
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
    return Row(
      children: [
        Icon(
          Icons.restaurant_rounded,
          size: 20,
          color: colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            AppStrings.makanDiaryEmpty,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section satu hari: subheader naked (ring mini + label hari) + baris item.
class _DaySection extends ConsumerWidget {
  const _DaySection({
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

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    FoodLog log,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final notifier = ref.read(foodLogsProvider(childId).notifier);
      await notifier.deleteLog(log.id);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.makanLogDeleted),
          action: SnackBarAction(
            label: AppStrings.makanUndoAction,
            onPressed: () => notifier.restoreLog(log),
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: PiringRing(
                met: groups,
                size: 36,
                strokeWidth: 7,
                showCount: false,
                semanticsLabel: AppStrings.piringGroupsMetSemantics(
                  groups.length,
                  FoodGroup.allCodes.length,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _dayLabel(day),
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              AppStrings.piringCountLine(
                groups.length,
                FoodGroup.allCodes.length,
              ),
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(height: 1, color: colors.outline),
        for (var i = 0; i < logs.length; i++) ...[
          _LogRow(
            log: logs[i],
            onDelete: () => _deleteWithUndo(context, ref, logs[i]),
          ),
          if (i < logs.length - 1) Divider(height: 1, color: colors.outline),
        ],
      ],
    );
  }
}

/// Baris item diary: ikon 40 slab + nama + jam, aksi hapus (swipe / tombol).
class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.log,
    required this.onDelete,
  });

  final FoodLog log;
  final VoidCallback onDelete;

  IconData _leadingIcon() {
    if (log.groups.length == 1) {
      return switch (log.groups.first) {
        'breast_milk' => Icons.water_drop_rounded,
        'grains_tubers' => Icons.rice_bowl_rounded,
        'legumes_nuts' => Icons.grain_rounded,
        'dairy' => Icons.local_drink_rounded,
        'flesh' => Icons.set_meal_rounded,
        'eggs' => Icons.egg_rounded,
        'vit_a_fruit_veg' => Icons.eco_rounded,
        'other_fruit_veg' => Icons.apple_rounded,
        _ => Icons.restaurant_rounded,
      };
    }
    return Icons.restaurant_rounded;
  }

  bool _isBreastMilk() =>
      log.groups.length == 1 && log.groups.first == 'breast_milk';

  String _time(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final asi = _isBreastMilk();

    return Dismissible(
      key: ValueKey('log-${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: colors.statusAlert.withValues(alpha: 0.14),
        child: Icon(Icons.delete_rounded, color: colors.statusAlert),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        leading: SizedBox(
          width: 40,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: asi ? colors.primaryContainer : colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _leadingIcon(),
              size: 20,
              color: asi ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
        title: Text(
          log.items.map((item) => item.name).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        ),
        subtitle: Text(
          _time(log.eatenAt),
          style: textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        trailing: IconButton(
          tooltip: AppStrings.makanDeleteLog,
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
