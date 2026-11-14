import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/meals_actions.dart';

/// Checklist kelompok pangan hari ini (PRD §6.4).
///
/// Setiap baris punya aksi eksplisit "Catat" / "Hapus" dan seluruh baris juga
/// bisa diketuk. Status tidak pernah hanya warna: ikon centang + teks
/// "Tercatat" selalu ada. ASI menjadi baris pertama karena untuk usia 6–23
/// bulan ASI ikut dihitung dalam target.
class FoodGroupChecklist extends ConsumerWidget {
  const FoodGroupChecklist({
    super.key,
    required this.childId,
    required this.piring,
    required this.asiCounted,
    this.codes,
  });

  final String childId;

  /// Keadaan hari ini; null saat masih memuat (baris tetap tampil belum
  /// tercatat agar tata letak tidak melompat).
  final PiringDay? piring;

  /// True untuk usia 6–23 bulan (ASI dihitung pada target).
  final bool asiCounted;

  /// Kelompok yang tampil, urut dari atas. Default: seluruh semesta hari ini
  /// dengan ASI baris pertama.
  final List<String>? codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final visibleCodes = codes ?? checklistCodes(includeBreastMilk: true);
    final logged = piring?.groups ?? const <String>{};
    final logGroups = <List<String>>[
      for (final log in piring?.logs ?? const <FoodLog>[]) log.groups,
    ];

    return Container(
      decoration: AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < visibleCodes.length; index++) ...[
            _GroupChecklistRow(
              key: ValueKey('group-row-${visibleCodes[index]}'),
              code: visibleCodes[index],
              logged: logged.contains(visibleCodes[index]),
              canRemove: canRemoveGroupFromChecklist(
                logGroups,
                visibleCodes[index],
              ),
              optional: visibleCodes[index] == 'breast_milk' && !asiCounted,
              childId: childId,
            ),
            if (index < visibleCodes.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.outline,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupChecklistRow extends ConsumerWidget {
  const _GroupChecklistRow({
    super.key,
    required this.code,
    required this.logged,
    required this.canRemove,
    required this.optional,
    required this.childId,
  });

  final String code;
  final bool logged;
  final bool canRemove;
  final bool optional;
  final String childId;

  bool get _isAsi => code == 'breast_milk';

  String get _label => _isAsi ? AppStrings.makanAsiToday : AppStrings.groupShortLabel(code);

  String get _examples {
    if (!_isAsi) return AppStrings.groupExamples(code);
    if (logged) return AppStrings.makanAsiLogged;
    return optional
        ? AppStrings.makanAsiSecondaryNote
        : AppStrings.makanAsiSubtitle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    void onRowTap() {
      if (logged) {
        showGroupAlreadyLogged(
          context,
          ref,
          childId: childId,
          groupCode: code,
          groupLabel: AppStrings.groupLabel(code),
          canRemove: canRemove,
        );
      } else {
        logFoodGroup(
          context,
          ref,
          childId: childId,
          groupCode: code,
          groupLabel: AppStrings.groupLabel(code),
        );
      }
    }

    return Semantics(
      button: true,
      label: AppStrings.makanChecklistSemantics(_label, _examples, logged),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.easeOutCubic,
        color: logged
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
          onTap: onRowTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: logged ? colors.primary : colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    foodGroupIcon(code),
                    size: 20,
                    color: logged ? colors.onPrimary : colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _examples,
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
                _Action(
                  key: ValueKey('group-action-$code'),
                  logged: logged,
                  canRemove: canRemove,
                  optional: optional,
                  isAsi: _isAsi,
                  onLog: () => logFoodGroup(
                    context,
                    ref,
                    childId: childId,
                    groupCode: code,
                    groupLabel: AppStrings.groupLabel(code),
                  ),
                  onRemove: () => removeFoodGroup(
                    context,
                    ref,
                    childId: childId,
                    groupCode: code,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.logged,
    required this.canRemove,
    required this.optional,
    required this.isAsi,
    required this.onLog,
    required this.onRemove,
  });

  final bool logged;
  final bool canRemove;
  final bool optional;
  final bool isAsi;
  final VoidCallback onLog;
  final VoidCallback onRemove;

  static const _buttonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
    tapTargetSize: MaterialTapTargetSize.padded,
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    if (logged && canRemove) {
      return TextButton.icon(
        onPressed: onRemove,
        style: _buttonStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(colors.statusAlert),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: const Text(AppStrings.makanChecklistActionRemove),
      );
    }

    if (logged) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.makanChecklistCounted,
              style: textTheme.labelMedium?.copyWith(color: colors.primary),
            ),
          ],
        ),
      );
    }

    final label = isAsi
        ? AppStrings.makanAsiActionLog
        : AppStrings.makanChecklistActionLog;

    if (optional) {
      return TextButton.icon(
        onPressed: onLog,
        style: _buttonStyle,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: onLog,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );
  }
}
