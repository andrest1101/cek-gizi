import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/chart/sd_series.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/chart_point_info.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Grafik pita SD (PRD §6.5) yang bisa diketuk untuk ringkasan satu ukuran.
///
/// Pita: −3…−2 SD & +2…+3 SD kuning lembut, −2…+1 SD (PB/U: +3) hijau
/// lembut. Garis ±2 SD putus-putus, median solid, baris anak hijau tua.
/// Sumbu diberi judul + satuan; warna tidak pernah jadi sinyal tunggal.
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
      error: (error, stackTrace) =>
          _ChartError(onRetry: () => ref.invalidate(permenkesTablesProvider)),
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

class _ChartBody extends StatefulWidget {
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
  State<_ChartBody> createState() => _ChartBodyState();
}

class _ChartBodyState extends State<_ChartBody> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final secondary = colors.textSecondary;
    final measurements = widget.measurements;
    final index = widget.index;
    final series = widget.series;

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
      _reference(
        series.neg3,
        secondary.withValues(alpha: 0.35),
        width: 1,
        dashArray: const [4, 4],
      ),
      _reference(series.neg2, secondary, width: 1.5, dashArray: const [6, 4]),
      _reference(series.upper, secondary, width: 1.5, dashArray: const [6, 4]),
      if (hasOuterUpper)
        _reference(
          series.outerUpper,
          secondary.withValues(alpha: 0.35),
          width: 1,
          dashArray: const [4, 4],
        ),
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
          getDotPainter: (spot, percent, barData, dotIndex) =>
              FlDotCirclePainter(
                radius: dotIndex == _selectedIndex ? 6.5 : 4.5,
                color: colors.primary,
                strokeWidth: dotIndex == _selectedIndex ? 3 : 2,
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
    final xName = index == AnthropometryIndex.whz
        ? AppStrings.growthAxisXHeight
        : AppStrings.growthAxisXAge;
    final yName = index == AnthropometryIndex.haz
        ? AppStrings.growthAxisYHeight
        : AppStrings.growthAxisYWeight;

    final selected = _selectedIndex;
    final info = selected != null && selected < measurements.length
        ? ChartPointInfo.from(
            measurement: measurements[selected],
            index: index,
            median: medianAt(
              series.median,
              measurements[selected].chartX(index),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.normal),
          curve: AppMotion.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            switchInCurve: AppMotion.easeOutCubic,
            transitionBuilder: (child, animation) => SlideTransition(
              position: animation.drive(
                Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: info == null
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PointDetail(
                        key: ValueKey(info.semanticsLabel),
                        info: info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: widget.semanticsLabel,
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
                      axisNameWidget: Text(
                        xName,
                        textAlign: TextAlign.center,
                        style: axisStyle,
                      ),
                      axisNameSize: 22,
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
                      axisNameWidget: Text(
                        yName,
                        textAlign: TextAlign.center,
                        style: axisStyle,
                      ),
                      axisNameSize: 22,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toStringAsFixed(0), style: axisStyle),
                      ),
                    ),
                  ),
                  lineBarsData: bars,
                  betweenBarsData: bandData,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchSpotThreshold: 12,
                    // Indicator bawaan muncul instan; feedback halus cukup
                    // dari dot membesar + kartu detail beranimasi.
                    getTouchedSpotIndicator: (barData, spotIndexes) => const [],
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => const [],
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.lineBarSpots == null ||
                          response!.lineBarSpots!.isEmpty) {
                        if (mounted) setState(() => _selectedIndex = null);
                        return;
                      }
                      final childBar = bars.length - 1;
                      final spot = response.lineBarSpots!.firstWhere(
                        (item) => item.barIndex == childBar,
                        orElse: () => response.lineBarSpots!.first,
                      );
                      final tapped = spot.spotIndex;
                      if (tapped >= 0 &&
                          tapped < measurements.length &&
                          mounted) {
                        setState(() => _selectedIndex = tapped);
                      }
                    },
                  ),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ),
      ],
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

/// Kartu ringkas yang muncul saat user mengetuk titik grafik.
class _PointDetail extends StatelessWidget {
  const _PointDetail({super.key, required this.info});

  final ChartPointInfo info;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final (icon, toneColor) = switch (info.tone) {
      StatusTone.good => (Icons.check_circle_rounded, colors.statusGood),
      StatusTone.watch => (Icons.info_rounded, colors.statusWatchText),
      StatusTone.alert => (Icons.warning_rounded, colors.statusAlert),
    };
    return Semantics(
      label: info.semanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.sunken(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: toneColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppStrings.growthPointTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _Detail(
                  label: AppStrings.growthPointDate,
                  value: info.dateLabel,
                ),
                _Detail(label: AppStrings.growthPointAge, value: info.ageLabel),
                _Detail(
                  label: AppStrings.growthPointValue,
                  value: info.valueLabel,
                ),
                _Detail(
                  label: AppStrings.growthPointZScore,
                  value: info.zLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${info.category} · ${info.medianLabel}',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, color: colors.textSecondary),
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
