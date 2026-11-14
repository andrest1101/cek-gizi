import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/features/meals/data/repositories/meal_scan_repository_impl.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/domain/repositories/meal_scan_repository.dart';

final mealScanRepositoryProvider = Provider<MealScanRepository>(
  (ref) => MealScanRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Daftar kamera yang tersedia - dipisah jadi provider agar widget test
/// bisa meng-override tanpa plugin kamera.
final availableCamerasProvider = FutureProvider<List<CameraDescription>>(
  (ref) => availableCameras(),
);

/// Kompresi foto hasil scan - dipisah jadi antarmuka agar widget test
/// tidak memuat plugin kamera/kompresi.
abstract interface class ScanImageCompressor {
  /// Mengembalikan JPEG ≤ 300 KB bila memungkinkan; melempar [ScanException]
  /// `image_too_large` bila hasil akhir masih > 1,5 MB (batas server).
  Future<List<int>> compress(File file);
}

final class FlutterImageCompressorImpl implements ScanImageCompressor {
  const FlutterImageCompressorImpl();

  static const _targetMaxBytes = 300_000;
  static const _serverHardLimitBytes = 1_500_000;
  static const _qualitySteps = [75, 65, 55, 45];

  @override
  Future<List<int>> compress(File file) async {
    for (final quality in _qualitySteps) {
      final bytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (bytes == null) {
        throw const ScanException('invalid_image');
      }
      // EXIF/GPS dihapus oleh plugin (default); file sementara tidak disimpan.
      if (bytes.length <= _targetMaxBytes) return bytes;
      if (quality == _qualitySteps.last) {
        if (bytes.length <= _serverHardLimitBytes) return bytes;
        throw const ScanException('image_too_large');
      }
    }
    throw const ScanException('ai_unavailable');
  }
}

final mealScanCompressorProvider =
    Provider<ScanImageCompressor>((ref) => const FlutterImageCompressorImpl());
