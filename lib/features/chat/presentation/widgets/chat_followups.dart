import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Pertanyaan lanjutan dari jawaban terakhir.
///
/// Ditampilkan sebagai baris yang bisa diketuk (bukan chip) supaya kalimat
/// panjang tetap terbaca dan target sentuh tetap 48dp.
class ChatFollowups extends StatelessWidget {
  const ChatFollowups({
    super.key,
    required this.followups,
    required this.onSend,
  });

  final List<String> followups;
  final void Function(String question) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    // Fill `surfaceVariant` (bukan `surface`) supaya kartu ini tidak terbaca
    // sebagai jawaban asisten kedua.
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Material(
        color: colors.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control + 4),
          side: BorderSide(color: colors.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                AppStrings.tanyaFollowupsTitle,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            for (var index = 0; index < followups.length; index++) ...[
              if (index > 0) Divider(height: 1, color: colors.outline),
              InkWell(
                onTap: () => onSend(followups[index]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          followups[index],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
