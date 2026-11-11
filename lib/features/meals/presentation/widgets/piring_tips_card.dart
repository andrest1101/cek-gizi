import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Kartu "Tips hari ini" di Beranda (PRD §6.3, §3.7).
///
/// Menampilkan SATU tips dari `nutrition_rules.json` sesuai kelompok yang
/// belum tercapai. Sembunyi bila anak <6 bulan, aturan gagal dimuat, atau
/// semua kelompok yang dihitung sudah tercapai. Menampilkan penanda bila
/// aturan belum ditinjau ahli gizi (PRD §9.1).
class PiringTipsCard extends ConsumerWidget {
  const PiringTipsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;
    if (child == null) return const SizedBox.shrink();
    final ageMonths = child.ageInCompletedMonths(DateTime.now());
    if (ageMonths < 6) return const SizedBox.shrink();

    final piringAsync = ref.watch(piringTodayProvider(child.id));
    final rulesAsync = ref.watch(nutritionRulesProvider);

    return piringAsync.when(
      loading: () => const _TipsSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (piring) {
        final diversity = piring?.diversity;
        if (piring == null || diversity == null) {
          return const SizedBox.shrink();
        }
        // Semua kelompok yang dihitung sudah terisi → hero menampilkan capaian.
        if (diversity.missingGroups.isEmpty || piring.isTargetReached) {
          return const SizedBox.shrink();
        }
        return rulesAsync.when(
          loading: () => const _TipsSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (rules) {
            final tips = rules.tipsForMissing(diversity.missingGroups);
            if (tips.isEmpty) return const SizedBox.shrink();
            return _TipsContent(
              tip: tips.first,
              isReviewed: rules.isReviewed,
            );
          },
        );
      },
    );
  }
}

class _TipsContent extends StatelessWidget {
  const _TipsContent({required this.tip, required this.isReviewed});

  final String tip;
  final bool isReviewed;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 19,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.tipTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            tip,
            style: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
          ),
          if (!isReviewed) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    AppStrings.piringUnreviewedCaption,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TipsSkeleton extends StatelessWidget {
  const _TipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 36, height: 36, radius: 18),
              SizedBox(width: AppSpacing.sm),
              Skeleton(width: 120, height: 14),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 12),
        ],
      ),
    );
  }
}
