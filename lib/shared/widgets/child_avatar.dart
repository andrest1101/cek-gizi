import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/shared/illustrations/child_avatar_figure.dart';

/// Avatar anak: foto lokal bila ada, atau satu dari dua ilustrasi default
/// yang otomatis mengikuti jenis kelamin.
///
/// Foto TIDAK pernah diunggah - lihat `ChildPhotoStore`. Avatar lama dengan
/// `avatar_key` seperti `sprout` tetap tampil benar karena bentuk default
/// ditentukan oleh [sex], bukan key lama.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.sex,
    this.avatarKey,
    this.photo,
    this.size = 44,
    this.semanticLabel,
  });

  final Sex sex;

  /// Dipertahankan untuk kompatibilitas data lama; tidak lagi menentukan
  /// bentuk avatar.
  final String? avatarKey;

  /// Foto profil dari penyimpanan lokal. Bila null, ilustrasi default dipakai.
  final ImageProvider? photo;

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final label =
        semanticLabel ??
        AppStrings.childAvatarDefaultSemantics(
          sex == Sex.male ? AppStrings.childSexMale : AppStrings.childSexFemale,
        );

    return Semantics(
      label: label,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: photo == null
            ? _DefaultFigure(sex: sex, size: size, colors: colors)
            : Image(
                image: photo!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _DefaultFigure(sex: sex, size: size, colors: colors),
              ),
      ),
    );
  }
}

class _DefaultFigure extends StatelessWidget {
  const _DefaultFigure({
    required this.sex,
    required this.size,
    required this.colors,
  });

  final Sex sex;
  final double size;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: ChildAvatarFigurePainter(
        color: colors.primary,
        sex: sex,
        highlightColor: colors.onPrimary.withValues(alpha: 0.18),
      ),
    );
  }
}
