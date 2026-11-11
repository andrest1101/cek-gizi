import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/growth/data/models/growth_measurement_model.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_repository.dart';

/// CRUD pengukuran di Supabase (tabel `growth_measurements`, RLS aktif).
final class GrowthRepositoryImpl implements GrowthRepository {
  const GrowthRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, child_id, measured_on, weight_kg, length_height_cm, measure_mode, '
      'age_months, haz, waz, whz, status_haz, status_waz, status_whz, '
      'ref_version, note';

  @override
  Future<List<GrowthMeasurement>> listMeasurements(String childId) async {
    final rows = await _client
        .from('growth_measurements')
        .select(_columns)
        .eq('child_id', childId)
        .order('measured_on');
    return [
      for (final row in rows as List)
        GrowthMeasurementModel.fromMap(row as Map<String, dynamic>).measurement,
    ];
  }

  @override
  Future<GrowthMeasurement?> findOnDate({
    required String childId,
    required DateTime date,
  }) async {
    final iso = _isoDate(date);
    final row = await _client
        .from('growth_measurements')
        .select(_columns)
        .eq('child_id', childId)
        .eq('measured_on', iso)
        .maybeSingle();
    if (row == null) return null;
    return GrowthMeasurementModel.fromMap(row).measurement;
  }

  @override
  Future<GrowthMeasurement> insert(GrowthMeasurement measurement) async {
    final row = await _client
        .from('growth_measurements')
        .insert(GrowthMeasurementModel(measurement).toMap())
        .select(_columns)
        .single();
    return GrowthMeasurementModel.fromMap(row).measurement;
  }

  @override
  Future<GrowthMeasurement> update(GrowthMeasurement measurement) async {
    final row = await _client
        .from('growth_measurements')
        .update(GrowthMeasurementModel(measurement).toMap())
        .eq('id', measurement.id)
        .select(_columns)
        .single();
    return GrowthMeasurementModel.fromMap(row).measurement;
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('growth_measurements').delete().eq('id', id);
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
