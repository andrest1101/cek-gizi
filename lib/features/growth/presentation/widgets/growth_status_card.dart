import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/services/growth_trend_evaluator.dart';
import 'package:cekgizi/features/growth/presentation/growth_summary.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/add_measurement_sheet.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/metric_tile.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';
import 'package:cekgizi/shared/widgets/z_score_table.dart';

/// Kartu status tumbuh (PRD §6.3, §6.5): status terburuk, tanggal, tren,
/// metrik terakhir (opsional di Beranda), aksi tambah ukuran & detail.
class GrowthStatusCard extends ConsumerWidget {
  const GrowthStatusCard({super.key, this.showMetrics = true});

  /// Beranda menampilkan metrik berat/tinggi; layar Tumbuh tidak perlu
  /// karena grafik & riwayat sudah ada di bawahnya.
  final bool showMetrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;
    if (child == null) return const SizedBox.shrink();

    final measurementsAsync = ref.watch(measurementsProvider(child.id));
    return measurementsAsync.when(
      loading: () => _StatusSkeleton(showMetrics: showMetrics),
      error: (error, stackTrace) => ErrorCard(
        message: AppStrings.growthLoadError,
        onRetry: () => ref.invalidate(measurementsProvider(child.id)),
      ),
      data: (measurements) {
        if (measurements.isEmpty) {
          return _EmptyStatus(
            onAdd: () => showMeasurementSheet(context),
          );
        }
        final latest = GrowthSummary.latestOf(measurements)!;
        final summary = GrowthStatusSummary.worstOf(latest);
        final trend = GrowthSummary.trendOf(measurements);
        final delta = showMetrics ? GrowthSummary.weightDeltaOf(measurements) : null;

        return _StatusCard(
          summary: summary,
          latest: latest,
          dateLabel: IdDateFormat.full(latest.measuredOn),
          trend: trend,
          weightDelta: delta,
          showMetrics: showMetrics,
          onDetail: () => _showDetail(context, child.nickname, latest),
          onAdd: () => showMeasurementSheet(context),
        );
      },
    );
  }

  void _showDetail(
    BuildContext context,
    String nickname,
    GrowthMeasurement measurement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailSheet(
        nickname: nickname,
        measurement: measurement,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.summary,
    required this.latest,
    required this.dateLabel,
    required this.trend,
    required this.weightDelta,
    required this.showMetrics,
    required this.onDetail,
    required this.onAdd,
  });

  final GrowthStatusSummary summary;
  final GrowthMeasurement latest;
  final String dateLabel;
  final GrowthTrendResult trend;
  final double? weightDelta;
  final bool showMetrics;
  final VoidCallback onDetail;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.statusCardTitle,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToneIcon(tone: summary.tone, label: summary.title),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      summary.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trend.trend != GrowthTrend.insufficientData) ...[
            const SizedBox(height: AppSpacing.md),
            _TrendRow(trend: trend.trend),
          ],
          if (showMetrics) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: colors.outline),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MetricTile(
                    label: AppStrings.growthLatestWeight,
                    value: GrowthStatusCopy.formatKgCm(latest.weightKg),
                    unit: 'kg',
                    footnote: weightDelta == null
                        ? null
                        : GrowthStatusCopy.weightDeltaLabel(weightDelta!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MetricTile(
                    label: AppStrings.growthLatestHeight,
                    value:
                        GrowthStatusCopy.formatKgCm(latest.lengthHeightCm),
                    unit: 'cm',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.straighten_rounded),
            label: const Text(AppStrings.statusAddFirst),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: onDetail,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text(AppStrings.statusViewDetail),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}

class _ToneIcon extends StatelessWidget {
  const _ToneIcon({required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final (icon, color) = switch (tone) {
      StatusTone.good => (Icons.check_circle_rounded, colors.statusGood),
      StatusTone.watch => (Icons.info_rounded, colors.statusWatchText),
      StatusTone.alert => (Icons.warning_rounded, colors.statusAlert),
    };
    return Semantics(
      label: label,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend});

  final GrowthTrend trend;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final needsAttention = trend == GrowthTrend.needsAttention;
    final icon = needsAttention
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    final color =
        needsAttention ? colors.statusWatchText : colors.textSecondary;
    final copy = needsAttention
        ? AppStrings.statusTrendNeedsAttention
        : AppStrings.statusTrendTracked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            copy,
            style: textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: EmptyState(
        icon: Icons.straighten_rounded,
        iconSemantics: AppStrings.growthNoMeasurementsTitle,
        title: AppStrings.growthNoMeasurementsTitle,
        body: AppStrings.growthNoMeasurementsBody,
        action: FilledButton(
          onPressed: onAdd,
          child: const Text(AppStrings.growthNoMeasurementsCta),
        ),
      ),
    );
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton({required this.showMetrics});

  final bool showMetrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Skeleton(width: 120, height: 12),
              Spacer(),
              Skeleton(width: 84, height: 12),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 44, height: 44, radius: 22),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 160, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    Skeleton(height: 12),
                  ],
                ),
              ),
            ],
          ),
          if (showMetrics) ...[
            const SizedBox(height: AppSpacing.xl),
            const Row(
              children: [
                Expanded(child: Skeleton(height: 44)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Skeleton(height: 44)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const Skeleton(height: 48),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.nickname, required this.measurement});

  final String nickname;
  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
      ),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${AppStrings.statusDetailTitle} — $nickname',
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppStrings.statusDetailDate}: '
            '${IdDateFormat.full(measurement.measuredOn)}',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppSurfaces.sunken(context),
            child: ZScoreTable(measurement: measurement),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.statusDetailFootnote,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.actionClose),
          ),
        ],
      ),
    );
  }
}
