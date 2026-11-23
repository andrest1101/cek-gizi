import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/recipes/presentation/widgets/recipe_group_thumb.dart';

/// Foto resep dari aset lokal yang sudah dioptimasi.
///
/// Konvensi nama: `assets/recipes/images/<id resep>.jpg` - dibuat oleh
/// `tool/optimize_recipe_images.py` sehingga aplikasi tidak perlu menebak
/// nama berkas. Bila berkas tidak tersedia (mis. resep uji tanpa aset),
/// widget jatuh ke kolase logo kelompok pangan: tidak pernah kotak rusak.
class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.recipeId,
    required this.groups,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.borderRadius = BorderRadius.zero,
  });

  static const String directory = 'assets/recipes/images';

  /// Path aset untuk [recipeId] - satu sumber kebenaran konvensi nama.
  static String assetFor(String recipeId) => '$directory/$recipeId.jpg';

  final String recipeId;
  final List<String> groups;
  final BoxFit fit;

  /// Lebar decode (piksel fisik) untuk menghemat memori pada thumbnail.
  /// Null = ukuran asli aset (1280 px).
  final int? decodeWidth;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        assetFor(recipeId),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: decodeWidth,
        filterQuality: FilterQuality.medium,
        // Foto bersifat dekoratif: judul & isi sudah diumumkan kartu/header.
        excludeFromSemantics: true,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return ColoredBox(color: colors.surfaceVariant);
        },
        errorBuilder: (context, error, stackTrace) =>
            _RecipeImageFallback(groups: groups),
      ),
    );
  }
}

/// Pengganti foto: kolase logo kelompok pangan di permukaan tonal.
class _RecipeImageFallback extends StatelessWidget {
  const _RecipeImageFallback({required this.groups});

  final List<String> groups;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 120.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 120.0;
        final size = math.min(width, height).clamp(64.0, 132.0);
        return ColoredBox(
          color: colors.surfaceVariant,
          child: Center(
            child: RecipeGroupThumb(groups: groups, size: size),
          ),
        );
      },
    );
  }
}
