import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';

/// Label jenis makan (dipakai composer & hasil scan).
String mealTypeLabel(MealType type) => switch (type) {
      MealType.breakfast => AppStrings.mealBreakfast,
      MealType.lunch => AppStrings.mealLunch,
      MealType.dinner => AppStrings.mealDinner,
      MealType.snack => AppStrings.mealSnack,
    };

/// Jenis makan awal menurut jam perangkat. Bukan klaim yang ditampilkan
/// sebagai fakta - pengguna selalu bisa menggantinya di composer.
MealType defaultMealTypeFor(DateTime now) {
  final hour = now.hour;
  if (hour < 10) return MealType.breakfast;
  if (hour < 14) return MealType.lunch;
  if (hour < 17) return MealType.snack;
  return MealType.dinner;
}

/// Label porsi yang tersimpan di `items[].portion`.
String portionLabel(String portion) => switch (portion) {
      'sedikit' => AppStrings.portionLittle,
      'sedang' => AppStrings.portionMedium,
      'habis' => AppStrings.portionFinished,
      _ => portion,
    };

/// Ikon kelompok pangan. Selalu dipakai bersama label teks, tidak pernah
/// menjadi satu-satunya penanda (PRD §7.2).
IconData foodGroupIcon(String code) => switch (code) {
      'breast_milk' => Icons.water_drop_rounded,
      'grains_tubers' => Icons.rice_bowl_rounded,
      'legumes_nuts' => Icons.grain_rounded,
      'dairy' => Icons.local_drink_rounded,
      'flesh' => Icons.set_meal_rounded,
      'eggs' => Icons.egg_rounded,
      'vit_a_fruit_veg' => Icons.eco_rounded,
      'other_fruit_veg' => Icons.apple_rounded,
      _ => Icons.restaurant_rounded,
    };

/// Urutan tampil checklist: ASI selalu baris pertama (bila relevan), lalu
/// urutan tetap PRD §3.7.
List<String> checklistCodes({required bool includeBreastMilk}) => [
      if (includeBreastMilk) 'breast_milk',
      'grains_tubers',
      'legumes_nuts',
      'dairy',
      'flesh',
      'eggs',
      'vit_a_fruit_veg',
      'other_fruit_veg',
    ];
