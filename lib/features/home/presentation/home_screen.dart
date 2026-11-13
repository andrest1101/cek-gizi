import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/greeting.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_hero_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_tips_card.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';
import 'package:cekgizi/features/meals/presentation/widgets/photo_scan_fab.dart';

/// Beranda (PRD §6.3, cakupan Batch 4): sapaan, anak aktif, status tumbuh.
/// Kartu Piring Hari Ini & tips menyusul di Batch 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);

    return Scaffold(
      floatingActionButton: const PhotoScanFab(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            key: const Key('home-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxxl + AppSpacing.lg,
            ),
            children: [
              const _HomeHeader(),
              const SizedBox(height: AppSpacing.lg),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ChildSwitcherCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const PiringHeroCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const PiringTipsCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const GrowthStatusCard(),
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

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final selectedChild = ref.watch(selectedChildProvider).value;
    final childName = selectedChild?.nickname;
    // Berlangganan data catatan hari ini: saat resume/tengah malam
    // (lihat `TodayWatcher`), header ini ikut dibangun ulang dengan tanggal
    // yang benar. Tidak memicu jaringan tambahan - provider yang sama.
    if (selectedChild != null) {
      ref.watch(foodLogsProvider(selectedChild.id));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                IdDateFormat.eyebrow(now),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  childName == null
                      ? AppConfig.appName
                      : AppStrings.homeGreeting(Greeting.of(now), childName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          tooltip: AppStrings.homeManageChild,
          onPressed: () => context.push('/children'),
          icon: const Icon(Icons.manage_accounts_rounded, size: 21),
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
        Skeleton(height: 56),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 320, radius: AppRadius.card + AppSpacing.xs),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 236),
      ],
    );
  }
}
