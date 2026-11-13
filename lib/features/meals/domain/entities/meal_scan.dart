import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Kualitas foto hasil analisis (PRD §5.5 `image_quality`).
enum MealScanImageQuality { ok, blur, dark, noFood }

/// Satu item terdeteksi pada foto makanan (PRD §5.5 `items`).
final class MealScanItem {
  const MealScanItem({
    required this.name,
    required this.groups,
    required this.confidence,
  });

  /// Nama makanan, maksimal 40 karakter (aturan server).
  final String name;

  /// Kelompok pangan (kode resmi PRD §3.7), 1–3 per item.
  final List<String> groups;

  /// Keyakinan model 0..1; jangan pernah dipakai untuk estimasi porsi.
  final double confidence;
}

/// Hasil lengkap `analyze-meal` untuk satu foto (PRD §5.5).
final class MealScanResult {
  const MealScanResult({
    required this.requestId,
    required this.isFood,
    required this.imageQuality,
    required this.items,
    this.notes,
  });

  final String requestId;
  final bool isFood;
  final MealScanImageQuality imageQuality;
  final List<MealScanItem> items;
  final String? notes;

  factory MealScanResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('items wajib berupa array.');
    }
    final items = <MealScanItem>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('item harus berupa objek.');
      }
      final name = raw['name'];
      final groups = raw['groups'];
      final confidence = raw['confidence'];
      if (name is! String || name.trim().isEmpty) {
        throw const FormatException('item tanpa nama.');
      }
      if (groups is! List) {
        throw const FormatException('item tanpa groups.');
      }
      final groupCodes = <String>[
        for (final code in groups)
          if (code is String && FoodGroup.fromCode(code) != null) code,
      ];
      if (groupCodes.isEmpty) {
        throw const FormatException('item tanpa kelompok dikenal.');
      }
      if (confidence is! num ||
          confidence < 0 ||
          confidence > 1) {
        throw const FormatException('confidence di luar 0..1.');
      }
      items.add(
        MealScanItem(
          name: name.trim().length > 40
              ? name.trim().substring(0, 40)
              : name.trim(),
          groups: List.unmodifiable(groupCodes),
          confidence: confidence.toDouble(),
        ),
      );
    }
    if (items.length > 12) {
      throw const FormatException('maksimal 12 item.');
    }

    final isFood = json['is_food'];
    if (isFood is! bool) {
      throw const FormatException('is_food wajib ada (bool).');
    }

    final quality = switch (json['image_quality']) {
      'ok' => MealScanImageQuality.ok,
      'blur' => MealScanImageQuality.blur,
      'dark' => MealScanImageQuality.dark,
      'no_food' => MealScanImageQuality.noFood,
      _ => throw const FormatException('image_quality tidak dikenal.'),
    };

    final requestId = json['request_id'];
    if (requestId is! String || requestId.trim().isEmpty) {
      throw const FormatException('request_id wajib ada.');
    }

    final notes = json['notes'];
    if (notes != null && notes is! String) {
      throw const FormatException('notes harus string atau null.');
    }

    return MealScanResult(
      requestId: requestId.trim(),
      isFood: isFood,
      imageQuality: quality,
      items: List.unmodifiable(items),
      notes: notes as String?,
    );
  }
}

/// Kegagalan scan yang sudah diterjemahkan (tanpa pesan mentah).
/// [code] memakai kode PRD §5.5: `invalid_image`, `image_too_large`,
/// `quota_daily`, `ai_unavailable`, `timeout`, `unauthorized`, `offline`.
final class ScanException implements Exception {
  const ScanException(this.code);

  final String code;

  @override
  String toString() => 'ScanException($code)';
}
