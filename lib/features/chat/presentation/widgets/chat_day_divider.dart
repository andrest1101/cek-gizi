import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/chat_dates.dart';

/// Pembatas hari pada percakapan: "Hari ini", "Kemarin", atau tanggal.
class ChatDayDivider extends StatelessWidget {
  const ChatDayDivider({super.key, required this.at, required this.now});

  final DateTime at;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final label = switch (chatDayKind(at, now: now)) {
      ChatDayKind.today => AppStrings.tanyaToday,
      ChatDayKind.yesterday => AppStrings.tanyaYesterday,
      ChatDayKind.date => formatChatDate(at),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}
