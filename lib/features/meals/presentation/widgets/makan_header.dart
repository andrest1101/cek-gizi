import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/meals/presentation/providers/makan_section.dart';
import 'package:cekgizi/shared/widgets/child_switcher.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Kepala Makan: tanggal, judul, ganti anak, dan dua bagian
/// (Hari ini / Riwayat).
///
/// Sengaja ikut menggulir di dalam daftar (bukan disematkan di atas layar)
/// supaya tidak menutupi konten saat pengguna menggulir. Sama seperti
/// Beranda, bagian atas layar bebas "bergerak" bersama konten.
class MakanHeader extends ConsumerWidget {
  const MakanHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(makanSectionProvider);
    final now = ref.watch(clockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          eyebrow: IdDateFormat.eyebrow(now),
          title: AppStrings.makanTitle,
          subtitle: AppStrings.makanSubtitle,
          trailing: const ChildSwitcherButton(),
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentControl<MakanSection>(
          options: const [
            SegmentOption(
              value: MakanSection.today,
              label: AppStrings.makanSectionToday,
              semanticLabel: AppStrings.makanSectionTodaySemantics,
            ),
            SegmentOption(
              value: MakanSection.history,
              label: AppStrings.makanSectionHistory,
              semanticLabel: AppStrings.makanSectionHistorySemantics,
            ),
          ],
          selected: section,
          onChanged: (value) =>
              ref.read(makanSectionProvider.notifier).show(value),
        ),
      ],
    );
  }
}
