import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Ringkasan tiga z-score pengukuran terakhir, sekaligus pemilih indeks grafik.
///
/// Tiga ubin sama tinggi, terpusat vertikal: label → angka z (dominan) →
/// status ikon+teks. Terpilih diberi latar `primaryContainer` + hairline
/// `primary`; tidak terpilih transparan. Tidak ada divider kaku.
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
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.sm),
      // ListView memberi constraint tinggi tak-terbatas; `stretch` di dalam
      // Row butuh tinggi terukur → `IntrinsicHeight` menghitung tinggi
      // mengikuti ubin tertinggi (bukan stretch infinity).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final index in AnthropometryIndex.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _ZTile(
                    index: index,
                    measurement: latest,
                    selected: index == selected,
                    onTap: () => onChanged(index),
                  ),
                ),
              ),
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
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? colors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: selected
                    ? Border.all(color: colors.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? colors.primary : colors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    GrowthStatusCopy.formatZ(z),
                    style: AppTextStyles.heroNumber.copyWith(
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: AppSpacing.xs - 2),
                      Flexible(
                        child: Text(
                          status,
                          maxLines: 2,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            color: iconColor,
                            fontSize: 10.5,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
