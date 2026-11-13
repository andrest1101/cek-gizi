import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';

/// Kontrak scan makanan (`analyze-meal` Edge Function).
abstract interface class MealScanRepository {
  /// Unggah foto (JPEG ≤ 1,5 MB) untuk dikenali. Melempar [ScanException]
  /// dengan kode PRD §5.5 bila gagal.
  Future<MealScanResult> analyze({
    required List<int> imageBytes,
    required int ageMonths,
  });
}
