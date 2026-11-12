import 'package:flutter/services.dart';

import 'package:cekgizi/domain_ref/nutrition_rules.dart';

/// Memuat aturan keragaman pangan dari asset (offline-safe).
///
/// Seed saat ini `reviewed_by: null` (belum ditinjau ahli gizi) - UI wajib
/// menampilkan penandanya (PRD §9.1); jangan mengarang aturan baru (PRD §3.7).
Future<NutritionRules> loadNutritionRules() async {
  final json = await rootBundle.loadString('assets/rules/nutrition_rules.json');
  return NutritionRulesLoader.fromJsonString(json);
}
