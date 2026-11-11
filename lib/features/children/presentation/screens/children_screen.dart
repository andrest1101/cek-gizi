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
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Daftar & kelola profil anak (PRD §6.8: tambah, ubah, hapus).
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);
    final hasChildren = childrenAsync.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.childListTitle)),
      floatingActionButton: hasChildren
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/children/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.childEmptyCta),
            )
          : null,
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const _ChildrenSkeleton(),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: ErrorCard(
                message: AppStrings.childListLoadError,
                onRetry: () => ref.invalidate(childrenListProvider),
              ),
            ),
          ),
          data: (children) {
            if (children.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: EmptyState(
                    icon: Icons.child_care_rounded,
                    title: AppStrings.childEmptyTitle,
                    body: AppStrings.childEmptyBody,
                    action: FilledButton(
                      onPressed: () => context.push('/children/add'),
                      child: const Text(AppStrings.childEmptyCta),
                    ),
                  ),
                ),
              );
            }
            final selectedId = ref.watch(selectedChildIdProvider);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.xxxl + AppSpacing.xl,
              ),
              children: [
                Text(
                  AppStrings.childManageHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorsOf(context).textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var index = 0; index < children.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ChildCard(
                      child: children[index],
                      isSelected: selectedId == null
                          ? index == 0
                          : children[index].id == selectedId,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChildrenSkeleton extends StatelessWidget {
  const _ChildrenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(width: 220, height: 14),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 84),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 84),
          SizedBox(height: AppSpacing.md),
          Skeleton(height: 84),
        ],
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child, required this.isSelected});

  final ChildProfile child;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final age = child.ageLabel(DateTime.now());

    return DecoratedBox(
      decoration: isSelected
          ? BoxDecoration(
              color: AppSurfaces.cardColor(context),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.primary, width: 1.5),
            )
          : AppSurfaces.card(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () {
            ref.read(selectedChildIdProvider.notifier).select(child.id);
            context.pop();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                AppStrings.childSelectedBadge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: AppStrings.childOptionsTooltip,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        context.push('/children/${child.id}/edit');
                      case 'delete':
                        _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(AppStrings.actionEdit),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(AppStrings.actionDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.childDeleteTitle),
        content: Text('${AppStrings.childDeleteBody}\n(${child.nickname})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.childDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(childrenListProvider.notifier).deleteChild(child.id);
    }
  }
}
