import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/core/time/local_dates.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/home/presentation/widgets/app_nav_bar.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

/// Shell navigasi utama (PRD §6.2, v2.1): 5 destinasi
/// (Beranda, Makan, Resep, Tumbuh, Akun).
///
/// Tanya Gizi tidak lagi berupa tab - dibuka lewat [TanyaBubble] yang
/// mengambang di atas bilah navigasi.
///
/// [TodayWatcher] memastikan data "hari ini" tetap benar saat aplikasi
/// dibuka kembali dari latar atau melewati tengah malam: catatan makan
/// anak terpilih dimuat ulang sehingga label "Hari ini"/"Kemarin", ring,
/// dan diary tidak menampilkan tanggal yang salah.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFoodLogs();
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = ref.read(clockProvider)();
    final nextMidnight = startOfNextLocalDay(now);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        _refreshFoodLogs();
        _scheduleMidnightRefresh();
      },
    );
  }

  void _refreshFoodLogs() {
    final childId = ref.read(selectedChildProvider).value?.id;
    if (childId == null) return;
    ref.invalidate(foodLogsProvider(childId));
    ref.invalidate(historyLogsProvider(childId));
    ref.invalidate(historySummaryProvider(childId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}
