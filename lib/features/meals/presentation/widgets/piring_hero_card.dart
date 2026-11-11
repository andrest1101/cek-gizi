import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Kartu "Piring Hari Ini" di Beranda (PRD §6.3) — satu-satunya permukaan
/// hero (`primaryContainer`). Usia <6 bulan menampilkan kartu ASI eksklusif.
class PiringHeroCard extends ConsumerWidget {
  const PiringHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;
    if (child == null) return const SizedBox.shrink();
    final ageMonths = child.ageInCompletedMonths(DateTime.now());
    if (ageMonths < 6) {
      return const _AsiExclusiveHero();
    }

    final piringAsync = ref.watch(piringTodayProvider(child.id));
    return piringAsync.when(
      loading: () => const _PiringSkeleton(),
      error: (error, stackTrace) => _PiringError(
        onRetry: () => ref.invalidate(piringTodayProvider(child.id)),
      ),
      data: (piring) =>
          piring == null ? const SizedBox.shrink() : _PiringContent(piring: piring),
    );
  }
}

class _PiringContent extends StatelessWidget {
  const _PiringContent({required this.piring});

  final PiringDay piring;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final animalMissing = !piring.animalProteinPresent;
    final reached = piring.isTargetReached;
    final noProfile = piring.profile == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.piringTitle,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              if (reached)
                Semantics(
                  label: AppStrings.piringTargetReached,
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      AppStrings.piringReachedBadge,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: PiringRing(
              met: piring.groups,
              size: 196,
              strokeWidth: 18,
              semanticsLabel: AppStrings.piringGroupsMetSemantics(
                piring.groups.length,
                FoodGroup.allCodes.length,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (piring.logs.isEmpty)
            Text(
              AppStrings.piringEmpty,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            )
          else if (reached)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    AppStrings.piringTargetReached,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else if (animalMissing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    AppStrings.piringAnimalProteinMissing,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              AppStrings.piringPartial(
                piring.groups.length,
                FoodGroup.allCodes.length,
              ),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          if (noProfile) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.piringNoProfile,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/makan'),
            icon: const Icon(Icons.add_rounded),
            label: const Text(AppStrings.piringCta),
          ),
        ],
      ),
    );
  }
}

class _PiringSkeleton extends StatelessWidget {
  const _PiringSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(context),
      child: Column(
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 132, height: 14),
          ),
          SizedBox(height: AppSpacing.lg),
          Skeleton(width: 180, height: 180, radius: 90),
          SizedBox(height: AppSpacing.lg),
          Skeleton(width: 200, height: 14),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 48),
        ],
      ),
    );
  }
}

class _PiringError extends StatelessWidget {
  const _PiringError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(context),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.makanLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _AsiExclusiveHero extends StatelessWidget {
  const _AsiExclusiveHero();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop_rounded, color: colors.onPrimary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.asiExclusiveTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.asiExclusiveBody,
            style: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/makan'),
            icon: const Icon(Icons.add_rounded),
            label: const Text(AppStrings.piringCta),
          ),
        ],
      ),
    );
  }
}
