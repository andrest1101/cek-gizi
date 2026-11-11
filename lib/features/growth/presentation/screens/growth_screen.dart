import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/growth_summary.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/add_measurement_sheet.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_chart.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/shared/widgets/child_identity_row.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';
import 'package:cekgizi/shared/widgets/status_pill.dart';

/// Layar Tumbuh (PRD §6.5): status terbaru, grafik pita SD, riwayat ukur.
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen> {
  AnthropometryIndex _index = AnthropometryIndex.haz;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.growthTitle)),
      body: SafeArea(
        child: child == null
            ? const _NoChild()
            : _GrowthBody(
                child: child,
                index: _index,
                onIndexChanged: (value) => setState(() => _index = value),
              ),
      ),
    );
  }
}

class _NoChild extends StatelessWidget {
  const _NoChild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState(
          icon: Icons.child_care_rounded,
          title: AppStrings.growthNoChildTitle,
          body: AppStrings.growthNoChildBody,
          action: FilledButton(
            onPressed: () => context.push('/children/add'),
            child: const Text(AppStrings.growthNoChildCta),
          ),
        ),
      ),
    );
  }
}

class _GrowthBody extends ConsumerWidget {
  const _GrowthBody({
    required this.child,
    required this.index,
    required this.onIndexChanged,
  });

  final ChildProfile child;
  final AnthropometryIndex index;
  final ValueChanged<AnthropometryIndex> onIndexChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(measurementsProvider(child.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        ChildIdentityRow(child: child),
        const SizedBox(height: AppSpacing.lg),
        const GrowthStatusCard(showMetrics: false),
        const SizedBox(height: AppSpacing.lg),
        GrowthChartCard(
          child: child,
          index: index,
          onIndexChanged: onIndexChanged,
          measurementsAsync: measurementsAsync,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionHeader(title: AppStrings.growthHistoryTitle),
        const SizedBox(height: AppSpacing.md),
        measurementsAsync.when(
          loading: () => const _HistorySkeleton(),
          error: (error, stackTrace) => ErrorCard(
            message: AppStrings.growthLoadError,
            onRetry: () => ref.invalidate(measurementsProvider(child.id)),
          ),
          data: (measurements) {
            final sorted = GrowthSummary.sorted(measurements);
            if (sorted.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppSurfaces.sunken(context),
                child: Text(
                  AppStrings.growthHistoryEmpty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorsOf(context).textSecondary,
                      ),
                ),
              );
            }
            return Column(
              children: [
                for (final measurement in sorted.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _MeasurementTile(measurement: measurement),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Kartu grafik: pemilih indeks, grafik pita SD, legenda, dan sumber tabel.
class GrowthChartCard extends ConsumerWidget {
  const GrowthChartCard({
    super.key,
    required this.child,
    required this.index,
    required this.onIndexChanged,
    required this.measurementsAsync,
  });

  final ChildProfile child;
  final AnthropometryIndex index;
  final ValueChanged<AnthropometryIndex> onIndexChanged;
  final AsyncValue<List<GrowthMeasurement>> measurementsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.growthChartTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentControl<AnthropometryIndex>(
            selected: index,
            onChanged: onIndexChanged,
            options: const <SegmentOption<AnthropometryIndex>>[
              SegmentOption(
                value: AnthropometryIndex.haz,
                label: AppStrings.growthTabLengthHeightShort,
                semanticLabel: AppStrings.growthTabLengthHeightSemantics,
              ),
              SegmentOption(
                value: AnthropometryIndex.waz,
                label: AppStrings.growthTabWeightShort,
                semanticLabel: AppStrings.growthTabWeightSemantics,
              ),
              SegmentOption(
                value: AnthropometryIndex.whz,
                label: AppStrings.growthTabWeightHeightShort,
                semanticLabel: AppStrings.growthTabWeightHeightSemantics,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          measurementsAsync.when(
            loading: () => const Skeleton(height: 240),
            error: (error, stackTrace) => _ChartError(
              onRetry: () => ref.invalidate(measurementsProvider(child.id)),
            ),
            data: (measurements) {
              final sorted = GrowthSummary.sorted(measurements);
              if (sorted.isEmpty) return const _ChartEmpty();
              final latest = sorted.last;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final height = (constraints.maxWidth * 0.78)
                          .clamp(230.0, 320.0);
                      return SizedBox(
                        height: height,
                        child: GrowthChart(
                          child: child,
                          measurements: sorted,
                          index: index,
                          semanticsLabel: _semanticsLabel(latest, index),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChartLegend(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.growthChartCaption,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _semanticsLabel(
    GrowthMeasurement latest,
    AnthropometryIndex index,
  ) {
    final value = switch (index) {
      AnthropometryIndex.haz =>
        'Tinggi ${GrowthStatusCopy.formatKgCm(latest.lengthHeightCm)} cm',
      AnthropometryIndex.waz =>
        'Berat ${GrowthStatusCopy.formatKgCm(latest.weightKg)} kg',
      AnthropometryIndex.whz =>
        'Berat ${GrowthStatusCopy.formatKgCm(latest.weightKg)} kg menurut '
            'panjang/tinggi',
    };
    return 'Grafik pertumbuhan. Pengukuran terakhir $value, '
        'usia ${latest.ageMonths} bulan.';
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 32,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.growthNoMeasurementsBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.growthReferenceError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
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

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(
          label: AppStrings.growthLegendBand,
          swatch: Container(
            width: 14,
            height: 12,
            decoration: BoxDecoration(
              color: colors.statusGood.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        _LegendItem(
          label: AppStrings.growthLegendLimit,
          swatch: SizedBox(
            width: 14,
            height: 12,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 3,
                      height: 2,
                      color: colors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        _LegendItem(
          label: AppStrings.growthLegendMedian,
          swatch: SizedBox(
            width: 14,
            height: 12,
            child: Center(
              child: Container(width: 14, height: 2, color: colors.textSecondary),
            ),
          ),
        ),
        _LegendItem(
          label: AppStrings.growthLegendChild,
          swatch: SizedBox(
            width: 14,
            height: 12,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.swatch});

  final String label;
  final Widget swatch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.colorsOf(context).textSecondary,
              ),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Skeleton(height: 84),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 84),
      ],
    );
  }
}

class _MeasurementTile extends ConsumerWidget {
  const _MeasurementTile({required this.measurement});

  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final category = GrowthStatusCopy.categoryLabel(
      AnthropometryIndex.haz,
      measurement.statusHaz,
    );
    final tone = GrowthStatusCopy.toneOf(
      AnthropometryIndex.haz,
      measurement.statusHaz,
    );

    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${GrowthStatusCopy.formatKgCm(measurement.weightKg)} kg · '
                      '${GrowthStatusCopy.formatKgCm(measurement.lengthHeightCm)} cm',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${IdDateFormat.full(measurement.measuredOn)} · '
                      '${measurement.ageMonths} ${AppStrings.childAgeMonths}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: AppStrings.growthOptionsTooltip,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.textSecondary,
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await showMeasurementSheet(
                        context,
                        existing: measurement,
                      );
                    case 'delete':
                      await _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(AppStrings.actionEdit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(AppStrings.actionDelete),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: StatusPill(label: category, tone: tone),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.growthDeleteTitle),
        content: const Text(AppStrings.growthDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final childId = ref.read(selectedChildProvider).value?.id;
      if (childId == null) return;
      await ref
          .read(measurementsProvider(childId).notifier)
          .deleteMeasurement(measurement.id);
    }
  }
}
