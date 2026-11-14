import 'package:cekgizi/features/meals/domain/entities/food_log.dart';

/// Kontrak repository catatan makan (PRD §5.2, §6.4).
///
/// Implementasi konkret (Supabase) berada di data layer; kontrak ini murni
/// Dart agar mudah dites.
abstract interface class FoodLogRepository {
  /// Catatan makan milik [childId] pada rentang waktu tertentu, urut
  /// [FoodLog.eatenAt] naik.
  ///
  /// [from] inklusif dan [to] eksklusif, dalam waktu lokal perangkat. Bila
  /// keduanya null, seluruh riwayat dikembalikan (hindari di UI; selalu
  /// kirim rentang agar query terbatas dan hemat).
  Future<List<FoodLog>> listLogs(
    String childId, {
    DateTime? from,
    DateTime? to,
  });

  /// Simpan catatan baru (id diabaikan/digantikan server).
  Future<FoodLog> addLog(FoodLog log);

  /// Hapus catatan berdasarkan id.
  Future<void> deleteLog(String id);
}
