/// Keragaman pangan "Piring Hari Ini" (PRD §3.7).
///
/// Delapan kelompok (kode tetap, dipakai DB/DTO/UI). Aturan target HANYA
/// berasal dari `nutrition_rules.json` (disediakan pemilik) — tidak ada
/// angka target yang dihardcode di kode ini; kode ini menerima
/// [DiversityProfile] sebagai parameter.
library;

/// Delapan kelompok pangan (PRD §3.7).
enum FoodGroup {
  breastMilk('breast_milk'),
  grainsTubers('grains_tubers'),
  legumesNuts('legumes_nuts'),
  dairy('dairy'),
  flesh('flesh'),
  eggs('eggs'),
  vitAFruitVeg('vit_a_fruit_veg'),
  otherFruitVeg('other_fruit_veg');

  const FoodGroup(this.code);

  final String code;

  static const List<String> allCodes = [
    'breast_milk',
    'grains_tubers',
    'legumes_nuts',
    'dairy',
    'flesh',
    'eggs',
    'vit_a_fruit_veg',
    'other_fruit_veg',
  ];

  /// Protein hewani — pemeriksaan terpisah per hari (PRD §3.7).
  static const List<String> animalProteinCodes = ['dairy', 'flesh', 'eggs'];

  static FoodGroup? fromCode(String code) {
    for (final group in FoodGroup.values) {
      if (group.code == code) return group;
    }
    return null;
  }
}

/// Profil target keragaman dari `nutrition_rules.json` (PRD §3.7).
final class DiversityProfile {
  const DiversityProfile({
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.targetGroups,
    required this.countWithoutBreastMilk,
  });

  final int minAgeMonths;
  final int maxAgeMonths;

  /// Mis. 5 (MPASI 6–23 bulan, ≥ 5 dari 8 kelompok).
  final int targetGroups;

  /// true → hitung target tanpa menghitung ASI (profil 24–59 bulan, ≥5 dari 7).
  final bool countWithoutBreastMilk;

  bool supports(int ageMonths) =>
      ageMonths >= minAgeMonths && ageMonths <= maxAgeMonths;
}

/// Ringkasan keragaman untuk satu anak pada satu hari.
final class DiversitySummary {
  const DiversitySummary({
    required this.metGroups,
    required this.missingGroups,
    required this.target,
    required this.animalProteinPresent,
  });

  /// Kelompok yang terpenuhi hari ini (unik).
  final Set<String> metGroups;

  /// Kelompok yang belum terpenuhi hari ini (untuk tips harian).
  final Set<String> missingGroups;

  /// Target harian dari profil yang berlaku.
  final int target;

  /// Minimal satu protein hewani (`flesh`, `eggs`, `dairy`) hari ini.
  final bool animalProteinPresent;

  int get groupCount => metGroups.length;

  bool get isTargetReached => groupCount >= target;
}

abstract final class DietaryDiversity {
  const DietaryDiversity._();

  /// Usia minimum untuk fitur scanner (PRD §3.7: <6 bulan → ASI eksklusif).
  static const int minimumScanAgeMonths = 6;

  static bool isScanSupportedForAge(int ageMonths) =>
      ageMonths >= minimumScanAgeMonths;

  /// Pilih profil yang cocok dengan usia; null bila tidak ada yang cocok.
  static DiversityProfile? profileForAge(
    int ageMonths,
    List<DiversityProfile> profiles,
  ) {
    for (final profile in profiles) {
      if (profile.supports(ageMonths)) return profile;
    }
    return null;
  }

  /// Evaluasi gabungan kelompok dari semua catatan makan satu hari.
  ///
  /// [groupCodes] boleh duplikat; kode tak dikenal = data korup → [ArgumentError].
  static DiversitySummary evaluate({
    required Set<String> groupCodes,
    required DiversityProfile profile,
  }) {
    for (final code in groupCodes) {
      if (FoodGroup.fromCode(code) == null) {
        throw ArgumentError.value(code, 'groupCodes', 'Kelompok pangan tidak dikenal');
      }
    }

    final countedMet = profile.countWithoutBreastMilk
        ? groupCodes.difference({'breast_milk'})
        : {...groupCodes};

    final universe = profile.countWithoutBreastMilk
        ? FoodGroup.allCodes.toSet().difference({'breast_milk'})
        : FoodGroup.allCodes.toSet();

    final missing = universe.difference(countedMet);

    return DiversitySummary(
      metGroups: countedMet,
      missingGroups: missing,
      target: profile.targetGroups,
      animalProteinPresent: countedMet
          .any(FoodGroup.animalProteinCodes.contains),
    );
  }
}
