import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/presentation/widgets/manual_food_sheet.dart';
import 'package:cekgizi/shared/illustrations/plate_viewfinder_illustration.dart';

/// Panel dominan "Kenali isi piring" di tab Makan (PRD §6.4, v2.1).
///
/// Kamera pindah dari FAB Beranda ke sini karena Makan adalah tab aksi.
/// Panel ini **satu-satunya** pintu kamera: tidak ada `CameraPreview` hidup
/// di dalam tab (hemat baterai, privasi jelas) - ketuk CTA untuk membuka
/// layar pemindai penuh yang juga menyediakan galeri dan catat manual.
///
/// Susunan v2.2: ikon + judul → kalimat singkat → ilustrasi viewfinder →
/// tiga langkah yang bisa dibaca → catatan privasi → aksi utama.
/// Semua elemen memakai token hero agar kontras di light & dark tetap aman.
class CapturePanel extends StatelessWidget {
  const CapturePanel({super.key, this.childId});

  /// Diperlukan untuk pintu "Catat tanpa foto" (tetap bisa offline).
  final String? childId;

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
                        AppStrings.capturePanelEyebrow,
                        style: AppTextStyles.label.copyWith(
                          color: colors.onHeroAccent,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.capturePanelTitle,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.onHeroSurface,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.capturePanelBody,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.onHeroSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: PlateViewfinderIllustration(size: 112, onHero: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Step(
                  number: '1',
                  label: AppStrings.capturePanelStepPhoto,
                  color: colors.onHeroSurface,
                  border: colors.onHeroSurfaceMuted,
                ),
                _Step(
                  number: '2',
                  label: AppStrings.capturePanelStepRecognize,
                  color: colors.onHeroSurface,
                  border: colors.onHeroSurfaceMuted,
                ),
                _Step(
                  number: '3',
                  label: AppStrings.capturePanelStepReview,
                  color: colors.onHeroSurface,
                  border: colors.onHeroSurfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: colors.onHeroAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    AppStrings.capturePanelPrivacy,
                    style: AppTextStyles.label.copyWith(
                      color: colors.onHeroSurfaceMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
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
            if (childId != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () => showManualFoodSheet(context, childId: childId!),
                style: TextButton.styleFrom(
                  foregroundColor: colors.onHeroSurface,
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(AppStrings.capturePanelManualCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.color,
    required this.border,
  });

  final String number;
  final String label;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.label.copyWith(
                  color: AppTheme.colorsOf(context).heroSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
