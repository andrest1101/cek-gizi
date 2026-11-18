import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Ringkasan tiga z-score pengukuran terakhir, sekaligus pemilih indeks grafik.
///
/// Menggantikan `SegmentControl` terpisah di kartu grafik: satu baris dengan
/// tiga ubin yang punya label, angka, dan status (ikon + teks + warna).
class ZScoreSummaryStrip extends StatelessWidget {
  const ZScoreSummaryStrip({
    super.key,
    required this.latest,
    required this.selected,
    required this.onChanged,
  });

  final GrowthMeasurement latest;
  final AnthropometryIndex selected;
  final ValueChanged<AnthropometryIndex> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      // ListView memberi constraint tinggi tak-terbatas: `stretch` di sini
      // akan memaksa tinggi infinity. Beri tinggi eksplisit agar aman.
      child: SizedBox(
        height: 112,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final index in AnthropometryIndex.values) ...[
              if (index != AnthropometryIndex.haz)
                SizedBox(
                  width: 1,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: colors.outline,
                  ),
                ),
              Expanded(
                child: _ZTile(
                  index: index,
                  measurement: latest,
                  selected: index == selected,
                  onTap: () => onChanged(index),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZTile extends StatelessWidget {
  const _ZTile({
    required this.index,
    required this.measurement,
    required this.selected,
    required this.onTap,
  });

  final AnthropometryIndex index;
  final GrowthMeasurement measurement;
  final bool selected;
  final VoidCallback onTap;

  (String, String?, double) get _data => switch (index) {
        AnthropometryIndex.haz => (
          AppStrings.growthTabLengthHeightShort,
          measurement.statusHaz,
          measurement.haz,
        ),
        AnthropometryIndex.waz => (
          AppStrings.growthTabWeightShort,
          measurement.statusWaz,
          measurement.waz,
        ),
        AnthropometryIndex.whz => (
          AppStrings.growthTabWeightHeightShort,
          measurement.statusWhz,
          measurement.whz,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final (label, statusCode, z) = _data;
    final tone = GrowthStatusCopy.toneOf(index, statusCode);
    final status = GrowthStatusCopy.categoryLabel(index, statusCode);
    final (icon, iconColor) = switch (tone) {
      StatusTone.good => (Icons.check_circle_rounded, colors.statusGood),
      StatusTone.watch => (Icons.info_rounded, colors.statusWatchText),
      StatusTone.alert => (Icons.warning_rounded, colors.statusAlert),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '$label. z ${GrowthStatusCopy.formatZ(z)}. $status',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: selected ? colors.primary : colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  GrowthStatusCopy.formatZ(z),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: iconColor),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: iconColor,
                          fontSize: 9,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
