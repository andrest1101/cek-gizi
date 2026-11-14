import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/time/local_dates.dart';

/// Dua bagian layar Makan: catatan hari ini atau riwayat 30 hari.
///
/// Navigasi tetap tiga destinasi (Beranda, Makan, Tumbuh); riwayat hidup di
/// dalam Makan agar pengguna tidak perlu mempelajari tab baru.
enum MakanSection { today, history }

/// Bagian Makan yang sedang aktif. Beranda dapat memindahkannya ke
/// [MakanSection.history] sebelum membuka tab Makan.
final makanSectionProvider =
    NotifierProvider<MakanSectionNotifier, MakanSection>(
  MakanSectionNotifier.new,
);

class MakanSectionNotifier extends Notifier<MakanSection> {
  @override
  MakanSection build() => MakanSection.today;

  void show(MakanSection section) => state = section;
}

/// Tanggal yang dipilih pada Riwayat (awal hari lokal). Null berarti hari ini.
final historySelectedDayProvider =
    NotifierProvider<HistorySelectedDayNotifier, DateTime?>(
  HistorySelectedDayNotifier.new,
);

class HistorySelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}

/// Pilih satu hari dan buka Riwayat. Dipakai strip 7 hari di Beranda,
/// strip Riwayat, dan kalender bulan.
void focusHistoryDay(WidgetRef ref, DateTime day) {
  ref.read(historySelectedDayProvider.notifier).select(startOfLocalDay(day));
  ref.read(makanSectionProvider.notifier).show(MakanSection.history);
}

/// Kembali ke catatan hari ini (tombol "Catat makan hari ini" di riwayat).
void focusToday(WidgetRef ref) {
  ref.read(historySelectedDayProvider.notifier).select(null);
  ref.read(makanSectionProvider.notifier).show(MakanSection.today);
}
