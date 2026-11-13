import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/meals/data/models/food_log_model.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/repositories/food_log_repository.dart';

/// CRUD catatan makan di Supabase (tabel `food_logs`, RLS aktif).
final class FoodLogRepositoryImpl implements FoodLogRepository {
  const FoodLogRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, child_id, eaten_at, meal_type, source, items, groups';

  @override
  Future<List<FoodLog>> listLogs(String childId) async {
    final rows = await _client
        .from('food_logs')
        .select(_columns)
        .eq('child_id', childId)
        .order('eaten_at');
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
