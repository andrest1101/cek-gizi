import 'package:cekgizi/features/meals/domain/entities/food_log.dart';

/// Kontrak repository catatan makan (PRD §5.2, §6.4).
///
/// Implementasi konkret (Supabase) berada di data layer; kontrak ini murni
/// Dart agar mudah dites.
abstract interface class FoodLogRepository {
  /// Semua catatan makan milik [childId], urut [FoodLog.eatenAt] naik.
  Future<List<FoodLog>> listLogs(String childId);

  /// Simpan catatan baru (id diabaikan/digantikan server).
  Future<FoodLog> addLog(FoodLog log);

  /// Hapus catatan berdasarkan id.
  Future<void> deleteLog(String id);
}
