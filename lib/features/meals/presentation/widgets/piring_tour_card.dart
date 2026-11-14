import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Tur singkat sekali jalan di layar Makan. Penjelasan lengkap tetap bisa
/// dibuka kapan pun lewat tombol "Cara kerja".
class PiringTourCard extends ConsumerStatefulWidget {
  const PiringTourCard({super.key});

  @override
  ConsumerState<PiringTourCard> createState() => _PiringTourCardState();
}

class _PiringTourCardState extends ConsumerState<PiringTourCard> {
  bool _dismissed = false;

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      await ref.read(localPrefsProvider).setPiringTourSeen();
    } catch (_) {
      // Flag lokal gagal ditulis bukan alasan mengganggu pengguna.
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localPrefsProvider);
    if (_dismissed || prefs.isPiringTourSeen) return const SizedBox.shrink();

    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Semantics(
        container: true,
        label: AppStrings.piringTourSemantics,
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 19,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.piringTourTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.piringTourBody,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(AppStrings.piringTourDismiss),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
