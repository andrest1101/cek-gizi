import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/chat_dates.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_markdown.dart';

/// Satu pesan pada percakapan Tanya Gizi.
///
/// Jawaban asisten berupa **lembar `surface` ber-border hairline**, tanpa
/// avatar dan tanpa nama berulang: identitas cukup di header, sedangkan peran
/// dibedakan lewat bentuk (lembar penuh di kiri vs pil `primary` di kanan).
/// Peran tetap diumumkan ke pembaca layar lewat [Semantics].
class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.message,
    this.showTime = true,
  });

  final ChatMessage message;

  /// Tampilkan jam di bawah pesan (pesan terakhir dalam grup).
  final bool showTime;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    return _isUser ? _buildUser(context) : _buildAssistant(context);
  }

  Widget _buildUser(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final maxWidth = math.min(520.0, MediaQuery.sizeOf(context).width * 0.84);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: AppStrings.tanyaUserMessageSemantics,
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.card),
                      topRight: Radius.circular(AppRadius.card),
                      bottomLeft: Radius.circular(AppRadius.card),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(color: colors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
          if (showTime) _TimeLabel(at: message.createdAt, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildAssistant(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label: AppStrings.tanyaAnswerSemantics(),
          child: GestureDetector(
            onLongPress: () => _showActions(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.outline, width: 1),
              ),
              child: ChatMarkdown(
                text: message.content,
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        if (showTime) _TimeLabel(at: message.createdAt, alignEnd: false),
      ],
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = AppTheme.colorsOf(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Icon(Icons.copy_rounded, color: colors.textSecondary),
              title: const Text(AppStrings.tanyaCopy),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ),
        );
      },
    );
    if (action != true || !context.mounted) return;

    await Clipboard.setData(ClipboardData(text: message.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.tanyaCopyDone)));
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.at, required this.alignEnd});

  final DateTime at;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final time = formatChatTime(at);
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        right: alignEnd ? AppSpacing.xs : 0,
      ),
      child: Semantics(
        label: AppStrings.tanyaTimeSemantics(time),
        excludeSemantics: true,
        child: Text(
          time,
          style: AppTextStyles.label.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
