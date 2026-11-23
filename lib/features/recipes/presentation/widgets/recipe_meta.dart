/// Meta kecil pada kartu & detail resep. Semua penanda memakai ikon + teks
/// (tidak pernah warna saja) dan token tema - tanpa warna literal.
library;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

TextStyle get _pillStyle => AppTextStyles.label.copyWith(
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w600,
);

/// Waktu memasak (ikon jam + teks, tanpa latar).
class RecipeMinutesMeta extends StatelessWidget {
  const RecipeMinutesMeta({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            AppStrings.recipesMinutes(minutes),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pillStyle.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Pil rentang usia (tonal hijau).
class RecipeBandPill extends StatelessWidget {
  const RecipeBandPill({super.key, required this.bandCode});

  final String bandCode;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _Pill(
      background: colors.primaryContainer,
      foreground: colors.primary,
      icon: Icons.child_care_rounded,
      label: AppStrings.recipesFilterBandLabel(bandCode),
    );
  }
}

/// Pil protein hewani (tonal hangat) - selalu ikon + teks.
class RecipeProteinPill extends StatelessWidget {
  const RecipeProteinPill({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _Pill(
      background: colors.accentContainer,
      foreground: colors.onAccentContainer,
      icon: Icons.set_meal_rounded,
      label: AppStrings.recipesProteinBadge,
    );
  }
}

/// Chip kelompok pangan (netral, bukan tombol).
class RecipeGroupChip extends StatelessWidget {
  const RecipeGroupChip({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.pill),
      child: Text(
        AppStrings.groupShortLabel(code),
        style: _pillStyle.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Penanda jumlah kelompok yang tidak ditampilkan sebagai chip (mis. "+2").
class RecipeGroupOverflowChip extends StatelessWidget {
  const RecipeGroupOverflowChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppSurfaces.sunken(context, radius: AppRadius.pill),
      child: Text(
        AppStrings.recipesMoreGroups(count),
        style: _pillStyle.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Satu baris meta: waktu memasak · jumlah kelompok pangan.
///
/// Memakai [Wrap] agar tetap aman di 360dp pada text scale 1,3.
class RecipeMetaRow extends StatelessWidget {
  const RecipeMetaRow({
    super.key,
    required this.minutes,
    required this.groupCount,
  });

  final int minutes;
  final int groupCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final style = _pillStyle.copyWith(color: colors.textSecondary);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RecipeMinutesMeta(minutes: minutes),
        Text('·', style: style),
        Text(AppStrings.recipesGroupCountShort(groupCount), style: style),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pillStyle.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
