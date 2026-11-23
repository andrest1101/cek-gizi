import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Mark AI Tanya Gizi (aset mono putih, latar transparan).
///
/// Mono-white + [BlendMode.srcIn] membuat mark mengikuti `colors.primary`
/// (hijau tua di light, mint di dark) sehingga kontras terjaga di kedua tema
/// dan siluet tetap terbaca pada ukuran kecil. Aset duotone disimpan untuk
/// penempatan brand berukuran besar di permukaan terang.
class TanyaAiMark extends StatelessWidget {
  const TanyaAiMark({super.key, this.size = 22});

  static const String assetPath = 'assets/logo/tanya_gizi_mono_white_1024.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: colors.primary,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      // Label peran diumumkan oleh induk (mis. lingkaran header).
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.spa_rounded, size: size, color: colors.primary),
    );
  }
}
