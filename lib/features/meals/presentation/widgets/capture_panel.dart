import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Panel dominan "Kenali isi piring" di tab Makan (PRD §6.4, v2.1).
///
/// Kamera pindah dari FAB Beranda ke sini karena Makan adalah tab aksi.
/// Panel ini **satu-satunya** pintu kamera: tidak ada `CameraPreview` hidup
/// di dalam tab (hemat baterai, privasi jelas) - ketuk CTA untuk membuka
/// layar pemindai penuh yang juga menyediakan galeri dan catat manual.
class CapturePanel extends StatelessWidget {
  const CapturePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Semantics(
      container: true,
      label: AppStrings.capturePanelSemantics,
      child: Container(
        decoration: AppSurfaces.hero(
          context,
          radius: AppRadius.card + AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.onHeroSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 22,
                    color: colors.heroSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.capturePanelTitle,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colors.onHeroSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.capturePanelBody,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onHeroSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/scan'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.onHeroSurface,
                foregroundColor: colors.heroSurface,
              ),
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text(AppStrings.capturePanelCta),
            ),
          ],
        ),
      ),
    );
  }
}
