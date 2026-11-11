import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';

/// Baris identitas anak (avatar + nama + usia) untuk header layar
/// Tumbuh/Makan. Bila [semanticsLabel] diisi, baris dibungkus Semantics.
class ChildIdentityRow extends StatelessWidget {
  const ChildIdentityRow({super.key, required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        ChildAvatar(
          avatarKey: child.avatarKey,
          size: 40,
          semanticLabel: child.nickname,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                child.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                child.ageLabel(DateTime.now()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
