import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Buka sheet "Catat manual" dari dalam pemindai (PRD §6.4).
///
/// Mengembalikan true bila catatan tersimpan.
Future<bool?> showManualFoodSheet(
  BuildContext context, {
  required String childId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ManualFoodSheet(childId: childId),
  );
}

/// Alternatif offline-first untuk pengguna yang tidak ingin memfoto:
/// ketik nama makanan, pilih kelompoknya, pilih waktu makan, simpan sebagai
/// satu catatan `source = manual`.
class ManualFoodSheet extends ConsumerStatefulWidget {
  const ManualFoodSheet({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ManualFoodSheet> createState() => _ManualFoodSheetState();
}

class _ManualFoodSheetState extends ConsumerState<ManualFoodSheet> {
  final _nameController = TextEditingController();
  final Set<String> _groups = {};
  MealType _mealType = MealType.snack;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mealType = defaultMealTypeFor(ref.read(clockProvider)());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && _nameController.text.trim().isNotEmpty && _groups.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) {
      setState(() {
        _error = _nameController.text.trim().isEmpty
            ? AppStrings.manualFoodEmptyName
            : AppStrings.manualFoodEmptyGroups;
      });
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(foodLogsProvider(widget.childId).notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final log = await notifier.addManualItemLog(
        name: _nameController.text,
        mealType: _mealType,
        groups: _groups.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.manualFoodSaved),
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
        _error = AppStrings.manualFoodError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // `foodLogsProvider`: jaga notifier tetap hidup selama sheet terbuka.
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
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: SingleChildScrollView(
            key: const Key('manual-food-sheet'),
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
                        Icons.edit_note_rounded,
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
                              AppStrings.manualFoodTitle,
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.manualFoodSubtitle,
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
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.manualFoodNameLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('manual-food-name'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: AppStrings.manualFoodNameHint,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          AppStrings.manualFoodGroupsLabel,
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final code in FoodGroup.allCodes)
                      FilterChip(
                        key: ValueKey('manual-food-group-$code'),
                        label: Text(AppStrings.groupShortLabel(code)),
                        selected: _groups.contains(code),
                        showCheckmark: false,
                        onSelected: (_) => setState(() {
                          if (_groups.contains(code)) {
                            _groups.remove(code);
                          } else {
                            _groups.add(code);
                          }
                          _error = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.catatMakanMealTypeLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                    key: const Key('manual-food-save'),
                    onPressed: _canSave ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text(AppStrings.manualFoodSave),
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
