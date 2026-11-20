import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Penampil foto profil full-screen ala profil LinkedIn.
///
/// Aksi: **Atur** (crop ulang), **Hapus** (hapus foto), **Selesai**.
/// Tidak ada "Perbarui" di sini — penggantian foto sudah tersedia di form
/// data anak lewat tombol Ambil foto / Galeri.
class ChildPhotoViewerSheet extends StatelessWidget {
  const ChildPhotoViewerSheet({
    super.key,
    required this.child,
    required this.photo,
    required this.onAdjust,
    this.onRemove,
  });

  final ChildProfile child;
  final ImageProvider? photo;
  final VoidCallback onAdjust;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final size = (MediaQuery.sizeOf(context).width - 88).clamp(200.0, 300.0);
    final hasPhoto = photo != null;
    final duration = AppMotion.of(context, AppMotion.normal);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: AppStrings.childPhotoViewerDone,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    header: true,
                    child: Text(
                      AppStrings.childPhotoViewerTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outline),
            Expanded(
              child: Center(
                child: Semantics(
                  label: AppStrings.childPhotoViewerSemantics(child.nickname),
                  image: true,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1),
                    duration: duration,
                    curve: AppMotion.easeOutCubic,
                    builder: (context, scale, childWidget) => Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: scale.clamp(0.0, 1.0),
                        child: childWidget,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outline),
                      ),
                      child: ChildAvatar(
                        sex: child.sex,
                        photo: photo,
                        size: size,
                        semanticLabel: child.nickname,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!hasPhoto) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Text(
                  AppStrings.childPhotoViewerEmptyHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outline)),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (hasPhoto) ...[
                    _Action(
                      icon: Icons.crop_rotate_rounded,
                      label: AppStrings.childPhotoViewerAdjust,
                      onTap: onAdjust,
                    ),
                    _Action(
                      icon: Icons.delete_outline_rounded,
                      label: AppStrings.childPhotoViewerRemove,
                      color: colors.statusAlert,
                      onTap: onRemove ?? () {},
                    ),
                  ],
                  _Action(
                    icon: Icons.check_rounded,
                    label: AppStrings.childPhotoViewerDone,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TonalIconCircle(
                icon: icon,
                iconSemantics: label,
                size: 48,
                iconSize: 22,
                backgroundColor: color == null
                    ? colors.primaryContainer
                    : color!.withValues(alpha: 0.12),
                iconColor: color ?? colors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: color ?? colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilkan viewer foto profil (pencil/avatar → edit foto).
Future<void> showChildPhotoViewer({
  required BuildContext context,
  required ChildProfile child,
  required ImageProvider? photo,
  required VoidCallback onAdjust,
  VoidCallback? onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChildPhotoViewerSheet(
      child: child,
      photo: photo,
      onAdjust: onAdjust,
      onRemove: onRemove,
    ),
  );
}
