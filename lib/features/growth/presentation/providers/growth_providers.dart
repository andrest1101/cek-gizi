import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/domain_ref/permenkes_asset.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/data/repositories/growth_repository_impl.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_repository.dart';
import 'package:cekgizi/features/growth/domain/use_cases/save_measurement.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

final growthRepositoryProvider = Provider<GrowthRepository>(
  (ref) => GrowthRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Tabel SD Permenkes 2/2020 dimuat sekali dari asset (offline-safe).
final permenkesTablesProvider =
    FutureProvider<AnthropometryReferenceTables>((ref) => loadPermenkesTables());

final measurementsProvider = AsyncNotifierProvider.autoDispose
    .family<MeasurementsNotifier, List<GrowthMeasurement>, String>(
  MeasurementsNotifier.new,
);

class MeasurementsNotifier extends AsyncNotifier<List<GrowthMeasurement>> {
  MeasurementsNotifier(this.childId);

  final String childId;

  @override
  Future<List<GrowthMeasurement>> build() =>
      ref.watch(growthRepositoryProvider).listMeasurements(childId);

  Future<GrowthMeasurement> addMeasurement({
    required DateTime measuredOn,
    required double weightKg,
    required double lengthHeightCm,
    required MeasureMode mode,
    String? note,
  }) async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) {
      throw StateError('Tidak ada anak yang dipilih.');
    }
    final tables = await ref.read(permenkesTablesProvider.future);
    final saved = await SaveMeasurement.add(
      repository: ref.read(growthRepositoryProvider),
      child: child,
      measuredOn: measuredOn,
      weightKg: weightKg,
      lengthHeightCm: lengthHeightCm,
      mode: mode,
      tables: tables,
      note: note,
    );
    state = AsyncData([...?state.value, saved]);
    return saved;
  }

  Future<GrowthMeasurement> updateMeasurement({
    required GrowthMeasurement existing,
    required double weightKg,
    required double lengthHeightCm,
    required MeasureMode mode,
    String? note,
  }) async {
    final child = ref.read(selectedChildProvider).value;
    if (child == null) {
      throw StateError('Tidak ada anak yang dipilih.');
    }
    final tables = await ref.read(permenkesTablesProvider.future);
    final saved = await SaveMeasurement.update(
      repository: ref.read(growthRepositoryProvider),
      child: child,
      existing: existing,
      weightKg: weightKg,
      lengthHeightCm: lengthHeightCm,
      mode: mode,
      tables: tables,
      note: note,
    );
    state = AsyncData([
      for (final m in state.value ?? const <GrowthMeasurement>[])
        if (m.id == saved.id) saved else m,
    ]);
    return saved;
  }

  Future<void> deleteMeasurement(String id) async {
    await ref.read(growthRepositoryProvider).delete(id);
    state = AsyncData([
      for (final m in state.value ?? const <GrowthMeasurement>[])
        if (m.id != id) m,
    ]);
  }
}
