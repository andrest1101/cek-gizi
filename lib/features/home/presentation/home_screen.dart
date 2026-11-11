import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/add_measurement_sheet.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';

/// Beranda (PRD §6.3, cakupan Batch 4): switch anak, kartu status tumbuh.
/// Piring Hari Ini & tips menyusul di Batch 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeGreeting),
        actions: const [SizedBox(width: 4)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMeasurementSheet(context),
        icon: const Icon(Icons.straighten_rounded),
        label: const Text(AppStrings.statusAddFirst),
      ),
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _HomeError(
            onRetry: () => ref.invalidate(childrenListProvider),
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
            final child = ref.watch(selectedChildProvider).value ?? children.first;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.xxxl + AppSpacing.xl,
              ),
              children: [
                _ChildSwitcherCard(childId: child.id),
                const SizedBox(height: AppSpacing.lg),
                const GrowthStatusCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kartu switcher anak di Beranda: avatar, nama, usia, dropdown ganti anak.
class _ChildSwitcherCard extends ConsumerWidget {
  const _ChildSwitcherCard({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final childrenAsync = ref.watch(childrenListProvider);
    final children = childrenAsync.value ?? const [];
    final child = children.where((c) => c.id == childId).firstOrNull;

    if (child == null) return const SizedBox.shrink();

    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _openSwitcher(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              ChildAvatar(
                avatarKey: child.avatarKey,
                size: 56,
                semanticLabel: child.nickname,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.nickname,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child.ageLabel(DateTime.now()),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSwitcher(BuildContext context, WidgetRef ref) {
    final children = ref.read(childrenListProvider).value ?? const [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SwitcherSheet(children: children),
    );
  }
}

class _SwitcherSheet extends ConsumerWidget {
  const _SwitcherSheet({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final selectedId = ref.watch(selectedChildIdProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.childListTitle,
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final child in children)
            ListTile(
              leading: ChildAvatar(
                avatarKey: child.avatarKey,
                size: 40,
                semanticLabel: child.nickname,
              ),
              title: Text(child.nickname),
              subtitle: Text(child.ageLabel(DateTime.now())),
              trailing: (selectedId == null && child == children.first) ||
                      child.id == selectedId
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () {
                ref.read(selectedChildIdProvider.notifier).select(child.id);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/children');
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Kelola anak'),
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak bisa memuat data. Periksa koneksi internet kamu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
