import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Buka composer "Catat satu kali makan" (PRD §6.4).
Future<void> showCatatMakanSheet(
  BuildContext context, {
  required String childId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CatatMakanSheet(childId: childId),
  );
}

/// Satu catatan makan berisi beberapa kelompok sekaligus.
///
/// Tetap memakai field yang sudah ada: `meal_type`, `items[].portion`, dan
/// `groups` union canonical - tanpa perubahan skema. Porsi bersifat opsional
/// dan tidak pernah dinilai.
class CatatMakanSheet extends ConsumerStatefulWidget {
  const CatatMakanSheet({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<CatatMakanSheet> createState() => _CatatMakanSheetState();
}

class _CatatMakanSheetState extends ConsumerState<CatatMakanSheet> {
  late MealType _mealType;
  final Set<String> _groups = {};
  String? _portion;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mealType = defaultMealTypeFor(ref.read(clockProvider)());
  }

  bool get _canSave => !_saving && _groups.isNotEmpty;

  Future<void> _save() async {
    if (_groups.isEmpty) {
      setState(() => _error = AppStrings.catatMakanEmptyGroups);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(foodLogsProvider(widget.childId).notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final log = await notifier.addManualMeal(
        mealType: _mealType,
        groupLabels: {
          for (final code in _groups) code: AppStrings.groupLabel(code),
        },
        portion: _portion,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.catatMakanSaved),
          action: SnackBarAction(
            label: AppStrings.makanUndoAction,
            onPressed: () => notifier.deleteLog(log.id),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.catatMakanError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jaga provider tetap hidup selama sheet terbuka (autoDispose).
    ref.watch(selectedChildProvider);
    ref.watch(foodLogsProvider(widget.childId));
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          child: SingleChildScrollView(
            key: const Key('catat-makan-sheet'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _DragHandle()),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              AppStrings.catatMakanTitle,
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.catatMakanSubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Label(AppStrings.catatMakanMealTypeLabel),
                const SizedBox(height: AppSpacing.sm),
                SegmentControl<MealType>(
                  options: [
                    for (final type in const [
                      MealType.breakfast,
                      MealType.lunch,
                      MealType.dinner,
                      MealType.snack,
                    ])
                      SegmentOption(
                        value: type,
                        label: mealTypeLabel(type),
                        semanticLabel:
                            '${AppStrings.catatMakanMealTypeLabel}: ${mealTypeLabel(type)}',
                      ),
                  ],
                  selected: _mealType,
                  onChanged: (value) => setState(() => _mealType = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label(AppStrings.catatMakanGroupsLabel),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.catatMakanGroupsHint,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.catatMakanSelectedCount(_groups.length),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final code in FoodGroup.allCodes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: DecoratedBox(
                      decoration: AppSurfaces.sunken(context),
                      child: CheckboxListTile(
                        key: ValueKey('catat-makan-group-$code'),
                        value: _groups.contains(code),
                        onChanged: (value) => setState(() {
                          if (value ?? false) {
                            _groups.add(code);
                          } else {
                            _groups.remove(code);
                          }
                          _error = null;
                        }),
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        secondary: Icon(
                          foodGroupIcon(code),
                          color: colors.textSecondary,
                          size: 22,
                        ),
                        title: Text(
                          AppStrings.groupShortLabel(code),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          AppStrings.groupExamples(code),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _Label(AppStrings.catatMakanPortionLabel),
                const SizedBox(height: 2),
                Text(
                  AppStrings.catatMakanPortionHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final portion in const [
                      'sedikit',
                      'sedang',
                      'habis',
                    ])
                      ChoiceChip(
                        key: ValueKey('catat-makan-portion-$portion'),
                        label: Text(portionLabel(portion)),
                        selected: _portion == portion,
                        onSelected: (_) => setState(
                          () => _portion = _portion == portion ? null : portion,
                        ),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.statusAlert,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('catat-makan-save'),
                    onPressed: _canSave ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text(AppStrings.catatMakanSave),
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colors.outline,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
