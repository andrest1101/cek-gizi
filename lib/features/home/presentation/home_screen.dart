import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/greeting.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_hero_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_tips_card.dart';
import 'package:cekgizi/features/meals/presentation/widgets/week_strip.dart';
import 'package:cekgizi/shared/illustrations/seedling_illustration.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Beranda (PRD §6.3, v2.1): sapaan + anak aktif + ringkasan hari ini.
///
/// Header sengaja hanya berisi sapaan: aksi "Kelola anak" pindah ke sheet
/// ganti anak & tab Akun, "Pengaturan" pindah ke tab Akun, dan kamera pindah
/// ke tab Makan. Satu layar = satu aksi utama (di sini: ringkasan).
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
                        illustration: const SeedlingIllustration(),
                        title: AppStrings.childEmptyTitle,
                        body: AppStrings.childEmptyBody,
                        action: FilledButton(
                          onPressed: () => context.push('/children/add'),
                          child: const Text(AppStrings.childEmptyCta),
                        ),
                      ),
                    );
                  }
                  final selectedChild = ref.watch(selectedChildProvider).value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ChildSwitcherCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const PiringHeroCard(),
                      if (selectedChild != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        HomeWeekStrip(childId: selectedChild.id),
                      ],
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
    final now = DateTime.now();
    final selectedChild = ref.watch(selectedChildProvider).value;
    final childName = selectedChild?.nickname;
    // Berlangganan data catatan hari ini: saat resume/tengah malam
    // (lihat `TodayWatcher`), header ini ikut dibangun ulang dengan tanggal
    // yang benar. Tidak memicu jaringan tambahan - provider yang sama.
    if (selectedChild != null) {
      ref.watch(foodLogsProvider(selectedChild.id));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          IdDateFormat.eyebrow(now),
          style: AppTextStyles.label.copyWith(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
          ),
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
