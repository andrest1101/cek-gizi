import '../entities/growth_measurement.dart';

/// Kontrak data pengukuran (implementasi di data layer via Supabase).
abstract interface class GrowthRepository {
  Future<List<GrowthMeasurement>> listMeasurements(String childId);

  Future<GrowthMeasurement?> findOnDate({
    required String childId,
    required DateTime date,
  });

  Future<GrowthMeasurement> insert(GrowthMeasurement measurement);

  Future<GrowthMeasurement> update(GrowthMeasurement measurement);

  Future<void> delete(String id);
}
