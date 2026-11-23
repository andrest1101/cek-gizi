import 'package:flutter/material.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_ai_mark.dart';

/// Header ringkas Tanya Gizi: identitas asisten, aksi menu, dan tombol tutup.
///
/// Riwayat chat tidak lagi dihapus lewat ikon terpisah di header (terlalu
/// ramai); aksinya pindah ke menu ⋮ agar header tetap satu baris.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.onClose,
    required this.onClearHistory,
    required this.canClear,
  });

  final VoidCallback onClose;
  final VoidCallback onClearHistory;
  final bool canClear;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.outline, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: AppStrings.tanyaClose,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              label: 'Asisten ${AppConfig.appName}',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(child: const TanyaAiMark(size: 24)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      AppStrings.tanyaTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.tanyaHeaderSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: AppStrings.tanyaMenuSemantics,
              icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
              onSelected: (value) {
                if (value == 'clear') onClearHistory();
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'clear',
                  enabled: canClear,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          AppStrings.tanyaDeleteHistory,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
