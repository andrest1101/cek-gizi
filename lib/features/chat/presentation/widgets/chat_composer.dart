import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Kotak tulis Tanya Gizi.
///
/// Baris konteks (anak + sisa kuota) memberi tahu siapa yang sedang dibantu
/// tanpa memakan ruang percakapan. Kuota hanya informasi tampilan; penentu
/// sesungguhnya tetap server, jadi input tidak dikunci saat kuota 0.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
    this.childLabel,
    this.quotaText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;
  final String? childLabel;
  final String? quotaText;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final hasContext = childLabel != null || quotaText != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.outline, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContext) ...[
              Row(
                children: [
                  if (childLabel != null)
                    Expanded(
                      flex: 3,
                      child: Text(
                        childLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  if (quotaText != null)
                    Flexible(
                      flex: 2,
                      child: Semantics(
                        label: '${AppStrings.tanyaQuotaSemantics}: $quotaText',
                        excludeSemantics: true,
                        child: Text(
                          quotaText!,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card + 4),
                      border: Border.all(color: colors.outline, width: 1),
                    ),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.xs,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: Semantics(
                      label: AppStrings.tanyaInputSemantics,
                      textField: true,
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => canSend ? onSend() : null,
                        style: AppTextStyles.body.copyWith(
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.tanyaInputHint,
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                          filled: false,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor: colors.surfaceVariant,
                    disabledForegroundColor: colors.textSecondary,
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                  ),
                  onPressed: canSend ? onSend : null,
                  tooltip: AppStrings.tanyaSendSemantics,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
