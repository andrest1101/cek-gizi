import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';

/// Pill status (PRD §7.2: warna status tidak pernah sinyal tunggal —
/// selalu disertai ikon dan teks).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final (icon, color) = switch (tone) {
      StatusTone.good => (Icons.check_circle_rounded, colors.statusGood),
      StatusTone.watch => (Icons.info_rounded, colors.statusWatchText),
      StatusTone.alert => (Icons.warning_rounded, colors.statusAlert),
    };
    final fill = switch (tone) {
      StatusTone.good => colors.statusGood.withValues(alpha: 0.12),
      StatusTone.watch => colors.statusWatch.withValues(alpha: 0.16),
      StatusTone.alert => colors.statusAlert.withValues(alpha: 0.12),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
