import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/growth_summary.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_logo.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Kartu hero "Piring Hari Ini" di Beranda (PRD §6.3).
///
/// Satu-satunya permukaan solid berwarna di layar ini: hijau tua dengan teks
/// `onHeroSurface`. Susunan: eyebrow → ring besar dengan angka dominan →
/// status protein hewani → catatan target → CTA utama ke Makan.
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

class _PiringContent extends ConsumerWidget {
  const _PiringContent({required this.piring});

  final PiringDay piring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final reached = piring.isTargetReached;
    final animalPresent = piring.animalProteinPresent;
    final noProfile = piring.profile == null;
    final met = piring.countedCount;
    final total = piring.targetCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(
        context,
        radius: AppRadius.card + AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.piringTitle.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                color: colors.onHeroSurfaceMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: PiringRing(
              met: piring.countedGroups,
              codes: piring.targetCodes,
              size: 188,
              strokeWidth: 16,
              onHero: true,
              semanticsLabel: AppStrings.piringGroupsMetSemantics(met, total),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (piring.logs.isEmpty)
            _StatusLine(
              icon: Icons.restaurant_rounded,
              color: colors.onHeroSurfaceMuted,
              text: AppStrings.piringEmpty,
              muted: true,
            )
          else if (reached)
            _StatusLine(
              icon: Icons.check_circle_rounded,
              color: colors.onHeroSurface,
              text: AppStrings.piringTargetReached,
              bold: true,
            )
          else
            _StatusLine(
              icon: Icons.donut_small_rounded,
              color: colors.onHeroSurface,
              text: AppStrings.makanTodayProgress(met, total),
            ),
          // Dua ubin metrik berdampingan: protein hewani & tren berat.
          // Keduanya memakai data yang sudah ada (PiringDay & GrowthSummary).
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: colors.heroTrack),
          const SizedBox(height: AppSpacing.md),
          _HeroMetricsRow(piring: piring, animalPresent: animalPresent),
          if (animalPresent) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.piringLegendAnimal,
              style: AppTextStyles.label.copyWith(
                color: colors.onHeroSurfaceMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            noProfile
                ? AppStrings.piringNoProfile
                : AppStrings.piringTargetNote(
                    piring.profile!.targetGroups,
                    breastMilkNotCounted:
                        piring.profile!.countWithoutBreastMilk,
                  ),
            style: AppTextStyles.label.copyWith(
              color: colors.onHeroSurfaceMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/makan'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.onHeroSurface,
              foregroundColor: colors.heroSurface,
            ),
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
    final colors = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: muted ? colors.onHeroSurfaceMuted : colors.onHeroSurface,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dua metrik pendukung di dalam hero: protein hewani dan tren berat.
/// Fokus angka dominan tetap di ring, ubin ini hanya konteks cepat.
class _HeroMetricsRow extends ConsumerWidget {
  const _HeroMetricsRow({required this.piring, required this.animalPresent});

  final PiringDay piring;
  final bool animalPresent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final childId = ref.watch(selectedChildProvider).value?.id;
    final measurementsAsync = childId == null
        ? null
        : ref.watch(measurementsProvider(childId));
    final measurements = measurementsAsync?.value;
    final delta = (measurements == null || measurements.isEmpty)
        ? null
        : GrowthSummary.weightDeltaOf(measurements);

    final trendIcon = delta == null
        ? Icons.straighten_rounded
        : (delta >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);
    final trendColor = animalPresent
        ? colors.onHeroSurface
        : colors.onHeroAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HeroMetric(
            icon: animalPresent
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: animalPresent ? colors.onHeroSurface : colors.onHeroAccent,
            label: AppStrings.homeMetricProtein,
            value: animalPresent
                ? AppStrings.piringAnimalProteinPresent
                : AppStrings.piringAnimalProteinMissing,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _HeroMetric(
            icon: trendIcon,
            color: trendColor,
            label: AppStrings.homeMetricTrend,
            value: delta == null
                ? AppStrings.homeMetricNoTrend
                : GrowthStatusCopy.weightDeltaLabel(delta),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      container: true,
      label: '$label. $value',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: colors.onHeroSurfaceMuted,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onHeroSurface,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _PiringSkeleton extends StatelessWidget {
  const _PiringSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(
        context,
        radius: AppRadius.card + AppSpacing.xs,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 140, height: 12, color: colors.heroTrack),
          ),
          const SizedBox(height: AppSpacing.lg),
          Skeleton(
            width: 188,
            height: 188,
            radius: 94,
            color: colors.heroTrack,
          ),
          const SizedBox(height: AppSpacing.md),
          Skeleton(width: 220, height: 16, color: colors.heroTrack),
          const SizedBox(height: AppSpacing.md),
          Skeleton(height: 48, color: colors.heroTrack),
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
      decoration: AppSurfaces.hero(
        context,
        radius: AppRadius.card + AppSpacing.xs,
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.onHeroSurface),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.makanLoadError,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onHeroSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: colors.onHeroSurface),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppSurfaces.hero(
        context,
        radius: AppRadius.card + AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.onHeroSurface,
                  shape: BoxShape.circle,
                ),
                child: const FoodGroupLogo(code: 'breast_milk', size: 40),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.asiExclusiveTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.onHeroSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.asiExclusiveBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onHeroSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/makan'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.onHeroSurface,
              foregroundColor: colors.heroSurface,
            ),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text(AppStrings.heroAsiCta),
          ),
        ],
      ),
    );
  }
}
