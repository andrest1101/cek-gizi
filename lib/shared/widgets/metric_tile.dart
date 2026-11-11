import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Satu metrik besar (mis. "8,2 kg") dengan label di atas dan catatan
/// kecil di bawah. Angka memakai tabular figures agar tidak "bergoyang".
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.footnote,
  });

  final String label;

  /// Angka siap tampil, mis. "8,2" (format Indonesia).
  final String value;

  /// Satuan, mis. "kg" / "cm".
  final String unit;

  /// Catatan kecil opsional (mis. selisih berat).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.metricNumber.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              unit,
              style: textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            footnote!,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
