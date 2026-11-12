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

/// Kartu hero "Piring Hari Ini" di Beranda (PRD §6.3) — satu-satunya
/// permukaan solid berwarna (`primaryContainer`, §7.1).
///
/// Susunan: eyebrow + badge → ring besar dengan jumlah di tengah →
/// satu kalimat status + catatan target usia → CTA utama ke Makan.
/// Usia <6 bulan menampilkan versi ASI eksklusif (tanpa ring).
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
      data: (piring) => piring == null
          ? const SizedBox.shrink()
          : _PiringContent(piring: piring),
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
    final reached = piring.isTargetReached;
    final animalMissing = !piring.animalProteinPresent;
    final noProfile = piring.profile == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration:
          AppSurfaces.hero(context, radius: AppRadius.card + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.piringTitle.toUpperCase(),
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
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
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      AppStrings.piringReachedBadge,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
          if (piring.logs.isEmpty)
            _StatusLine(
              icon: Icons.restaurant_rounded,
              color: colors.textSecondary,
              text: AppStrings.piringEmpty,
              muted: true,
            )
          else if (reached)
            _StatusLine(
              icon: Icons.check_circle_rounded,
              color: colors.primary,
              text: AppStrings.piringTargetReached,
              bold: true,
            )
          else if (animalMissing)
            _StatusLine(
              icon: Icons.info_outline_rounded,
              color: colors.accent,
              text: AppStrings.piringAnimalProteinMissing,
            )
          else
            _StatusLine(
              icon: Icons.donut_small_rounded,
              color: colors.primary,
              text: AppStrings.piringPartial(
                piring.groups.length,
                FoodGroup.allCodes.length,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            noProfile
                ? AppStrings.piringNoProfile
                : AppStrings.piringTargetNote(
                    piring.profile!.targetGroups,
                    breastMilkNotCounted:
                        piring.profile!.countWithoutBreastMilk,
                  ),
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = AppTheme.colorsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: muted ? colors.textSecondary : colors.textPrimary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _PiringSkeleton extends StatelessWidget {
  const _PiringSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(context, radius: AppRadius.card + AppSpacing.xs),
      child: const Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 140, height: 12),
          ),
          SizedBox(height: AppSpacing.lg),
          Skeleton(width: 190, height: 190, radius: 95),
          SizedBox(height: AppSpacing.md),
          Skeleton(width: 220, height: 16),
          SizedBox(height: AppSpacing.md),
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
      decoration: AppSurfaces.hero(context, radius: AppRadius.card + AppSpacing.xs),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.makanLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.primary,
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
      decoration: AppSurfaces.hero(context, radius: AppRadius.card + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
            style: textTheme.bodySmall?.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/makan'),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text(AppStrings.heroAsiCta),
          ),
        ],
      ),
    );
  }
}
