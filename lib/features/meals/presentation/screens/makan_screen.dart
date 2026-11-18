import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/presentation/providers/makan_section.dart';
import 'package:cekgizi/features/meals/presentation/widgets/makan_history_view.dart';
import 'package:cekgizi/features/meals/presentation/widgets/makan_today_view.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';

/// Layar Makan (PRD §6.4) dengan dua bagian: **Hari ini** (target harian,
/// checklist kelompok pangan, catatan hari ini) dan **Riwayat** (30 hari
/// terakhir). Navigasi utama tetap tiga destinasi.
class MakanScreen extends ConsumerWidget {
  const MakanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;

    return Scaffold(
      body: SafeArea(
        child: child == null ? const _NoChild() : _MakanBody(child: child),
      ),
    );
  }
}

class _NoChild extends StatelessWidget {
  const _NoChild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: EmptyState(
          icon: Icons.restaurant_rounded,
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
}

class _MakanBody extends ConsumerWidget {
  const _MakanBody({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(makanSectionProvider);

    // Header (tanggal, judul, ganti anak, dua bagian) ikut menggulir di
    // dalam daftar - lihat MakanTodayView / MakanHistoryView.
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.normal),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: section == MakanSection.today
          ? MakanTodayView(
              key: const ValueKey('makan-today'),
              child: child,
            )
          : MakanHistoryView(
              key: const ValueKey('makan-history'),
              child: child,
            ),
    );
  }
}
