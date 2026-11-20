import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_logo.dart';

/// Porsi opsional untuk satu item hasil scan.
///
/// [storageValue] adalah nilai yang disimpan di `items[].portion`; `none`
/// berarti porsi tidak diisi (null di payload).
enum ScanPortion {
  none(''),
  little('sedikit'),
  medium('sedang'),
  finished('habis');

  const ScanPortion(this.storageValue);

  final String storageValue;

  static const List<ScanPortion> selectable = [little, medium, finished];

  String get label => switch (this) {
    ScanPortion.little => AppStrings.portionLittle,
    ScanPortion.medium => AppStrings.portionMedium,
    ScanPortion.finished => AppStrings.portionFinished,
    ScanPortion.none => '',
  };
}

/// Draft item yang sedang diperiksa di sheet hasil scan (bukan entitas domain).
///
/// [id] dipakai sebagai key animasi agar state tiap baris tetap menempel pada
/// item yang benar saat item lain dihapus.
final class ScanItemDraft {
  ScanItemDraft({
    required this.name,
    required this.groups,
    this.confidence = 1,
    Object? id,
  }) : id = id ?? Object();

  final Object id;
  String name;
  Set<String> groups;
  ScanPortion portion = ScanPortion.none;
  double confidence;
}

/// Satu baris item hasil scan: nama (bisa diedit), badge keyakinan rendah,
/// kelompok terpilih, dan porsi.
///
/// Sengaja tanpa kotak di dalam kotak: pemisah antar item memakai hairline di
/// parent, sesuai PRD §7.1.
class ScanResultItemTile extends StatelessWidget {
  const ScanResultItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
    required this.onEditGroups,
  });

  final ScanItemDraft item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onEditGroups;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final orderedGroups = _orderedGroups(item.groups);
    final primaryGroup = orderedGroups.isEmpty ? null : orderedGroups.first;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupBadge(code: primaryGroup),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: item.name,
                      onChanged: (value) => item.name = value.trim(),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 40,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: AppStrings.scanAddItemHint,
                        contentPadding: const EdgeInsets.only(
                          bottom: AppSpacing.xs,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.outline),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.outline),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.confidence < 0.6) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const _ConfidenceBadge(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: AppStrings.makanDeleteLog,
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.scanGroupLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEditGroups,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text(AppStrings.scanGroupEdit),
              ),
            ],
          ),
          if (orderedGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: colors.statusAlert,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      AppStrings.scanItemEmptyGroups,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.statusAlert,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final code in orderedGroups) _GroupPill(code: code),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.scanPortionOptional,
            style: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final portion in ScanPortion.selectable)
                Semantics(
                  button: true,
                  selected: item.portion == portion,
                  label: '${AppStrings.portionLabel}: ${portion.label}',
                  child: ExcludeSemantics(
                    child: ChoiceChip(
                      label: Text(portion.label),
                      selected: item.portion == portion,
                      showCheckmark: false,
                      onSelected: (_) {
                        item.portion = item.portion == portion
                            ? ScanPortion.none
                            : portion;
                        onChanged();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static List<String> _orderedGroups(Set<String> groups) => [
    for (final code in FoodGroup.allCodes)
      if (groups.contains(code)) code,
    for (final code in groups)
      if (FoodGroup.fromCode(code) == null) code,
  ];
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: code == null
          ? Icon(Icons.restaurant_rounded, size: 22, color: colors.primary)
          : FoodGroupLogo(code: code!, size: 34),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: AppStrings.scanConfidenceLowSemantics,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colors.accentContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 14,
                color: colors.onAccentContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.scanConfidenceLow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onAccentContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupPill extends StatelessWidget {
  const _GroupPill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FoodGroupLogo(code: code, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppStrings.groupShortLabel(code),
            style: textTheme.labelMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
