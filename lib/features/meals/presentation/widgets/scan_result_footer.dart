import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Footer tetap sheet hasil scan: ringkasan, pratinjau Piring Hari Ini,
/// catatan privasi, dan tombol simpan.
///
/// Saat keyboard terbuka ([compact] true), hanya ringkasan + tombol yang
/// ditampilkan agar sheet tetap muat di layar pendek.
class ScanResultFooter extends StatelessWidget {
  const ScanResultFooter({
    super.key,
    required this.itemCount,
    required this.groupCount,
    required this.canSave,
    required this.saving,
    required this.onSave,
    this.diversityText,
    this.error,
    this.compact = false,
  });

  final int itemCount;
  final int groupCount;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;
  final String? diversityText;
  final String? error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final duration = AppMotion.of(context, AppMotion.fast);
    final summary = AppStrings.scanFooterSummary(itemCount, groupCount);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        compact ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: duration,
          curve: AppMotion.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: duration,
                child: Column(
                  key: ValueKey('$summary|$diversityText|$compact'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!compact && diversityText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        diversityText!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        AppStrings.scanPrivacyNote,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.statusAlert,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('scan-save'),
                  onPressed: canSave ? onSave : null,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  icon: saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text(AppStrings.scanSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
