import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/illustrations/chat_illustration.dart';

/// Keadaan awal Tanya Gizi: sapaan singkat + empat kartu pertanyaan siap kirim.
///
/// Kartu vertikal (bukan chip) dipilih agar label panjang tetap rapi pada
/// 360dp dan pembesaran teks 1,3.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, required this.onAsk});

  final void Function(String question) onAsk;

  static const List<_Suggestion> _suggestions = [
    _Suggestion(Icons.restaurant_rounded, AppStrings.tanyaChipMpasi),
    _Suggestion(Icons.eco_rounded, AppStrings.tanyaChipPickyEater),
    _Suggestion(Icons.bakery_dining_rounded, AppStrings.tanyaChipSnack),
    _Suggestion(Icons.local_drink_rounded, AppStrings.tanyaChipMilk),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ListView(
      key: const Key('tanya-empty-list'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xxl,
      ),
      children: [
        const Center(child: ChatIllustration(size: 96)),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.tanyaEmptyTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.tanyaEmptyBody,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          AppStrings.tanyaQuickChipsTitle,
          style: AppTextStyles.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < _suggestions.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _SuggestionCard(
            suggestion: _suggestions[index],
            onTap: () => onAsk(_suggestions[index].label),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                AppStrings.tanyaPrivacyNote,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control + 4),
        side: BorderSide(color: colors.outline, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(suggestion.icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  suggestion.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
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
    );
  }
}
