import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';
import 'package:cekgizi/features/recipes/domain/use_cases/recipe_use_cases.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Buka sheet "Catat sebagai makan" untuk sebuah resep (PRD §6.6).
Future<bool?> showRecipeLogSheet(
  BuildContext context, {
  required Recipe recipe,
  required String childId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecipeLogSheet(recipe: recipe, childId: childId),
  );
}

/// Pilih waktu makan lalu simpan resep sebagai satu catatan `source=recipe`.
/// Kelompok pangan resep otomatis masuk ke Piring Hari Ini.
class RecipeLogSheet extends ConsumerStatefulWidget {
  const RecipeLogSheet({
    super.key,
    required this.recipe,
    required this.childId,
  });

  final Recipe recipe;
  final String childId;

  @override
  ConsumerState<RecipeLogSheet> createState() => _RecipeLogSheetState();
}

class _RecipeLogSheetState extends ConsumerState<RecipeLogSheet> {
  late MealType _mealType;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mealType = defaultMealTypeFor(ref.read(clockProvider)());
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(foodLogsProvider(widget.childId).notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = RecipeUseCases.toFoodLog(
        recipe: widget.recipe,
        childId: widget.childId,
        mealType: _mealType,
        at: ref.read(clockProvider)(),
      );
      final log = await notifier.addRecipeLog(draft);
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.recipesLogSaved),
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
        _error = AppStrings.recipesLogError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jaga provider tetap hidup selama sheet terbuka.
    ref.watch(selectedChildProvider);
    ref.watch(foodLogsProvider(widget.childId));
    final colors = AppTheme.colorsOf(context);
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
          child: SingleChildScrollView(
            key: const Key('recipe-log-sheet'),
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
                        Icons.restaurant_rounded,
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
                              AppStrings.recipesLogSheetTitle,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.recipesLogSheetSubtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.recipe.title,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.catatMakanMealTypeLabel,
                    style: AppTextStyles.label.copyWith(
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.statusAlert,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('recipe-log-save'),
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text(AppStrings.recipesLogCta),
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
