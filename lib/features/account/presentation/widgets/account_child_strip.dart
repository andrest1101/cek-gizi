import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/children/presentation/widgets/child_photo_avatar.dart';

/// Chip anak horizontal di tab Akun. Hanya ditampilkan bila ada ≥ 2 anak,
/// sehingga tiap anak punya foto/avatar sendiri dan bisa dipilih langsung.
class AccountChildStrip extends ConsumerWidget {
  const AccountChildStrip({
    super.key,
    required this.children,
    required this.now,
  });

  final List<ChildProfile> children;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedChildIdProvider);
    final effectiveSelected = selectedId ?? children.first.id;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: children.length + (children.length < 5 ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/children/add'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(AppStrings.accountChildAdd),
              ),
            );
          }
          final child = children[index];
          return _ChildChip(
            child: child,
            selected: child.id == effectiveSelected,
            age: child.ageLabel(now),
            onTap: () =>
                ref.read(selectedChildIdProvider.notifier).select(child.id),
          );
        },
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({
    required this.child,
    required this.selected,
    required this.age,
    required this.onTap,
  });

  final ChildProfile child;
  final bool selected;
  final String age;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${child.nickname}, $age',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs + 2,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer
                  : AppSurfaces.cardColor(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChildPhotoAvatar(child: child, size: 36),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    child.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
