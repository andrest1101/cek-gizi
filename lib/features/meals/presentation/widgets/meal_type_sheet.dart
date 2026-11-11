import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Sheet "Untuk kapan?" — pilih jenis makan lalu simpan catatan manual
/// untuk kelompok [groupCode] (PRD §6.4, jalur manual).
Future<void> showMealTypeSheet(
  BuildContext context, {
  required String childId,
  required String groupCode,
  required String groupLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MealTypeSheet(
      childId: childId,
      groupCode: groupCode,
      groupLabel: groupLabel,
    ),
  );
}

class _MealTypeSheet extends ConsumerStatefulWidget {
  const _MealTypeSheet({
    required this.childId,
    required this.groupCode,
    required this.groupLabel,
  });

  final String childId;
  final String groupCode;
  final String groupLabel;

  @override
  ConsumerState<_MealTypeSheet> createState() => _MealTypeSheetState();
}

class _MealTypeSheetState extends ConsumerState<_MealTypeSheet> {
  MealType _mealType = MealType.snack;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(foodLogsProvider(widget.childId).notifier)
          .addManualGroup(
            groupCode: widget.groupCode,
            groupLabel: widget.groupLabel,
            mealType: _mealType,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.makanSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                'Catat ${widget.groupLabel}',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.makanMealTypeBody,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.makanMealTypeTitle,
              style: textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentControl<MealType>(
              selected: _mealType,
              onChanged: (value) => setState(() => _mealType = value),
              options: const <SegmentOption<MealType>>[
                SegmentOption(
                  value: MealType.breakfast,
                  label: AppStrings.mealBreakfast,
                  semanticLabel: AppStrings.mealBreakfast,
                ),
                SegmentOption(
                  value: MealType.lunch,
                  label: AppStrings.mealLunch,
                  semanticLabel: AppStrings.mealLunch,
                ),
                SegmentOption(
                  value: MealType.dinner,
                  label: AppStrings.mealDinner,
                  semanticLabel: AppStrings.mealDinner,
                ),
                SegmentOption(
                  value: MealType.snack,
                  label: AppStrings.mealSnack,
                  semanticLabel: AppStrings.mealSnack,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: colors.statusAlert,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.statusAlert,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text(AppStrings.makanSaveLog),
            ),
          ],
        ),
      ),
    );
  }
}
