import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement_point.dart';
import 'package:cekgizi/features/growth/domain/services/growth_trend_evaluator.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/add_measurement_sheet.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';

/// Kartu status tumbuh (PRD §6.3, §6.5): status terbaru, tanggal, tren,
/// aksi tambah ukuran & "Lihat detail" (nilai z + kategori resmi).
class GrowthStatusCard extends ConsumerWidget {
  const GrowthStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);
    final child = childAsync.value;
    if (child == null) return const SizedBox.shrink();

    final measurementsAsync = ref.watch(measurementsProvider(child.id));
    return measurementsAsync.when(
      loading: () => const _StatusSkeleton(),
      error: (error, stackTrace) => ErrorCard(
        message:
            'Gagal memuat pengukuran. Periksa koneksi, lalu coba lagi.',
        onRetry: () => ref.invalidate(measurementsProvider(child.id)),
      ),
      data: (measurements) {
        if (measurements.isEmpty) {
          return _EmptyStatus(
            onAdd: () => showMeasurementSheet(context),
          );
        }
        final latest = measurements.last;
        final worst = _worstStatus(measurements.last);
        final trend = _trend(measurements);

        return _StatusCard(
          title: worst.title,
          body: worst.body,
          action: worst.action,
          dateLabel: IdDateFormat.full(latest.measuredOn),
          tone: worst.tone,
          trend: trend,
          onDetail: () => _showDetail(context, child.nickname, latest),
          onAdd: () => showMeasurementSheet(context),
        );
      },
    );
  }

  ({String title, String body, String action, StatusTone tone})
      _worstStatus(GrowthMeasurement latest) {
    final entries = [
      (AnthropometryIndex.haz, latest.statusHaz),
      (AnthropometryIndex.waz, latest.statusWaz),
      (AnthropometryIndex.whz, latest.statusWhz),
    ];
    entries.sort(
      (a, b) => GrowthStatusCopy.severity(b.$1, b.$2)
          .compareTo(GrowthStatusCopy.severity(a.$1, a.$2)),
    );
    final chosen = entries.first;
    final copy = GrowthStatusCopy.forIndex(chosen.$1, chosen.$2);
    return (
      title: copy.title,
      body: copy.body,
      action: copy.action,
      tone: copy.tone,
    );
  }

  GrowthTrendResult _trend(List<GrowthMeasurement> measurements) {
    return GrowthTrendEvaluator.evaluate([
      for (final m in measurements)
        GrowthMeasurementPoint(
          measuredOn: m.measuredOn,
          weightKg: m.weightKg,
          hazStatusCode: m.statusHaz,
        ),
    ]);
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
    required this.title,
    required this.body,
    required this.action,
    required this.dateLabel,
    required this.tone,
    required this.trend,
    required this.onDetail,
    required this.onAdd,
  });

  final String title;
  final String body;
  final String action;
  final String dateLabel;
  final StatusTone tone;
  final GrowthTrendResult trend;
  final VoidCallback onDetail;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = switch (tone) {
      StatusTone.good => (Icons.check_circle_rounded, colors.statusGood),
      StatusTone.watch => (Icons.info_rounded, colors.statusWatchText),
      StatusTone.alert => (Icons.warning_rounded, colors.statusAlert),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.statusCardTitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: title,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
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
                    const SizedBox(height: AppSpacing.xs),
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
          ),
          const SizedBox(height: AppSpacing.md),
          if (trend.trend == GrowthTrend.needsAttention)
            Row(
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 18,
                  color: colors.statusWatchText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    AppStrings.statusTrendNeedsAttention,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.statusWatchText,
                    ),
                  ),
                ),
              ],
            )
          else if (trend.trend == GrowthTrend.tracked)
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: colors.statusGood,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    AppStrings.statusTrendTracked,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetail,
                  child: const Text(AppStrings.statusViewDetail),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: const Text(AppStrings.statusAddFirst),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.straighten_rounded, size: 40, color: colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.growthNoMeasurementsTitle,
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.growthNoMeasurementsBody,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onAdd,
            child: const Text(AppStrings.growthNoMeasurementsCta),
          ),
        ],
      ),
    );
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      height: 152,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
    final rows = [
      (AppStrings.hazLabel, measurement.haz, measurement.statusHaz,
          AnthropometryIndex.haz),
      (AppStrings.wazLabel, measurement.waz, measurement.statusWaz,
          AnthropometryIndex.waz),
      (AppStrings.whzLabel, measurement.whz, measurement.statusWhz,
          AnthropometryIndex.whz),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          for (final (label, z, status, index) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(label, style: textTheme.bodyMedium),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${AppStrings.statusDetailZScore} '
                      '${GrowthStatusCopy.formatZ(z)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      status == null
                          ? AppStrings.statusOutOfRangeShort
                          : '${AppStrings.statusDetailCategory}: '
                              '${GrowthStatusCopy.officialCategories(index)[status] ?? status}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
