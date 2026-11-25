import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
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
import 'package:cekgizi/features/growth/presentation/widgets/zscore_summary_strip.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/shared/widgets/child_gate.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';
import 'package:cekgizi/shared/widgets/status_pill.dart';
import 'package:cekgizi/shared/widgets/z_score_table.dart';

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
    return Scaffold(
      floatingActionButton: const TanyaBubble(),
      body: SafeArea(
        // Memuat/gagal/kosong dibedakan oleh ChildGate.
        child: ChildGate(
          builder: (context, child) => _GrowthBody(
            child: child,
            index: _index,
            onIndexChanged: (value) => setState(() => _index = value),
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
    final now = DateTime.now();
    final hasMeasurements = measurementsAsync.value?.isNotEmpty ?? false;
    // Saat data belum ada, cukup satu empty state di kartu status - grafik
    // dan riwayat kosong disembunyikan agar tidak ada tiga blok kosong.
    final showChart = measurementsAsync.isLoading || hasMeasurements;

    // Grafik sengaja full-bleed: blok lain dibungkus padding, grafik tidak.
    Widget block(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: child,
    );

    return ListView(
      key: const Key('growth-list'),
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxxl + AppSpacing.lg,
      ),
      children: [
        block(
          ScreenHeader(
            eyebrow: IdDateFormat.eyebrow(now),
            title: AppStrings.growthTitle,
            subtitle: AppStrings.growthSubtitle,
            trailing: const ChildSwitcherButton(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        block(const GrowthStatusCard(showMetrics: false)),
        if (showChart) ...[
          const SizedBox(height: AppSpacing.lg),
          if (measurementsAsync.value != null &&
              measurementsAsync.value!.isNotEmpty)
            block(
              ZScoreSummaryStrip(
                latest: GrowthSummary.sorted(measurementsAsync.value!).last,
                selected: index,
                onChanged: onIndexChanged,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          GrowthChartCard(
            child: child,
            index: index,
            measurementsAsync: measurementsAsync,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          block(const SectionHeader(title: AppStrings.growthHistoryTitle)),
          const SizedBox(height: AppSpacing.md),
          block(
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
                      style: AppTextStyles.bodySmall.copyWith(
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
          ),
        ],
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
    required this.measurementsAsync,
  });

  final ChildProfile child;
  final AnthropometryIndex index;
  final AsyncValue<List<GrowthMeasurement>> measurementsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);

    // Permukaan grafik menyentuh tepi layar: tidak ada kartu melayang.
    // Kedalaman tetap dari tone + hairline, bukan bayangan.
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline, width: 1),
          bottom: BorderSide(color: colors.outline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.growthChartTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
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
                      final height = (constraints.maxWidth * 0.78).clamp(
                        230.0,
                        320.0,
                      );
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
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          AppStrings.growthChartTapHint,
                          style: AppTextStyles.label.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChartLegend(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.growthChartCaption,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (sorted.length < 2) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            AppStrings.growthTrendHint,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          Icon(Icons.show_chart_rounded, size: 32, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.growthNoMeasurementsBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
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
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
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
                    Container(width: 3, height: 2, color: colors.textSecondary),
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
              child: Container(
                width: 14,
                height: 2,
                color: colors.textSecondary,
              ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          swatch,
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: AppTextStyles.label.copyWith(
                color: AppTheme.colorsOf(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
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

class _MeasurementTile extends ConsumerStatefulWidget {
  const _MeasurementTile({required this.measurement});

  final GrowthMeasurement measurement;

  @override
  ConsumerState<_MeasurementTile> createState() => _MeasurementTileState();
}

class _MeasurementTileState extends ConsumerState<_MeasurementTile> {
  bool _expanded = false;

  Future<void> _confirmDelete(BuildContext context) async {
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
          .deleteMeasurement(widget.measurement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final measurement = widget.measurement;
    final value =
        '${GrowthStatusCopy.formatKgCm(measurement.weightKg)} kg · '
        '${GrowthStatusCopy.formatKgCm(measurement.lengthHeightCm)} cm';
    final category = GrowthStatusCopy.categoryLabel(
      AnthropometryIndex.haz,
      measurement.statusHaz,
    );
    final tone = GrowthStatusCopy.toneOf(
      AnthropometryIndex.haz,
      measurement.statusHaz,
    );

    return Container(
      key: ValueKey('measurement-${measurement.id}'),
      decoration: AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label:
                '$value. $category. '
                '${_expanded ? AppStrings.actionClose : AppStrings.growthHistoryTitle}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              softWrap: true,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: colors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            StatusPill(label: category, tone: tone),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.normal),
            curve: AppMotion.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: colors.outline),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${IdDateFormat.full(measurement.measuredOn)} · '
                              '${measurement.ageMonths} ${AppStrings.childAgeMonths}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: AppSurfaces.sunken(context),
                              child: ZScoreTable(measurement: measurement),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => showMeasurementSheet(
                                    context,
                                    existing: measurement,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(AppStrings.actionEdit),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(context),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(AppStrings.actionDelete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
