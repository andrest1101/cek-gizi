import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/presentation/meals_actions.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Band "Tips hari ini" di Beranda (PRD §6.3, §3.7).
///
/// Berbentuk jalur tipis (bukan kartu 20dp) agar tidak tertukar dengan
/// permukaan aksi/hero. Menampilkan SATU tips dari `nutrition_rules.json`
/// sesuai kelompok yang belum tercapai. Sembunyi bila anak <6 bulan,
/// aturan gagal dimuat, atau semua kelompok dihitung sudah tercapai.
/// Bila aturan belum ditinjau ahli gizi, penanda ditampilkan (PRD §9.1).
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
        if (diversity.missingGroups.isEmpty || piring.isTargetReached) {
          return const SizedBox.shrink();
        }
        return rulesAsync.when(
          loading: () => const _TipsSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (rules) {
            final codes = rules.missingCodesWithTips(diversity.missingGroups);
            if (codes.isEmpty) return const SizedBox.shrink();
            final code = codes.first;
            final tip = rules.tipFor(code);
            if (tip == null) return const SizedBox.shrink();
            final groupLabel = AppStrings.groupLabel(code);
            return _TipsContent(
              tip: tip,
              groupLabel: groupLabel,
              isReviewed: rules.isReviewed,
              onLog: () => logFoodGroup(
                context,
                ref,
                childId: child.id,
                groupCode: code,
                groupLabel: groupLabel,
                alreadyLogged: piring.groups.contains(code),
              ),
            );
          },
        );
      },
    );
  }
}

class _TipsContent extends StatelessWidget {
  const _TipsContent({
    required this.tip,
    required this.groupLabel,
    required this.isReviewed,
    required this.onLog,
  });

  final String tip;
  final String groupLabel;
  final bool isReviewed;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.control),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 17,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tipTitle,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  groupLabel,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (!isReviewed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.piringUnreviewedCaption,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onLog,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(AppStrings.tipsAction),
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

class _TipsSkeleton extends StatelessWidget {
  const _TipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Row(
        children: [
          Skeleton(width: 32, height: 32, radius: 16),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Skeleton(height: 12)),
        ],
      ),
    );
  }
}
