/// Satu catatan makan (PRD §5.2, §6.4).
///
/// `groups` adalah gabungan kelompok pangan (union) dari semua item pada
/// catatan ini - disimpan denormal sesuai skema agar perhitungan keragaman
/// harian tidak perlu membongkar `items`. Nilai selalu kode resmi PRD §3.7.
enum MealType { breakfast, lunch, dinner, snack }

enum FoodLogSource { scan, manual, recipe }

final class FoodLogItem {
  const FoodLogItem({
    required this.name,
    required this.groups,
    this.portion,
  });

  final String name;
  final List<String> groups;

  /// Porsi opsional: 'sedikit' | 'sedang' | 'habis' (dipakai sheet hasil scan).
  final String? portion;

  Map<String, dynamic> toJson() => {
        'name': name,
        'groups': groups,
        if (portion != null) 'portion': portion,
      };

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Item tanpa nama.');
    }
    final groups = json['groups'];
    if (groups is! List) {
      throw const FormatException('Item tanpa kelompok.');
    }
    return FoodLogItem(
      name: name,
      groups: [for (final group in groups) group as String],
      portion: json['portion'] as String?,
    );
  }
}

final class FoodLog {
  const FoodLog({
    required this.id,
    required this.childId,
    required this.eatenAt,
    required this.mealType,
    required this.source,
    required this.items,
    required this.groups,
  });

  final String id;
  final String childId;

  /// Waktu makan (zone device saat dibuat; disimpan sebagai timestamptz).
  final DateTime eatenAt;
  final MealType mealType;
  final FoodLogSource source;
  final List<FoodLogItem> items;

  /// Union kelompok dari seluruh item - diurutkan [FoodGroup.allCodes].
  final List<String> groups;

  FoodLog copyWith({
    String? id,
    DateTime? eatenAt,
    MealType? mealType,
    FoodLogSource? source,
    List<FoodLogItem>? items,
    List<String>? groups,
  }) {
    return FoodLog(
      id: id ?? this.id,
      childId: childId,
      eatenAt: eatenAt ?? this.eatenAt,
      mealType: mealType ?? this.mealType,
      source: source ?? this.source,
      items: items ?? this.items,
      groups: groups ?? this.groups,
    );
  }
}
