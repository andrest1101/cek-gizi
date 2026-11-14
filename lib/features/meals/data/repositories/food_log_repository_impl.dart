import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/meals/data/models/food_log_model.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/repositories/food_log_repository.dart';

/// CRUD catatan makan di Supabase (tabel `food_logs`, RLS aktif).
final class FoodLogRepositoryImpl implements FoodLogRepository {
  const FoodLogRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, child_id, eaten_at, meal_type, source, items, groups';

  /// Pagar keras agar satu permintaan tidak pernah menarik ribuan baris.
  /// Rentang tanggal di UI selalu jauh di bawah angka ini.
  static const int _maxRowsPerRequest = 1000;

  @override
  Future<List<FoodLog>> listLogs(
    String childId, {
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('food_logs')
        .select(_columns)
        .eq('child_id', childId);

    // `eaten_at` adalah timestamptz. Batas hari dihitung di zona perangkat,
    // lalu dikirim dalam UTC agar perbandingan di server tepat.
    if (from != null) {
      query = query.gte('eaten_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lt('eaten_at', to.toUtc().toIso8601String());
    }

    final rows = await query
        .order('eaten_at')
        .limit(_maxRowsPerRequest);
    return [
      for (final row in rows as List)
        FoodLogModel.fromMap(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<FoodLog> addLog(FoodLog log) async {
    final row = await _client
        .from('food_logs')
        .insert(FoodLogModel(log).toMap())
        .select(_columns)
        .single();
    return FoodLogModel.fromMap(row);
  }

  @override
  Future<void> deleteLog(String id) async {
    await _client.from('food_logs').delete().eq('id', id);
  }
}
