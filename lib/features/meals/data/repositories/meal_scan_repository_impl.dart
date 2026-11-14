import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/domain/repositories/meal_scan_repository.dart';

/// Implementasi `analyze-meal` (Edge Function, PRD §5.5).
///
/// Kunci Gemini TIDAK pernah ada di sini - hanya lewat function.
/// Foto dikompresi di sisi klien (≤ 1,5 MB) lalu dikirim base64; tidak
/// ada yang tersimpan di Storage atau database.
class MealScanRepositoryImpl implements MealScanRepository {
  const MealScanRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<MealScanResult> analyze({
    required List<int> imageBytes,
    required int ageMonths,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'analyze-meal',
        body: {
          'image_base64': base64Encode(imageBytes),
          'mime_type': 'image/jpeg',
          'age_months': ageMonths,
        },
      );
      final data = response.data;
      if (data is Map) {
        try {
          return MealScanResult.fromJson(Map<String, dynamic>.from(data));
        } on FormatException {
          throw const ScanException('ai_unavailable');
        }
      }
      throw const ScanException('ai_unavailable');
    } on ScanException {
      rethrow;
    } on FunctionException catch (exception) {
      throw ScanException(_codeOf(exception));
    } catch (_) {
      throw const ScanException('offline');
    }
  }

  static String _codeOf(FunctionException exception) {
    final details = exception.details;
    if (details is Map) {
      final code = details['error'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
      return 'ai_unavailable';
    }
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map && decoded['error'] is String) {
          return (decoded['error'] as String).trim();
        }
      } catch (_) {
        // bukan JSON - jatuh ke default di bawah
      }
    }
    return switch (exception.status) {
      429 => 'quota_daily',
      413 => 'image_too_large',
      400 => 'invalid_image',
      504 => 'timeout',
      _ => 'ai_unavailable',
    };
  }
}
