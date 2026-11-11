import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/services/measure_correction.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';

/// Grafik pita SD (PRD §6.5): area −2 s.d. +1 (PB/U: +3) hijau lembut,
/// di luarnya kuning/merah lembut, garis median tegas, titik anak di atas.
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Gagal memuat tabel referensi. Muat ulang aplikasi.'),
      ),
      data: (tables) => _buildChart(context, tables),
    );
  }

  Widget _buildChart(BuildContext context, AnthropometryReferenceTables tables) {
    final colors = AppTheme.colorsOf(context);
    final sd = _sdCurves(tables);

    final bars = <LineChartBarData>[
      _curve(sd.sdNeg3, colors.textSecondary, width: 0, dot: false),
      _curve(sd.sdNeg2, colors.textSecondary, width: 1.5, dot: false),
      _curve(sd.upper, colors.textSecondary, width: 1.5, dot: false),
      if (sd.outerUpper != null)
        _curve(sd.outerUpper!, colors.textSecondary, width: 0, dot: false),
      _curve(sd.median, colors.textPrimary, width: 2, dot: false),
      LineChartBarData(
        spots: [
          for (final m in measurements) FlSpot(m.x(index), m.y(index)),
        ],
        isCurved: false,
        color: colors.accent,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) =>
              FlDotCirclePainter(
            radius: 4.5,
            color: colors.accent,
            strokeWidth: 2,
            strokeColor: colors.surface,
          ),
        ),
      ),
    ];

    // Between-bar bands: index curve list differs per mode.
    const lowerNeg3 = 0;
    const lowerNeg2 = 1;
    const upperBand = 2; // haz: sdPos3, others: sdPos1
    final bandData = <BetweenBarsData>[
      BetweenBarsData(
        fromIndex: lowerNeg3,
        toIndex: lowerNeg2,
        color: colors.statusWatch.withValues(alpha: 0.18),
      ),
      BetweenBarsData(
        fromIndex: lowerNeg2,
        toIndex: upperBand,
        color: colors.statusGood.withValues(alpha: 0.18),
      ),
    ];
    if (sd.outerUpper != null) {
      bandData.add(
        BetweenBarsData(
          fromIndex: upperBand,
          toIndex: 3,
          color: colors.statusWatch.withValues(alpha: 0.18),
        ),
      );
    }

    final minY = sd.minY.floorToDouble();
    final maxY = sd.maxY.ceilToDouble();

    return Semantics(
      label: semanticsLabel,
      child: LineChart(
        LineChartData(
          minX: sd.minX,
          maxX: sd.maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.outline.withValues(alpha: 0.6),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: sd.titleInterval,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  meta.formattedValue,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: bars,
          betweenBarsData: bandData,
          lineTouchData: LineTouchData(enabled: false),
        ),
        duration: Duration.zero,
      ),
    );
  }

  LineChartBarData _curve(List<FlSpot> spots, Color color,
      {required double width, required bool dot}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.15,
      color: width == 0 ? Colors.transparent : color,
      barWidth: width,
      dotData: const FlDotData(show: false),
    );
  }

  _SdCurves _sdCurves(AnthropometryReferenceTables tables) {
    final isHaz = index == AnthropometryIndex.haz;
    final isWaz = index == AnthropometryIndex.waz;
    final sexKey = child.sex;

    final sdNeg3 = <FlSpot>[];
    final sdNeg2 = <FlSpot>[];
    final upper = <FlSpot>[];
    final outerUpper = <FlSpot>[];
    final median = <FlSpot>[];

    double minYraw = double.infinity;
    double maxYraw = double.negativeInfinity;
    double minX = double.infinity;
    double maxX = double.negativeInfinity;

    void addSpot(double x, SdColumns sd) {
      minX = x < minX ? x : minX;
      maxX = x > maxX ? x : maxX;
      sdNeg3.add(FlSpot(x, sd.sdNeg3 ?? sd.sdNeg1));
      sdNeg2.add(FlSpot(x, sd.sdNeg2 ?? sd.sdNeg1));
      final bandTop = isHaz ? (sd.sdPos3 ?? sd.sdPos1) : sd.sdPos1;
      upper.add(FlSpot(x, bandTop));
      if (!isHaz) {
        outerUpper.add(FlSpot(x, sd.sdPos3 ?? sd.sdPos1));
      }
      median.add(FlSpot(x, sd.median));
      minYraw = [
        minYraw,
        sd.sdNeg3 ?? sd.sdNeg1,
      ].reduce((a, b) => a < b ? a : b);
      maxYraw = [
        maxYraw,
        sd.sdPos3 ?? sd.sdPos1,
        sd.sdPos1,
      ].reduce((a, b) => a > b ? a : b);
    }

    if (isHaz || isWaz) {
      for (var month = 0; month <= 60; month++) {
        final sd = isHaz
            ? tables.haz(sex: sexKey, ageMonths: month)
            : tables.waz(sex: sexKey, ageMonths: month);
        addSpot(month.toDouble(), sd);
      }
      maxX = 60;
      minX = 0;
    } else {
      final useTb =
          child.ageInCompletedMonths(DateTime.now()) >= 24;
      final info = tables.whzTableInfo(
        sex: sexKey,
        ageMonths: useTb ? 30 : 12,
      );
      for (var cm = info.start; cm <= info.start + (info.length - 1) * info.step + 1e-9;
          cm += info.step) {
        final step = double.parse(cm.toStringAsFixed(1));
        final sd = tables.whz(
          sex: sexKey,
          lengthHeightCmStep: step,
          ageMonths: useTb ? 30 : 12,
        );
        addSpot(step, sd);
      }
      minX = info.start;
      maxX = info.start + (info.length - 1) * info.step;
    }

    final titleInterval = switch (index) {
      AnthropometryIndex.haz => 12.0,
      AnthropometryIndex.waz => 12.0,
      AnthropometryIndex.whz => 10.0,
    };

    return _SdCurves(
      sdNeg3: sdNeg3,
      sdNeg2: sdNeg2,
      upper: upper,
      outerUpper: outerUpper.isEmpty ? null : outerUpper,
      median: median,
      minX: minX,
      maxX: maxX,
      minY: minYraw - 1,
      maxY: maxYraw + 1,
      titleInterval: titleInterval,
    );
  }
}

class _SdCurves {
  const _SdCurves({
    required this.sdNeg3,
    required this.sdNeg2,
    required this.upper,
    required this.outerUpper,
    required this.median,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.titleInterval,
  });

  final List<FlSpot> sdNeg3;
  final List<FlSpot> sdNeg2;
  final List<FlSpot> upper;
  final List<FlSpot>? outerUpper;
  final List<FlSpot> median;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double titleInterval;
}

extension on GrowthMeasurement {
  double x(AnthropometryIndex index) => switch (index) {
        AnthropometryIndex.haz => ageMonths.toDouble(),
        AnthropometryIndex.waz => ageMonths.toDouble(),
        AnthropometryIndex.whz => MeasureCorrection.corrected(
            lengthHeightCm: lengthHeightCm,
            mode: measureMode,
            ageMonths: ageMonths,
          ),
      };

  double y(AnthropometryIndex index) => switch (index) {
        AnthropometryIndex.haz => MeasureCorrection.corrected(
            lengthHeightCm: lengthHeightCm,
            mode: measureMode,
            ageMonths: ageMonths,
          ),
        AnthropometryIndex.waz => weightKg,
        AnthropometryIndex.whz => weightKg,
      };
}
