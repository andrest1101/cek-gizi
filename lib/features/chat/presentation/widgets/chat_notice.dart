import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Disclaimer tetap: edukasi umum, bukan pengganti tenaga kesehatan.
///
/// Selalu terlihat dan tidak bisa ditutup (PRD §6.7), tetapi ditempatkan
/// tepat di atas kotak tulis agar tidak memakan ruang percakapan. Teks utuh,
/// tanpa ellipsis.
class ChatDisclaimer extends StatelessWidget {
  const ChatDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppStrings.tanyaDisclaimerBanner,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Galat kirim yang ringkas, tepat di atas kotak tulis.
class ChatInlineError extends StatelessWidget {
  const ChatInlineError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      container: true,
      label: '${AppStrings.errorTitle}. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.control + 4),
          border: Border.all(
            color: colors.statusAlert.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: colors.statusAlert,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text(AppStrings.retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Peringatan bahwa jawaban tampil tetapi riwayat belum tersimpan.
class ChatSyncNotice extends StatelessWidget {
  const ChatSyncNotice({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: colors.statusWatchText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.tanyaSyncFailed,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.tanyaSyncRetry),
          ),
        ],
      ),
    );
  }
}
