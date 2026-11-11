import 'dart:convert';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Aturan keragaman pangan & tips harian (`assets/rules/nutrition_rules.json`).
///
/// Semua aturan berasal dari berkas itu — TIDAK di-hardcode (PRD §3.7,
/// aturan agen: jangan karangan data gizi). Berkas saat ini adalah seed
/// dari Lampiran A PRD dengan `reviewed_by: null` → konten BELUM ditinjau
/// ahli gizi; aplikasi WAJIB menampilkan penanda (PRD §9.1).
final class NutritionRules {
  const NutritionRules({
    required this.version,
    required this.groups,
    required this.animalSource,
    required this.profiles,
    required this.tips,
    this.reviewedBy,
    this.reviewedOn,
  });

  final String version;

  /// Delapan kode kelompok pangan (PRD §3.7) — persis divalidasi.
  final Set<String> groups;

  /// Sumber protein hewani (PRD §3.7) — persis [dairy, flesh, eggs].
  final Set<String> animalSource;

  /// Profil target keragaman (mpasi_6_23, balita_24_59, …). Tidak tumpang
  /// tindih; dipilih berdasarkan usia anak.
  final List<DiversityProfile> profiles;

  /// Tips per kelompok yang belum tercapai (dipakai kartu "Tips hari ini").
  final Map<String, String> tips;

  /// Peninjau (ahli gizi/bidan) atau null bila BELUM ditinjau (PRD §9.1).
  final String? reviewedBy;
  final String? reviewedOn;

  bool get isReviewed => reviewedBy != null;

  /// Profil target untuk usia tertentu; null bila tidak ada yang cocok.
  DiversityProfile? profileForAge(int ageMonths) =>
      DietaryDiversity.profileForAge(ageMonths, profiles);

  /// Tips untuk kelompok yang belum tercapai hari ini (urut [groups]).
  List<String> tipsForMissing(Set<String> missingGroups) =>
      [for (final code in FoodGroup.allCodes)
        if (missingGroups.contains(code) && tips.containsKey(code)) tips[code]!];
}

abstract final class NutritionRulesLoader {
  const NutritionRulesLoader._();

  static const allowedCountBasis = {'all', 'without_breast_milk'};
  static const _expectedAnimal = {'dairy', 'flesh', 'eggs'};

  static NutritionRules fromJsonString(String contents) {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: akar dokumen harus berupa objek JSON.',
      );
    }
    return fromJson(decoded);
  }

  static NutritionRules fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! String || version.trim().isEmpty) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "version" wajib ada (string).',
      );
    }

    // ── groups: tepat 8 kode tetap (PRD §3.7) ────────────────────
    final groupsRaw = json['groups'];
    if (groupsRaw is! List || groupsRaw.length != FoodGroup.allCodes.length) {
      throw InvalidReferenceDataException(
        'nutrition_rules.json: "groups" harus berisi tepat '
        '${FoodGroup.allCodes.length} kelompok.',
      );
    }
    final groups = <String>{};
    for (final item in groupsRaw) {
      if (item is! String || FoodGroup.fromCode(item) == null) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: kode kelompok tidak dikenal: $item',
        );
      }
      groups.add(item);
    }
    if (groups.length != FoodGroup.allCodes.length ||
        !FoodGroup.allCodes.every(groups.contains)) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "groups" harus persis 8 kode tetap PRD §3.7.',
      );
    }

    // ── animal_source: persis [dairy, flesh, eggs] ─────────────
    final animalRaw = json['animal_source'];
    if (animalRaw is! List || animalRaw.isEmpty) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "animal_source" wajib ada dan tidak kosong.',
      );
    }
    final animalSource = <String>{};
    for (final item in animalRaw) {
      if (item is! String || !groups.contains(item)) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: "animal_source" berisi kode non-kelompok: $item',
        );
      }
      animalSource.add(item);
    }
    if (animalSource.length != _expectedAnimal.length ||
        !_expectedAnimal.every(animalSource.contains)) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "animal_source" harus persis '
        '[dairy, flesh, eggs] (PRD §3.7).',
      );
    }

    // ── profiles: min<=max, tanpa tumpang tindih, count valid ───
    final profilesRaw = json['profiles'];
    if (profilesRaw is! Map || profilesRaw.isEmpty) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "profiles" wajib ada dan tidak kosong.',
      );
    }
    final profiles = <DiversityProfile>[];
    for (final entry in profilesRaw.entries) {
      final name = entry.key;
      final p = entry.value;
      if (p is! Map) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: profil "$name" harus berupa objek.',
        );
      }
      final min = p['min_age_months'];
      final max = p['max_age_months'];
      final target = p['target_groups'];
      final count = p['count'];
      if (min is! int || max is! int || min < 0 || min > max) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: profil "$name" rentang usia tidak valid.',
        );
      }
      if (target is! int || target < 1 || target > 8) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: profil "$name" target_groups tidak valid (1–8).',
        );
      }
      if (count is! String || !allowedCountBasis.contains(count)) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: profil "$name" count harus salah satu dari '
          '${allowedCountBasis.join(", ")}.',
        );
      }
      final withoutBreastMilk = count == 'without_breast_milk';
      final universeSize = withoutBreastMilk ? 7 : 8;
      if (target > universeSize) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: profil "$name" target $target melebihi '
          'semesta kelompoknya ($universeSize).',
        );
      }
      profiles.add(
        DiversityProfile(
          minAgeMonths: min,
          maxAgeMonths: max,
          targetGroups: target,
          countWithoutBreastMilk: withoutBreastMilk,
        ),
      );
    }
    profiles.sort((a, b) => a.minAgeMonths.compareTo(b.minAgeMonths));
    for (var i = 0; i < profiles.length - 1; i++) {
      if (profiles[i + 1].minAgeMonths <= profiles[i].maxAgeMonths) {
        throw const InvalidReferenceDataException(
          'nutrition_rules.json: rentang profil tumpang tindih.',
        );
      }
    }

    // ── tips: key harus kode kelompok dikenal, nilai tidak kosong ──
    final tipsRaw = json['tips'];
    if (tipsRaw is! Map) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "tips" harus berupa objek.',
      );
    }
    final tips = <String, String>{};
    for (final entry in tipsRaw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || !groups.contains(key)) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: kunci tips tidak dikenal: $key',
        );
      }
      if (value is! String || value.trim().isEmpty) {
        throw InvalidReferenceDataException(
          'nutrition_rules.json: nilai tips untuk "$key" kosong.',
        );
      }
      tips[key] = value;
    }

    // ── peninjauan (PRD §9.1): string atau null ───────────────────
    final reviewedBy = json['reviewed_by'];
    final reviewedOn = json['reviewed_on'];
    if (reviewedBy != null && reviewedBy is! String) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "reviewed_by" harus string atau null.',
      );
    }
    if (reviewedOn != null && reviewedOn is! String) {
      throw const InvalidReferenceDataException(
        'nutrition_rules.json: "reviewed_on" harus string atau null.',
      );
    }

    return NutritionRules(
      version: version,
      groups: groups,
      animalSource: animalSource,
      profiles: profiles,
      tips: tips,
      reviewedBy: reviewedBy,
      reviewedOn: reviewedOn,
    );
  }
}
