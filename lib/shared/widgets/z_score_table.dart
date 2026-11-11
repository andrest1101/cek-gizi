import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Tabel tiga indeks (PB/U, BB/U, BB/PB) untuk satu pengukuran:
/// label indeks, kategori resmi, dan skor z. Dipakai sheet "Lihat detail"
/// dan dialog hasil simpan agar angkanya selalu tampil dengan format sama.
class ZScoreTable extends StatelessWidget {
  const ZScoreTable({super.key, required this.measurement});

  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final rows = <({String label, double z, String? status, AnthropometryIndex index})>[
      (
        label: AppStrings.hazLabel,
        z: measurement.haz,
        status: measurement.statusHaz,
        index: AnthropometryIndex.haz,
      ),
      (
        label: AppStrings.wazLabel,
        z: measurement.waz,
        status: measurement.statusWaz,
        index: AnthropometryIndex.waz,
      ),
      (
        label: AppStrings.whzLabel,
        z: measurement.whz,
        status: measurement.statusWhz,
        index: AnthropometryIndex.whz,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: AppSpacing.xxl),
          _Row(row: rows[i], textTheme: textTheme, colors: colors),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.textTheme,
    required this.colors,
  });

  final ({String label, double z, String? status, AnthropometryIndex index})
      row;
  final TextTheme textTheme;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final category = row.status == null
        ? AppStrings.statusOutOfRangeShort
        : GrowthStatusCopy.officialCategories(row.index)[row.status] ??
            row.status!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppStrings.statusDetailZScore,
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              GrowthStatusCopy.formatZ(row.z),
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
