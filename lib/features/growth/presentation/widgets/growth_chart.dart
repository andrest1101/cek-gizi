import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/chart/sd_series.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Grafik pita SD (PRD §6.5).
///
/// Pita: −3…−2 SD & +2…+3 SD kuning lembut, −2…+1 SD (PB/U: +3) hijau
/// lembut. Garis ±2 SD putus-putus, median solid, baris anak hijau tua.
/// Warna tidak pernah jadi sinyal tunggal - legenda teks ada di kartu.
class GrowthChart extends ConsumerWidget {
  const GrowthChart({
    super.key,
    required this.child,
    required this.measurements,
    required this.index,
    required this.semanticsLabel,
  });

  final ChildProfile child;
  final List<GrowthMeasurement> measurements;
  final AnthropometryIndex index;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(permenkesTablesProvider);
    return tablesAsync.when(
      loading: () => const Skeleton(height: 220),
      error: (error, stackTrace) => _ChartError(
        onRetry: () => ref.invalidate(permenkesTablesProvider),
      ),
      data: (tables) => _ChartBody(
        measurements: measurements,
        index: index,
        semanticsLabel: semanticsLabel,
        series: SdSeriesBuilder.build(
          index: index,
          sex: child.sex,
          useTbTable: child.ageInCompletedMonths(DateTime.now()) >= 24,
          tables: tables,
        ),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.measurements,
    required this.index,
    required this.semanticsLabel,
    required this.series,
  });

  final List<GrowthMeasurement> measurements;
  final AnthropometryIndex index;
  final String semanticsLabel;
  final SdSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final secondary = colors.textSecondary;

    final hasOuterUpper = series.outerUpper.isNotEmpty;
    final bandData = <BetweenBarsData>[
      BetweenBarsData(
        fromIndex: 0,
        toIndex: 1,
        color: colors.statusWatch.withValues(alpha: 0.16),
      ),
      BetweenBarsData(
        fromIndex: 1,
        toIndex: 2,
        color: colors.statusGood.withValues(alpha: 0.18),
      ),
      if (hasOuterUpper)
        BetweenBarsData(
          fromIndex: 2,
          toIndex: 3,
          color: colors.statusWatch.withValues(alpha: 0.16),
        ),
    ];

    final bars = <LineChartBarData>[
      _reference(series.neg3, secondary.withValues(alpha: 0.35),
          width: 1, dashArray: const [4, 4]),
      _reference(series.neg2, secondary,
          width: 1.5, dashArray: const [6, 4]),
      _reference(series.upper, secondary,
          width: 1.5, dashArray: const [6, 4]),
      if (hasOuterUpper)
        _reference(series.outerUpper, secondary.withValues(alpha: 0.35),
            width: 1, dashArray: const [4, 4]),
      _reference(series.median, secondary, width: 2),
      LineChartBarData(
        spots: [
          for (final measurement in measurements)
            FlSpot(measurement.chartX(index), measurement.chartY(index)),
        ],
        isCurved: false,
        color: colors.primary,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, i) => FlDotCirclePainter(
            radius: 4.5,
            color: colors.primary,
            strokeWidth: 2,
            strokeColor: colors.surface,
          ),
        ),
      ),
    ];

    final minY = series.minY.floorToDouble();
    final maxY = series.maxY.ceilToDouble();
    final axisStyle = AppTextStyles.label.copyWith(
      fontSize: 11,
      color: secondary,
    );

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: LineChart(
          LineChartData(
            minX: series.minX,
            maxX: series.maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.outline.withValues(alpha: 0.7),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: series.xInterval,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(meta.formattedValue, style: axisStyle),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: (maxY - minY) / 4,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: axisStyle,
                  ),
                ),
              ),
            ),
            lineBarsData: bars,
            betweenBarsData: bandData,
            lineTouchData: const LineTouchData(enabled: false),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  LineChartBarData _reference(
    List<SdPoint> points,
    Color color, {
    required double width,
    List<int>? dashArray,
  }) {
    return LineChartBarData(
      spots: [for (final point in points) FlSpot(point.x, point.y)],
      isCurved: true,
      curveSmoothness: 0.15,
      color: color,
      barWidth: width,
      dashArray: dashArray,
      dotData: const FlDotData(show: false),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.growthReferenceError,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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
