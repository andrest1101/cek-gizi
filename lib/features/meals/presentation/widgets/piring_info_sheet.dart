import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Buka penjelasan "Cara kerja Piring Hari Ini".
Future<void> showPiringInfoSheet(
  BuildContext context, {
  required DiversityProfile? profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PiringInfoSheet(profile: profile),
  );
}

/// Penjelasan aturan yang dipakai Piring Hari Ini, tanpa istilah teknis dan
/// tanpa klaim medis. Target selalu berasal dari `nutrition_rules.json`.
class PiringInfoSheet extends ConsumerWidget {
  const PiringInfoSheet({super.key, required this.profile});

  final DiversityProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final rulesAsync = ref.watch(nutritionRulesProvider);
    final media = MediaQuery.of(context);
    final reviewed = rulesAsync.value?.isReviewed;

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
            key: const Key('piring-info-sheet'),
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
                        Icons.info_outline_rounded,
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
                              AppStrings.piringInfoTitle,
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.piringInfoIntro,
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
                _InfoBlock(
                  icon: Icons.today_rounded,
                  title: AppStrings.piringInfoResetTitle,
                  body: AppStrings.piringInfoResetBody,
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoBlock(
                  icon: Icons.donut_large_rounded,
                  title: AppStrings.piringInfoTargetTitle,
                  body: profile == null
                      ? AppStrings.piringNoProfile
                      : AppStrings.piringInfoTargetBody(
                          profile!.targetGroups,
                          breastMilkNotCounted:
                              profile!.countWithoutBreastMilk,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoBlock(
                  icon: Icons.water_drop_rounded,
                  title: AppStrings.piringInfoAsiTitle,
                  body: AppStrings.piringInfoAsiBody,
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoBlock(
                  icon: Icons.egg_alt_rounded,
                  title: AppStrings.piringInfoAnimalTitle,
                  body: AppStrings.piringInfoAnimalBody,
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoBlock(
                  icon: Icons.edit_note_rounded,
                  title: AppStrings.piringInfoNotJudgingTitle,
                  body: AppStrings.piringInfoNotJudgingBody,
                ),
                if (reviewed == false) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppSurfaces.sunken(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 18,
                          color: colors.statusWatchText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            AppStrings.piringUnreviewedCaption,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.piringInfoClose),
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TonalIconCircle(
          icon: icon,
          iconSemantics: title,
          size: 40,
          iconSize: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
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
