import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/widgets/child_photo_avatar.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/presentation/growth_summary.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Kartu identitas anak terpilih di tab Akun: foto/avatar, nama, usia,
/// jenis kelamin, dan pengukuran terakhir sebagai konteks cepat.
class AccountIdentityCard extends ConsumerWidget {
  const AccountIdentityCard({
    super.key,
    required this.child,
    required this.now,
  });

  final ChildProfile child;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final measurementsAsync = ref.watch(measurementsProvider(child.id));
    final measurements = measurementsAsync.value;
    final latest = measurements == null
        ? null
        : GrowthSummary.latestOf(measurements);
    final sexLabel = child.sex == Sex.male
        ? AppStrings.childSexMale
        : AppStrings.childSexFemale;

    return Container(
      decoration: AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChildPhotoAvatar(
                  child: child,
                  size: 68,
                  semanticLabel: child.nickname,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 20,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaPill(
                            icon: Icons.cake_outlined,
                            label: child.ageLabel(now),
                          ),
                          _MetaPill(
                            icon: child.sex == Sex.male
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            label: sexLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/children/${child.id}/edit'),
                  tooltip: AppStrings.accountChildEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          _MeasurementSection(
            latest: latest,
            loading: measurementsAsync.isLoading,
            now: now,
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementSection extends StatelessWidget {
  const _MeasurementSection({
    required this.latest,
    required this.loading,
    required this.now,
  });

  final GrowthMeasurement? latest;
  final bool loading;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    if (loading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.straighten_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppStrings.accountMeasurementLoading,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final measurement = latest;
    if (measurement == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _MeasurementIcon(icon: Icons.monitor_weight_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.accountNoMeasurement,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.accountNoMeasurementBody,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/growth'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text(AppStrings.accountAddMeasurement),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/growth'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const _MeasurementIcon(icon: Icons.straighten_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.accountLastMeasurement,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${GrowthStatusCopy.formatKgCm(measurement.weightKg)} kg'
                      ' · '
                      '${GrowthStatusCopy.formatKgCm(measurement.lengthHeightCm)}'
                      ' cm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeDate(measurement.measuredOn, now),
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime measuredOn, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final measured = DateTime(
      measuredOn.year,
      measuredOn.month,
      measuredOn.day,
    );
    final days = today.difference(measured).inDays;
    if (days <= 0) return AppStrings.accountMeasurementToday;
    if (days == 1) return AppStrings.accountMeasurementYesterday;
    if (days < 7) return AppStrings.accountMeasurementDaysAgo(days);
    return IdDateFormat.short(measuredOn);
  }
}

class _MeasurementIcon extends StatelessWidget {
  const _MeasurementIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Icon(icon, size: 20, color: colors.primary),
    );
  }
}
