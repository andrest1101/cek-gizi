import 'package:flutter/material.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';

/// Satu gelembung pesan di riwayat Tanya Gizi (PRD §6.7).
///
/// User di kanan (`primary`), asisten di kiri dengan avatar tonal.
/// Batasan keamanan jawaban tampil sebagai [SafetyCard], bukan bubble.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isUser = message.role == ChatRole.user;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.card),
            topRight: const Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(isUser ? AppRadius.card : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.card),
          ),
          border: isUser ? null : Border.all(color: colors.outline, width: 1),
        ),
        child: SelectableText(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: isUser ? colors.onPrimary : colors.textPrimary,
          ),
        ),
      ),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
          label: 'Asisten ${AppConfig.appName}',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_rounded, size: 18, color: colors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: bubble),
      ],
    );
  }
}
