import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';

/// Baris identitas anak di Beranda: avatar, usia, dan chevron ke sheet
/// ganti anak. Nama anak TIDAK diulang di sini karena sudah tampil di
/// judul sapaan Beranda - menghindari nama yang sama dua kali.
class ChildSwitcherCard extends ConsumerWidget {
  const ChildSwitcherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenListProvider).value ?? const [];
    if (children.isEmpty) return const SizedBox.shrink();

    final selectedId = ref.watch(selectedChildIdProvider);
    final child = children.where((c) => c.id == selectedId).firstOrNull ??
        children.first;
    final now = DateTime.now();
    final age = child.ageLabel(now);

    return Semantics(
      container: true,
      button: true,
      label: '${child.nickname}, $age. Ketuk untuk ganti anak',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () => showChildSwitcherSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ChildAvatar(
                  avatarKey: child.avatarKey,
                  size: 48,
                  semanticLabel: child.nickname,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        age,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.colorsOf(context).textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.childSwitcherTooltip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.colorsOf(context).textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(left: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppSurfaces.sunken(context, radius: AppRadius.pill)
                        .color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.unfold_more_rounded,
                    size: 22,
                    color: AppTheme.colorsOf(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol avatar kecil untuk header Makan/Tumbuh: ketuk → sheet ganti anak.
/// Target ketuk 48dp; avatar tetap 38dp agar tidak mendominasi judul.
class ChildSwitcherButton extends ConsumerWidget {
  const ChildSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenListProvider).value ?? const [];
    if (children.isEmpty) return const SizedBox.shrink();
    final colors = AppTheme.colorsOf(context);
    final selectedId = ref.watch(selectedChildIdProvider);
    final child = children.where((c) => c.id == selectedId).firstOrNull ??
        children.first;

    return Semantics(
      container: true,
      button: true,
      label: '${AppStrings.childSwitcherTooltip}: ${child.nickname}',
      excludeSemantics: true,
      child: Tooltip(
        message: AppStrings.childSwitcherTooltip,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showChildSwitcherSheet(context),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ChildAvatar(
                      avatarKey: child.avatarKey,
                      size: 38,
                      semanticLabel: child.nickname,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.outline),
                        ),
                        child: Icon(
                          Icons.unfold_more_rounded,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet pemilih anak (PRD §6.3) + tautan ke layar kelola anak.
Future<void> showChildSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ChildSwitcherSheet(),
  );
}

class ChildSwitcherSheet extends ConsumerWidget {
  const ChildSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final children = ref.watch(childrenListProvider).value ?? const [];
    final selectedId = ref.watch(selectedChildProvider).value?.id;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              AppStrings.childListTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.homeSwitchChildHint,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final child in children)
            _ChildSheetRow(
              child: child,
              isSelected: child.id == selectedId,
            ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.outline),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/children');
            },
            icon: const Icon(Icons.manage_accounts_rounded),
            label: const Text(AppStrings.homeManageChild),
          ),
        ],
      ),
    );
  }
}

class _ChildSheetRow extends ConsumerWidget {
  const _ChildSheetRow({required this.child, required this.isSelected});

  final ChildProfile child;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final age = child.ageLabel(DateTime.now());

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${child.nickname}, $age',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () {
            ref.read(selectedChildIdProvider.notifier).select(child.id);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
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
                        age,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
