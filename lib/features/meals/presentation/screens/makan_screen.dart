import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/meals/presentation/providers/makan_section.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/features/meals/presentation/widgets/makan_history_view.dart';
import 'package:cekgizi/features/meals/presentation/widgets/makan_today_view.dart';
import 'package:cekgizi/shared/widgets/child_gate.dart';

/// Layar Makan (PRD §6.4) dengan dua bagian: **Hari ini** (target harian,
/// checklist kelompok pangan, catatan hari ini) dan **Riwayat** (30 hari
/// terakhir). Navigasi utama tetap tiga destinasi.
class MakanScreen extends ConsumerWidget {
  const MakanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: const TanyaBubble(),
      body: SafeArea(
        // Memuat/gagal/kosong dibedakan oleh ChildGate: jangan menampilkan
        // "belum ada anak" saat daftar anak masih dimuat atau error.
        child: ChildGate(
          builder: (context, child) => _MakanBody(child: child),
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
