import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';

/// Checklist bahan saat memasak - status murni lokal di layar ini, tidak
/// disimpan dan tidak dikirim ke mana pun. Centang memakai ikon + teks, bukan
/// warna saja (PRD §7.7).
class IngredientChecklist extends StatefulWidget {
  const IngredientChecklist({super.key, required this.ingredients});

  final List<RecipeIngredient> ingredients;

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  final Set<int> _checked = <int>{};

  void _toggle(int index) {
    setState(() {
      if (!_checked.remove(index)) _checked.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final done = _checked.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recipesIngredientsHint,
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        if (done > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppStrings.recipesChecklistProgress(
                      done,
                      widget.ingredients.length,
                    ),
                    style: AppTextStyles.label.copyWith(color: colors.primary),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: TextButton(
                  onPressed: () => setState(_checked.clear),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  child: const Text(AppStrings.recipesChecklistReset),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.outline, width: 1),
          ),
          child: Column(
            children: [
              for (var i = 0; i < widget.ingredients.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: colors.outline,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                _IngredientRow(
                  ingredient: widget.ingredients[i],
                  checked: _checked.contains(i),
                  onTap: () => _toggle(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.checked,
    required this.onTap,
  });

  final RecipeIngredient ingredient;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      checked: checked,
      label: AppStrings.recipesIngredientSemantics(
        ingredient.name,
        ingredient.amount,
      ),
      excludeSemantics: true,
      child: Material(
        color: AppSurfaces.cardColor(context),
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: checked ? colors.primary : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.control / 2),
                    border: checked
                        ? null
                        : Border.all(color: colors.outline, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: checked
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colors.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    ingredient.amount,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
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
