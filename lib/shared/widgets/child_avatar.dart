import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// 8 avatar ilustrasi untuk profil anak (bukan foto asli - PRD §0 #7).
abstract final class AvatarCatalog {
  const AvatarCatalog._();

  static const Map<String, IconData> icons = {
    'sprout': Icons.spa_rounded,
    'sun': Icons.light_mode_rounded,
    'star': Icons.star_rounded,
    'leaf': Icons.eco_rounded,
    'heart': Icons.favorite_rounded,
    'cloud': Icons.cloud_rounded,
    'flower': Icons.local_florist_rounded,
    'moon': Icons.bedtime_rounded,
  };

  static IconData of(String key) => icons[key] ?? Icons.spa_rounded;
}

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.avatarKey,
    this.size = 44,
    this.semanticLabel,
  });

  final String avatarKey;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      label: semanticLabel ?? 'Avatar anak',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          AvatarCatalog.of(avatarKey),
          size: size * 0.56,
          color: colors.primary,
        ),
      ),
    );
  }
}
