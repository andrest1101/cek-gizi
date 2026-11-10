import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Kartu galat yang ramah (PRD §6.9): nada tenang, satu tombol "Coba lagi".
/// Jangan tampilkan detail teknis/eksepsi mentah ke orang tua.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = AppStrings.errorTitle,
    this.retryLabel = AppStrings.retry,
  });

  /// Kalimat penjelas ramah (dari AppStrings, sesuai konteks galat).
  final String message;

  /// Dipanggil saat tombol coba lagi ditekan.
  final VoidCallback onRetry;

  final String title;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.outline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TonalIconCircle(
              icon: Icons.error_outline_rounded,
              iconSemantics: title,
              backgroundColor: colors.statusAlert.withValues(alpha: 0.12),
              iconColor: colors.statusAlert,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style:
                  textTheme.titleMedium?.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
