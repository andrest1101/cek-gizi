import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';

/// Satu pilihan pada [SegmentControl].
final class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    required this.semanticLabel,
  });

  final T value;

  /// Teks pendek yang tampil (mis. "Tinggi").
  final String label;

  /// Nama lengkap untuk pembaca layar (mis. "Grafik tinggi menurut umur").
  final String semanticLabel;
}

/// Kontrol segmen pill (pengganti `TabBar`/`SegmentedButton`).
///
/// Dipakai untuk memilih indeks grafik, cara ukur, dan jenis kelamin.
/// Label pendek + [SegmentOption.semanticLabel] agar tidak meluber di
/// 360dp pada text scale 1.3 (PRD §7.7).
class SegmentControl<T> extends StatelessWidget {
  const SegmentControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.pill),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                isSelected: option.value == selected,
                colors: colors,
                onTap: () {
                  if (option.value != selected) onChanged(option.value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppSurfaces.cardColor(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: isSelected
                  ? Border.all(color: colors.outline, width: 1)
                  : null,
            ),
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colors.textPrimary
                    : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
