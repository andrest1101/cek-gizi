import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/greeting.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Beranda (PRD §6.3, cakupan Batch 4): sapaan, anak aktif, status tumbuh.
/// Kartu Piring Hari Ini & tips menyusul di Batch 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxxl + AppSpacing.lg,
            ),
            children: [
              const _HomeHeader(),
              const SizedBox(height: AppSpacing.xxl),
              childrenAsync.when(
                loading: () => const _HomeSkeleton(),
                error: (error, stackTrace) => ErrorCard(
                  message: AppStrings.homeLoadError,
                  onRetry: () => ref.invalidate(childrenListProvider),
                ),
                data: (children) {
                  if (children.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
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
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChildSwitcherCard(),
                      SizedBox(height: AppSpacing.lg),
                      GrowthStatusCard(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(childrenListProvider);
    await ref
        .read(childrenListProvider.future)
        .catchError((Object _) => <ChildProfile>[]);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Greeting.of(DateTime.now()),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  AppConfig.appName,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppStrings.homeManageChild,
          onPressed: () => context.push('/children'),
          icon: Icon(Icons.tune_rounded, color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 84),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 236),
      ],
    );
  }
}
