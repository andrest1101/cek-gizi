import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Mapping `food_logs` (PRD §5.2). Nilai tak dikenal = data korup →
/// [InvalidReferenceDataException] (jangan ditelan diam-diam).
final class FoodLogModel {
  const FoodLogModel(this.log);

  final FoodLog log;

  static FoodLog fromMap(Map<String, dynamic> row) {
    final id = row['id'];
    final childId = row['child_id'];
    final eatenAtRaw = row['eaten_at'];
    final mealTypeRaw = row['meal_type'];
    final sourceRaw = row['source'];
    final itemsRaw = row['items'];
    final groupsRaw = row['groups'];

    if (id is! String || childId is! String || eatenAtRaw is! String) {
      throw const InvalidReferenceDataException(
        'food_logs: kolom id/child_id/eaten_at tidak valid.',
      );
    }

    final items = <FoodLogItem>[];
    if (itemsRaw != null) {
      final list = itemsRaw as List;
      for (final item in list) {
        items.add(FoodLogItem.fromJson(item as Map<String, dynamic>));
      }
    }

    final groups = <String>[
      for (final group in (groupsRaw as List? ?? const []))
        _validGroup(group as String),
    ];

    return FoodLog(
      id: id,
      childId: childId,
      eatenAt: DateTime.parse(eatenAtRaw).toLocal(),
      mealType: _mealType(mealTypeRaw as String?),
      source: _source(sourceRaw as String?),
      items: items,
      groups: groups,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': log.childId,
      'eaten_at': log.eatenAt.toUtc().toIso8601String(),
      'meal_type': log.mealType.name,
      'source': log.source.name,
      'items': [for (final item in log.items) item.toJson()],
      'groups': log.groups,
    };
  }

  static String _validGroup(String code) {
    if (FoodGroup.fromCode(code) == null) {
      throw InvalidReferenceDataException(
        'food_logs: kelompok tidak dikenal: $code',
      );
    }
    return code;
  }

  static MealType _mealType(String? raw) => switch (raw) {
        'breakfast' => MealType.breakfast,
        'lunch' => MealType.lunch,
        'dinner' => MealType.dinner,
        'snack' => MealType.snack,
        _ => throw InvalidReferenceDataException(
            'food_logs: meal_type tidak dikenal: $raw',
          ),
      };

  static FoodLogSource _source(String? raw) => switch (raw) {
        'scan' => FoodLogSource.scan,
        'manual' => FoodLogSource.manual,
        'recipe' => FoodLogSource.recipe,
        _ => throw InvalidReferenceDataException(
            'food_logs: source tidak dikenal: $raw',
          ),
      };
}
