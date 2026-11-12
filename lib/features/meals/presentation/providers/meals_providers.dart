import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/domain_ref/nutrition_rules.dart';
import 'package:cekgizi/domain_ref/nutrition_rules_asset.dart';
import 'package:cekgizi/features/meals/data/repositories/food_log_repository_impl.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/repositories/food_log_repository.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>(
  (ref) => FoodLogRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Aturan keragaman pangan dari asset (offline-safe).
final nutritionRulesProvider =
    FutureProvider<NutritionRules>((ref) => loadNutritionRules());

final foodLogsProvider = AsyncNotifierProvider.autoDispose
    .family<FoodLogsNotifier, List<FoodLog>, String>(
  FoodLogsNotifier.new,
);

class FoodLogsNotifier extends AsyncNotifier<List<FoodLog>> {
  FoodLogsNotifier(this.childId);

  final String childId;

  @override
  Future<List<FoodLog>> build() =>
      ref.watch(foodLogRepositoryProvider).listLogs(childId);

  List<FoodLog> get _ordered =>
      [...?state.value]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));

  /// Catat satu kelompok pangan secara manual (PRD §6.4).
  ///
  /// Jenis makan tidak ditanyakan - kelompok pangan bukan sesi makan.
  /// `meal_type` disimpan sebagai klasifikasi kasar menurut jam perangkat
  /// (mis. sarapan <10.00) dan TIDAK ditampilkan di UI; waktu makan yang
  /// relevan untuk catatan bernama (scanner/resep) menyusul di Batch 5/8.
  Future<FoodLog> addManualGroup({
    required String groupCode,
    required String groupLabel,
    DateTime? at,
  }) async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final repo = ref.read(foodLogRepositoryProvider);
    final now = at ?? DateTime.now();
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
    state = AsyncData([..._ordered, restored]
      ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt)));
  }

  /// Catat ASI untuk hari ini (toggle "ASI hari ini").
  Future<void> addBreastMilkToday() async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final today = DateTime.now();
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
  }

  /// Matikan toggle ASI untuk hari ini: hapus catatan ASI murni hari ini.
  /// Catatan campur yang memuat ASI TIDAK ikut dihapus.
  Future<void> removeBreastMilkToday() async {
    final repo = ref.read(foodLogRepositoryProvider);
    final today = DateTime.now();
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
  }

  /// Hapus catatan hari ini yang mewakili satu kelompok (ketuk ulang tile).
  ///
  /// Hanya log dengan tepat satu kelompok tersebut yang dihapus; catatan
  /// gabungan (mis. hasil scan) tidak ikut terhapus.
  Future<void> removeGroupToday(String groupCode) async {
    final today = DateTime.now();
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
  }

  Future<void> deleteLog(String id) async {
    await ref.read(foodLogRepositoryProvider).deleteLog(id);
    state = AsyncData([
      for (final log in _ordered)
        if (log.id != id) log,
    ]);
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

/// Ringkasan Piring Hari Ini (anak terpilih, hari ini, waktu perangkat).
///
/// Menggabungkan logs + aturan + usia; re-evaluasi saat logs berubah.
final piringTodayProvider =
    FutureProvider.autoDispose.family<PiringDay?, String>((ref, childId) async {
  final child = ref.watch(selectedChildProvider).value;
  if (child == null) return null;
  final rules = await ref.watch(nutritionRulesProvider.future);
  final logs = await ref.watch(foodLogsProvider(childId).future);
  final ageMonths = child.ageInCompletedMonths(DateTime.now());
  return PiringDayEvaluator.evaluate(
    logs: logs,
    today: DateTime.now(),
    ageMonths: ageMonths,
    profiles: rules.profiles,
  );
});
