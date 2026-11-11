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
  Future<void> addManualGroup({
    required String groupCode,
    required String groupLabel,
    required MealType mealType,
  }) async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) throw StateError('Tidak ada anak yang dipilih.');
    final repo = ref.read(foodLogRepositoryProvider);
    final canonical = PiringDayEvaluator.canonicalOrder([groupCode]);
    final log = await repo.addLog(
      FoodLog(
        id: '',
        childId: child.id,
        eatenAt: DateTime.now(),
        mealType: mealType,
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

  Future<void> deleteLog(String id) async {
    await ref.read(foodLogRepositoryProvider).deleteLog(id);
    state = AsyncData([
      for (final log in _ordered)
        if (log.id != id) log,
    ]);
  }

  static bool _isSameDay(DateTime a, DateTime day) =>
      a.year == day.year && a.month == day.month && a.day == day.day;
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
