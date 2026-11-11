import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/services/measure_correction.dart';

/// Titik grafik (x, y) tanpa ketergantungan paket chart — mudah diuji.
typedef SdPoint = ({double x, double y});

/// Kumpulan kurva rujukan SD + rentang sumbu untuk satu indeks.
final class SdSeries {
  const SdSeries({
    required this.neg3,
    required this.neg2,
    required this.upper,
    required this.outerUpper,
    required this.median,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xInterval,
    required this.upperIsPos3,
  });

  /// Batas bawah luar (−3 SD) — garis bantu.
  final List<SdPoint> neg3;

  /// Batas bawah klasifikasi (−2 SD).
  final List<SdPoint> neg2;

  /// Batas atas klasifikasi: HAZ memakai +3 SD, lainnya +1 SD.
  final List<SdPoint> upper;

  /// Batas atas luar (+3 SD) untuk WAZ/WHZ; kosong untuk HAZ.
  final List<SdPoint> outerUpper;

  final List<SdPoint> median;

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  /// Jarak label sumbu X (bulan atau cm).
  final double xInterval;

  /// `upper` diambil dari kolom +3 SD (HAZ) — dipakai memilih pita.
  final bool upperIsPos3;
}

/// Membangun [SdSeries] dari tabel Permenkes 2/2020 (PRD §6.5).
abstract final class SdSeriesBuilder {
  const SdSeriesBuilder._();

  static const double _hazWazMaxMonth = 60;

  static SdSeries build({
    required AnthropometryIndex index,
    required Sex sex,
    required bool useTbTable,
    required AnthropometryReferenceTables tables,
  }) {
    final isHaz = index == AnthropometryIndex.haz;
    final isWaz = index == AnthropometryIndex.waz;

    final neg3 = <SdPoint>[];
    final neg2 = <SdPoint>[];
    final upper = <SdPoint>[];
    final outerUpper = <SdPoint>[];
    final median = <SdPoint>[];

    var minYraw = double.infinity;
    var maxYraw = double.negativeInfinity;
    var minX = double.infinity;
    var maxX = double.negativeInfinity;

    void addPoint(double x, SdColumns sd) {
      final lower = sd.sdNeg3 ?? sd.sdNeg1;
      final bandTop = isHaz ? (sd.sdPos3 ?? sd.sdPos1) : sd.sdPos1;
      final outerTop = sd.sdPos3 ?? sd.sdPos1;

      minX = x < minX ? x : minX;
      maxX = x > maxX ? x : maxX;
      neg3.add((x: x, y: lower));
      neg2.add((x: x, y: sd.sdNeg2 ?? sd.sdNeg1));
      upper.add((x: x, y: bandTop));
      if (!isHaz) outerUpper.add((x: x, y: outerTop));
      median.add((x: x, y: sd.median));

      minYraw = lower < minYraw ? lower : minYraw;
      final top = outerTop > sd.sdPos1 ? outerTop : sd.sdPos1;
      maxYraw = top > maxYraw ? top : maxYraw;
    }

    if (isHaz || isWaz) {
      for (var month = 0; month <= _hazWazMaxMonth; month++) {
        final sd = isHaz
            ? tables.haz(sex: sex, ageMonths: month)
            : tables.waz(sex: sex, ageMonths: month);
        addPoint(month.toDouble(), sd);
      }
      minX = 0;
      maxX = _hazWazMaxMonth;
    } else {
      final ageMonthsForTable = useTbTable ? 30 : 12;
      final info = tables.whzTableInfo(
        sex: sex,
        ageMonths: ageMonthsForTable,
      );
      final lastCm = info.start + (info.length - 1) * info.step;
      for (var cm = info.start; cm <= lastCm + 1e-9; cm += info.step) {
        final step = double.parse(cm.toStringAsFixed(1));
        final sd = tables.whz(
          sex: sex,
          lengthHeightCmStep: step,
          ageMonths: ageMonthsForTable,
        );
        addPoint(step, sd);
      }
      minX = info.start;
      maxX = lastCm;
    }

    return SdSeries(
      neg3: neg3,
      neg2: neg2,
      upper: upper,
      outerUpper: outerUpper,
      median: median,
      minX: minX,
      maxX: maxX,
      minY: minYraw - 1,
      maxY: maxYraw + 1,
      xInterval: index == AnthropometryIndex.whz ? 10 : 12,
      upperIsPos3: isHaz,
    );
  }
}

/// Pemetaan satu pengukuran ke titik grafik (dengan koreksi 0,7 cm).
extension GrowthMeasurementChartPoint on GrowthMeasurement {
  double chartX(AnthropometryIndex index) => switch (index) {
        AnthropometryIndex.haz => ageMonths.toDouble(),
        AnthropometryIndex.waz => ageMonths.toDouble(),
        AnthropometryIndex.whz => MeasureCorrection.corrected(
            lengthHeightCm: lengthHeightCm,
            mode: measureMode,
            ageMonths: ageMonths,
          ),
      };

  double chartY(AnthropometryIndex index) => switch (index) {
        AnthropometryIndex.haz => MeasureCorrection.corrected(
            lengthHeightCm: lengthHeightCm,
            mode: measureMode,
            ageMonths: ageMonths,
          ),
        AnthropometryIndex.waz => weightKg,
        AnthropometryIndex.whz => weightKg,
      };
}
