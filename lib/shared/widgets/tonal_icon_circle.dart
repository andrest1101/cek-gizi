import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ikon di lingkaran tonal (PRD §7.6): satu gaya visual untuk semua ikon
/// besar di empty/error state. Target sentuh ≥ 48dp tidak relevan (bukan
/// tombol), tetapi tooltip/Semantics wajib.
class TonalIconCircle extends StatelessWidget {
  const TonalIconCircle({
    super.key,
    required this.icon,
    required this.iconSemantics,
    this.size = 64,
    this.iconSize = 30,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;

  /// Label untuk pembaca layar (PRD §7.7) - wajib, jangan kosong.
  final String iconSemantics;

  final double size;
  final double iconSize;

  /// Default: `primaryContainer`; bisa ditimpa komponen (mis. error).
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      label: iconSemantics,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? colors.primary,
        ),
      ),
    );
  }
}
