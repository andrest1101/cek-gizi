import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/core/time/local_dates.dart';
import 'package:cekgizi/domain_ref/nutrition_rules.dart';
import 'package:cekgizi/domain_ref/nutrition_rules_asset.dart';
import 'package:cekgizi/features/meals/data/repositories/food_log_repository_impl.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/repositories/food_log_repository.dart';
import 'package:cekgizi/features/meals/domain/services/history_summary.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>(
  (ref) => FoodLogRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Aturan keragaman pangan dari asset (offline-safe).
final nutritionRulesProvider =
    FutureProvider<NutritionRules>((ref) => loadNutritionRules());

/// Catatan makan HARI INI untuk anak terpilih (waktu perangkat).
///
/// Query dibatasi 00.00 sampai 24.00 hari ini, sehingga aplikasi tidak
/// menarik seluruh riwayat setiap kali dibuka dan target otomatis kembali
/// ke 0 saat hari berganti (PRD §3.7).
final foodLogsProvider = AsyncNotifierProvider
    .family<FoodLogsNotifier, List<FoodLog>, String>(
  FoodLogsNotifier.new,
);

class FoodLogsNotifier extends AsyncNotifier<List<FoodLog>> {
  FoodLogsNotifier(this.childId);

  final String childId;

  @override
  Future<List<FoodLog>> build() {
    final now = ref.watch(clockProvider)();
    final range = localDayRange(now);
    return ref.watch(foodLogRepositoryProvider).listLogs(
          childId,
          from: range.from,
          to: range.to,
        );
  }

  /// Riwayat 30 hari terakhir, untuk strip dan ringkasan. Dibaca terpisah
  /// agar layar Hari ini tetap ringan.
  ///
  /// Invalidasi didefer ke setelah frame: membatalkan langsung di tengah
  /// gesture membuat Riverpod mem-flush dependency di dalam build itu
  /// (memicu assertion UncontrolledProviderScope saat pindah tab).
  void _refreshHistory() {
    final childId = this.childId;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(historyLogsProvider(childId));
      ref.invalidate(historySummaryProvider(childId));
    });
  }

  List<FoodLog> get _ordered =>
      [...?state.value]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));

  /// Catat satu makanan manual bernama (tanpa foto) memakai field yang
  /// sudah ada: satu item + `groups` union canonical, `source = manual`.
  /// Dipakai sheet "Catat manual" di dalam pemindai.
  Future<FoodLog> addManualItemLog({
    required String name,
    required MealType mealType,
    required List<String> groups,
    String? portion,
    DateTime? at,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('Nama makanan wajib diisi.');
    }
    if (groups.isEmpty) {
      throw StateError('Pilih minimal satu kelompok.');
    }
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final canonical = PiringDayEvaluator.canonicalOrder(groups);
    if (canonical.isEmpty) {
      throw StateError('Kelompok pangan tidak dikenal.');
    }
    final repo = ref.read(foodLogRepositoryProvider);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: at ?? ref.read(clockProvider)(),
        mealType: mealType,
        source: FoodLogSource.manual,
        items: [
          FoodLogItem(
            name: trimmed,
            groups: canonical,
            portion: portion,
          ),
        ],
        groups: canonical,
      ),
    );
    state = AsyncData([..._ordered, log]);
    _refreshHistory();
    return log;
  }

  /// Catat hasil scan sebagai satu log (PRD §6.4): item final yang sudah
  /// diedit pengguna, `groups` union canonical, `source = scan`.
  Future<FoodLog> addScanLog({
    required List<FoodLogItem> items,
    required MealType mealType,
    DateTime? at,
  }) async {
    if (items.isEmpty) {
      throw StateError('Tidak ada item yang disimpan.');
    }
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final touched = <String>{};
    for (final item in items) {
      touched.addAll(item.groups);
    }
    final groups = PiringDayEvaluator.canonicalOrder(touched);
    if (groups.isEmpty) {
      throw StateError('Setiap item harus punya minimal satu kelompok.');
    }
    final repo = ref.read(foodLogRepositoryProvider);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: at ?? ref.read(clockProvider)(),
        mealType: mealType,
        source: FoodLogSource.scan,
        items: items,
        groups: groups,
      ),
    );
    state = AsyncData([..._ordered, log]);
    _refreshHistory();
    return log;
  }

  /// Catat makan secara manual sebagai SATU log: jenis makan pilihan
  /// pengguna + beberapa kelompok sekaligus (PRD §6.4).
  ///
  /// Jalur ini melengkapi ketuk cepat per kelompok. `groups` selalu union
  /// canonical dan setiap kelompok menjadi satu item agar nama/porsi tetap
  /// terbaca di diary.
  Future<FoodLog> addManualMeal({
    required MealType mealType,
    required Map<String, String> groupLabels,
    String? portion,
    DateTime? at,
  }) async {
    if (groupLabels.isEmpty) {
      throw StateError('Pilih minimal satu kelompok.');
    }
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final groups = PiringDayEvaluator.canonicalOrder(groupLabels.keys);
    if (groups.isEmpty) {
      throw StateError('Kelompok pangan tidak dikenal.');
    }
    final repo = ref.read(foodLogRepositoryProvider);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: at ?? ref.read(clockProvider)(),
        mealType: mealType,
        source: FoodLogSource.manual,
        items: [
          for (final code in groups)
            FoodLogItem(
              name: groupLabels[code] ?? code,
              groups: [code],
              portion: portion,
            ),
        ],
        groups: groups,
      ),
    );
    state = AsyncData([..._ordered, log]);
    _refreshHistory();
    return log;
  }

  /// Catat satu kelompok pangan secara manual (ketuk cepat, PRD §6.4).
  ///
  /// Jenis makan tidak ditanyakan - kelompok pangan bukan sesi makan.
  /// `meal_type` disimpan sebagai klasifikasi kasar menurut jam perangkat
  /// (mis. sarapan <10.00) dan TIDAK ditampilkan di UI.
  Future<FoodLog> addManualGroup({
    required String groupCode,
    required String groupLabel,
    DateTime? at,
  }) async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final repo = ref.read(foodLogRepositoryProvider);
    final now = at ?? ref.read(clockProvider)();
    final canonical = PiringDayEvaluator.canonicalOrder([groupCode]);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: now,
        mealType: _inferMealType(now),
        source: FoodLogSource.manual,
        items: [
          FoodLogItem(
            name: groupLabel,
            groups: canonical,
          ),
        ],
        groups: canonical,
      ),
    );
    state = AsyncData([..._ordered, log]);
    _refreshHistory();
    return log;
  }

  /// Kembalikan catatan yang baru dihapus (aksi "Urungkan").
  Future<void> restoreLog(FoodLog log) async {
    final repo = ref.read(foodLogRepositoryProvider);
    final restored = await repo.addLog(
      FoodLog(
        id: '',
        childId: log.childId,
        eatenAt: log.eatenAt,
        mealType: log.mealType,
        source: log.source,
        items: log.items,
        groups: log.groups,
      ),
    );
    final now = ref.read(clockProvider)();
    if (_isSameDay(restored.eatenAt.toLocal(), now)) {
      state = AsyncData([..._ordered, restored]
        ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt)));
    }
    _refreshHistory();
  }

  /// Catat ASI untuk hari ini (toggle "ASI hari ini").
  Future<void> addBreastMilkToday() async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final today = ref.read(clockProvider)();
    final hasMilk = _ordered.any(
      (log) =>
          _isSameDay(log.eatenAt.toLocal(), today) &&
          log.groups.length == 1 &&
          log.groups.first == 'breast_milk',
    );
    if (hasMilk) return;
    final repo = ref.read(foodLogRepositoryProvider);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: today,
        mealType: MealType.snack,
        source: FoodLogSource.manual,
        items: const [
          FoodLogItem(name: 'ASI', groups: ['breast_milk']),
        ],
        groups: const ['breast_milk'],
      ),
    );
    state = AsyncData([..._ordered, log]);
    _refreshHistory();
  }

  /// Matikan toggle ASI untuk hari ini: hapus catatan ASI murni hari ini.
  /// Catatan campur yang memuat ASI TIDAK ikut dihapus.
  Future<void> removeBreastMilkToday() async {
    final repo = ref.read(foodLogRepositoryProvider);
    final today = ref.read(clockProvider)();
    final removable = [
      for (final log in _ordered)
        if (_isSameDay(log.eatenAt.toLocal(), today) &&
            log.groups.length == 1 &&
            log.groups.first == 'breast_milk')
          log,
    ];
    for (final log in removable) {
      await repo.deleteLog(log.id);
    }
    if (removable.isEmpty) return;
    final remaining = [
      for (final log in _ordered)
        if (!removable.contains(log)) log,
    ];
    state = AsyncData(remaining);
    _refreshHistory();
  }

  /// Hapus catatan hari ini yang mewakili satu kelompok (ketuk ulang tile).
  ///
  /// Hanya log dengan tepat satu kelompok tersebut yang dihapus; catatan
  /// gabungan (mis. hasil scan) tidak ikut terhapus.
  Future<void> removeGroupToday(String groupCode) async {
    final today = ref.read(clockProvider)();
    final removable = [
      for (final log in _ordered)
        if (_isSameDay(log.eatenAt.toLocal(), today) &&
            log.groups.length == 1 &&
            log.groups.first == groupCode)
          log,
    ];
    if (removable.isEmpty) return;
    final repo = ref.read(foodLogRepositoryProvider);
    for (final log in removable) {
      await repo.deleteLog(log.id);
    }
    final removedIds = {for (final log in removable) log.id};
    state = AsyncData([
      for (final log in _ordered)
        if (!removedIds.contains(log.id)) log,
    ]);
    _refreshHistory();
  }

  Future<void> deleteLog(String id) async {
    await ref.read(foodLogRepositoryProvider).deleteLog(id);
    state = AsyncData([
      for (final log in _ordered)
        if (log.id != id) log,
    ]);
    _refreshHistory();
  }

  static bool _isSameDay(DateTime a, DateTime day) =>
      a.year == day.year && a.month == day.month && a.day == day.day;

  /// Klasifikasi kasar jenis makan menurut jam perangkat (bukan klaim
  /// yang ditampilkan ke pengguna - lihat catatan di `addManualGroup`).
  static MealType _inferMealType(DateTime now) {
    final hour = now.hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }
}

/// Riwayat 30 hari terakhir (termasuk hari ini) untuk anak terpilih.
///
/// Jendela dibatasi agar query tidak pernah menarik seluruh riwayat. Dipakai
/// di Beranda (strip 7 hari) dan Makan (Riwayat); sengaja tanpa
/// `autoDispose` agar ticker mode saat pindah tab tidak memicu rebuild di
/// tengah build Riverpod.
final historyLogsProvider = FutureProvider.family<List<FoodLog>, String>(
  (ref, childId) {
    final now = ref.watch(clockProvider)();
    final range = localRecentDaysRange(
      now,
      HistoryEvaluator.defaultWindowDays,
    );
    return ref.watch(foodLogRepositoryProvider).listLogs(
          childId,
          from: range.from,
          to: range.to,
        );
  },
);

/// Ringkasan 30 hari terakhir untuk anak terpilih (ulang, kosong, protein
/// hewani). Evaluasi murni ada di [HistoryEvaluator].
final historySummaryProvider =
    FutureProvider.family<HistorySummary?, String>((ref, childId) async {
    final child = ref.watch(selectedChildProvider).value;
    if (child == null) return null;
    final rules = await ref.watch(nutritionRulesProvider.future);
    final logs = await ref.watch(historyLogsProvider(childId).future);
    final now = ref.watch(clockProvider)();
    return HistoryEvaluator.build(
      logs: logs,
      today: now,
      ageMonthsAt: child.ageInCompletedMonths,
      profiles: rules.profiles,
    );
  },
);

/// Ringkasan Piring Hari Ini (anak terpilih, hari ini, waktu perangkat).
///
/// Menggabungkan logs + aturan + usia; re-evaluasi saat logs berubah.
final piringTodayProvider =
    FutureProvider.family<PiringDay?, String>((ref, childId) async {
  final child = ref.watch(selectedChildProvider).value;
  if (child == null) return null;
  final rules = await ref.watch(nutritionRulesProvider.future);
  final logs = await ref.watch(foodLogsProvider(childId).future);
  final now = ref.watch(clockProvider)();
  final ageMonths = child.ageInCompletedMonths(now);
  return PiringDayEvaluator.evaluate(
    logs: logs,
    today: now,
    ageMonths: ageMonths,
    profiles: rules.profiles,
  );
});
