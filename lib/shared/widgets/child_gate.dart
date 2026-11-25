import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/illustrations/seedling_illustration.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Gerbang profil anak untuk layar yang membutuhkan anak aktif (Makan,
/// Tumbuh).
///
/// Membedakan tiga keadaan yang sering keliru disamakan:
/// - **memuat** → skeleton (bukan "belum ada anak"),
/// - **gagal** → [ErrorCard] + "Coba lagi" (bukan "belum ada anak"),
/// - **benar-benar kosong** → [EmptyState] dengan CTA tambah anak.
///
/// [builder] hanya dipanggil saat daftar anak sudah selesai dimuat dan
/// setidaknya ada satu profil.
class ChildGate extends ConsumerWidget {
  const ChildGate({super.key, required this.builder});

  /// Isi layar ketika profil anak tersedia.
  final Widget Function(BuildContext context, ChildProfile child) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);
    return childrenAsync.when(
      loading: () => const _ChildGateSkeleton(),
      error: (error, stackTrace) => Center(
        key: const Key('child-gate-error'),
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
            key: const Key('child-gate-empty'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: EmptyState(
                icon: Icons.child_care_rounded,
                illustration: const SeedlingIllustration(),
                title: AppStrings.growthNoChildTitle,
                body: AppStrings.growthNoChildBody,
                action: FilledButton(
                  onPressed: () => context.push('/children/add'),
                  child: const Text(AppStrings.growthNoChildCta),
                ),
              ),
            ),
          );
        }
        final selectedId = ref.watch(selectedChildIdProvider);
        final child = children.where((c) => c.id == selectedId).firstOrNull ??
            children.first;
        return builder(context, child);
      },
    );
  }
}

class _ChildGateSkeleton extends StatelessWidget {
  const _ChildGateSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('child-gate-loading'),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        Skeleton(width: 120, height: 12),
        SizedBox(height: AppSpacing.sm),
        Skeleton(width: 220, height: 24),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 180, radius: AppRadius.card),
        SizedBox(height: AppSpacing.lg),
        Skeleton(width: 160, height: 18),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72, radius: AppRadius.card),
      ],
    );
  }
}
