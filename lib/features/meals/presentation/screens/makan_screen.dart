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
import 'package:cekgizi/features/meals/presentation/meals_actions.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Layar Makan (PRD §6.4): ringkasan hari ini, catat manual (ketuk kelompok
/// pangan - langsung tersimpan, bisa diurungkan), kontrol ASI, dan diary.
///
/// Struktur sengaja dibuat dua tingkat:
/// 1. **Hari ini** - panel progres + grid + catatan hari ini (selalu tampil,
///    punya empty state yang mengarahkan).
/// 2. **Hari sebelumnya** - dilipat per hari agar tidak membanjiri layar.
///
/// Scanner menyusul di Batch 5 (butuh Cloud Billing + Gemini key).
class MakanScreen extends ConsumerWidget {
  const MakanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;

    return Scaffold(
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
    final piringAsync = ref.watch(piringTodayProvider(child.id));
    final now = DateTime.now();
    final ageMonths = child.ageInCompletedMonths(now);
    final isUnderSixMonths = ageMonths < 6;
    // 24–59 bulan: ASI tidak dihitung pada target → tombol ASI jadi sekunder.
    final breastMilkNotCounted = ageMonths >= 24;

    return ListView(
      key: const Key('makan-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        ScreenHeader(
          eyebrow: IdDateFormat.eyebrow(now),
          title: AppStrings.makanTitle,
          subtitle: AppStrings.makanSubtitle,
          trailing: const ChildSwitcherButton(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TodayPanel(piringAsync: piringAsync),
        const SizedBox(height: AppSpacing.sm),
        _AsiActionRow(
          childId: child.id,
          logsAsync: logsAsync,
          secondary: breastMilkNotCounted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (isUnderSixMonths)
          const _AsiExclusiveCard()
        else ...[
          const _GroupSectionHeader(),
          const SizedBox(height: AppSpacing.sm),
          _GroupGrid(childId: child.id, piringAsync: piringAsync),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const SectionHeader(title: AppStrings.makanDiaryTodayTitle),
        const SizedBox(height: AppSpacing.md),
        logsAsync.when(
          loading: () => const _DiarySkeleton(),
          error: (error, stackTrace) => ErrorCard(
            message: AppStrings.makanLoadError,
            onRetry: () => ref.invalidate(foodLogsProvider(child.id)),
          ),
          data: (logs) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayEntries(logs: logs, now: now, childId: child.id),
              const SizedBox(height: AppSpacing.xxl),
              _PreviousDays(
                logs: logs,
                now: now,
                childId: child.id,
                total: piringAsync.value?.targetCount ??
                    FoodGroup.allCodes.length,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Panel ringkasan "hari ini": ring progres berangka + status target +
/// status protein hewani. Ini pengganti header polos/ring kosong.
class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.piringAsync});

  final AsyncValue<PiringDay?> piringAsync;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: colors.outline),
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

/// Kontrol ASI hari ini - baris tanpa kartu. Tombol bermakna:
/// "Catat ASI" saat belum tercatat, "Hapus catatan ASI" saat sudah.
/// Untuk usia 24–59 bulan tombol jadi sekunder + catatan bahwa ASI tidak
/// dihitung pada target (PRD §3.7).
class _AsiActionRow extends ConsumerStatefulWidget {
  const _AsiActionRow({
    required this.childId,
    required this.logsAsync,
    required this.secondary,
  });

  final String childId;
  final AsyncValue<List<FoodLog>> logsAsync;
  final bool secondary;

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

    final subtitle = logged
        ? AppStrings.makanAsiLogged
        : widget.secondary
            ? AppStrings.makanAsiSecondaryNote
            : AppStrings.makanAsiSubtitle;

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
                  subtitle,
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
          else if (widget.secondary)
            TextButton.icon(
              onPressed: isLoading ? null : () => _act(false),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(AppStrings.makanAsiActionLog),
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

class _AsiExclusiveCard extends StatelessWidget {
  const _AsiExclusiveCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.control),
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
/// pendek, tanpa contoh makanan. Satu ketukan = langsung tersimpan +
/// snackbar "Urungkan". Tanda centang = kelompok sudah tercatat hari ini;
/// ketuk ulang tidak menambah log duplikat, melainkan menawarkan hapus.
class _GroupGrid extends ConsumerWidget {
  const _GroupGrid({required this.childId, required this.piringAsync});

  final String childId;
  final AsyncValue<PiringDay?> piringAsync;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logged = piringAsync.value?.countedGroups ?? const <String>{};

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 68,
      ),
      children: [
        for (final item in _items)
          _GroupTile(
            icon: item.icon,
            label: item.shortLabel,
            logged: logged.contains(item.code),
            onTap: () => logFoodGroup(
              context,
              ref,
              childId: childId,
              groupCode: item.code,
              groupLabel: item.groupLabel,
              alreadyLogged: logged.contains(item.code),
            ),
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
      label: logged
          ? AppStrings.makanGroupLoggedSemantics(label)
          : AppStrings.makanGroupLogSemantics(label),
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
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              logged ? colors.primary : colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 19,
                          color: logged ? colors.onPrimary : colors.primary,
                        ),
                      ),
                      if (logged)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.surface),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: colors.onPrimary,
                            ),
                          ),
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

/// Catatan khusus hari ini (selalu terbuka).
class _TodayEntries extends StatelessWidget {
  const _TodayEntries({
    required this.logs,
    required this.now,
    required this.childId,
  });

  final List<FoodLog> logs;
  final DateTime now;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final todays = PiringDayEvaluator.logsOn(logs, now);
    if (todays.isEmpty) return const _DiaryEmpty();
    // Terbaru di atas, konsisten dengan catatan hari sebelumnya.
    return _LogList(
      logs: todays.reversed.toList(),
      childId: childId,
    );
  }
}

/// Daftar "Hari sebelumnya": setiap hari dilipat. Ringkasan memberi tahu
/// berapa kelompok yang tercatat, jadi tidak perlu menebak arti busur.
class _PreviousDays extends StatelessWidget {
  const _PreviousDays({
    required this.logs,
    required this.now,
    required this.childId,
    required this.total,
  });

  final List<FoodLog> logs;
  final DateTime now;
  final String childId;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final days = [
      for (final day in PiringDayEvaluator.byDay(logs))
        if (!_isSameDay(day.day, now)) day,
    ];
    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: AppStrings.makanPreviousTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.makanPreviousHint,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final day in days) ...[
          _PreviousDayTile(
            day: day.day,
            logs: day.logs,
            childId: childId,
            total: total,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _PreviousDayTile extends StatefulWidget {
  const _PreviousDayTile({
    required this.day,
    required this.logs,
    required this.childId,
    required this.total,
  });

  final DateTime day;
  final List<FoodLog> logs;
  final String childId;
  final int total;

  @override
  State<_PreviousDayTile> createState() => _PreviousDayTileState();
}

class _PreviousDayTileState extends State<_PreviousDayTile> {
  bool _expanded = false;

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (_isSameDay(day, yesterday)) return AppStrings.makanYesterday;
    return IdDateFormat.full(day);
  }

  int get _met => widget.logs
      .expand((log) => log.groups)
      .where((code) => code != 'breast_milk' || widget.total == 8)
      .toSet()
      .length;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final label = _dayLabel(widget.day);

    return Container(
      decoration: AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: AppStrings.makanDayToggleSemantics(
              label,
              _met,
              widget.total,
            ),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    PiringProgressRing(
                      met: _met,
                      total: widget.total,
                      size: 40,
                      strokeWidth: 6,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.makanTodayProgress(_met, widget.total),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: colors.outline),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: _LogList(
                logs: widget.logs,
                childId: widget.childId,
                showDividers: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Daftar baris catatan (tanpa label hari) dengan aksi hapus + urungkan.
class _LogList extends ConsumerWidget {
  const _LogList({
    required this.logs,
    required this.childId,
    this.showDividers = false,
  });

  final List<FoodLog> logs;
  final String childId;
  final bool showDividers;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < logs.length; i++) ...[
          _LogRow(
            log: logs[i],
            onDelete: () => _deleteWithUndo(context, ref, logs[i]),
          ),
          if (showDividers && i < logs.length - 1)
            Divider(height: 1, color: colors.outline),
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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
