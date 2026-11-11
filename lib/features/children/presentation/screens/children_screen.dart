import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';

/// Daftar & kelola profil anak (PRD §6.8: tambah, ubah, hapus).
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final childrenAsync = ref.watch(childrenListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.childListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/children/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.childEmptyCta),
      ),
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: ErrorCard(
                message:
                    'Gagal memuat data anak. Periksa koneksi, lalu coba lagi.',
                onRetry: () => ref.invalidate(childrenListProvider),
              ),
            ),
          ),
          data: (children) {
            if (children.isEmpty) {
              return Center(
                child: EmptyState(
                  icon: Icons.child_care_rounded,
                  title: AppStrings.childEmptyTitle,
                  body: AppStrings.childEmptyBody,
                  action: FilledButton(
                    onPressed: () => context.push('/children/add'),
                    child: const Text(AppStrings.childEmptyCta),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xxxl + AppSpacing.xl,
              ),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final child = children[index];
                final selectedId = ref.watch(selectedChildIdProvider);
                final isSelected =
                    selectedId == null ? index == 0 : child.id == selectedId;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.outline,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minVerticalPadding: AppSpacing.md,
                    leading: ChildAvatar(
                      avatarKey: child.avatarKey,
                      size: 48,
                      semanticLabel: child.nickname,
                    ),
                    title: Text(
                      child.nickname,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      child.ageLabel(DateTime.now()),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Ubah data',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.push('/children/${child.id}/edit'),
                        ),
                        IconButton(
                          tooltip: AppStrings.childDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _confirmDelete(context, ref, child.id, child.nickname),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedChildIdProvider.notifier).select(child.id);
                      context.pop();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.childDeleteTitle),
        content: Text('${AppStrings.childDeleteBody}\n($name)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.childDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.childDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(childrenListProvider.notifier).deleteChild(id);
    }
  }
}
