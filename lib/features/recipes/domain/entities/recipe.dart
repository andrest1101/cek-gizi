/// Resep MPASI terkurasi (PRD §6.6, §9.1).
///
/// Seluruh isi berasal dari `assets/recipes/recipes.json` yang disediakan
/// pemilik proyek - TIDAK ada resep, bahan, atau langkah yang dikarang kode.
/// Entity ini murni Dart agar mudah diuji.
library;

/// Rentang usia resep (PRD §6.6: 6–8, 9–11, 12–23, 24+ bulan).
enum RecipeAgeBand {
  months6to8('6-8', 6, 8),
  months9to11('9-11', 9, 11),
  months12to23('12-23', 12, 23),
  months24plus('24+', 24, null);

  const RecipeAgeBand(this.code, this.minMonths, this.maxMonths);

  /// Kode persis seperti di berkas JSON.
  final String code;

  final int minMonths;

  /// null = tanpa batas atas (24+ bulan).
  final int? maxMonths;

  static RecipeAgeBand? fromCode(String code) {
    for (final band in RecipeAgeBand.values) {
      if (band.code == code) return band;
    }
    return null;
  }

  /// Rentang yang cocok untuk usia anak; null bila < 6 bulan (ASI eksklusif).
  static RecipeAgeBand? forAge(int ageMonths) {
    for (final band in RecipeAgeBand.values) {
      if (band.supports(ageMonths)) return band;
    }
    return null;
  }

  bool supports(int ageMonths) =>
      ageMonths >= minMonths && (maxMonths == null || ageMonths <= maxMonths!);
}

/// Satu bahan beserta takarannya (teks apa adanya dari berkas resep).
final class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.amount});

  final String name;
  final String amount;
}

/// Satu resep terkurasi.
final class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ageBand,
    required this.minutes,
    required this.ingredients,
    required this.steps,
    required this.groups,
    required this.animalProtein,
    required this.textureNote,
    required this.allergenNote,
    this.reviewedBy,
    this.reviewedOn,
  });

  final String id;
  final String title;
  final RecipeAgeBand ageBand;

  /// Perkiraan waktu memasak (menit) - berasal dari berkas, bukan dihitung.
  final int minutes;

  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  /// Kode kelompok pangan (PRD §3.7), sudah urut canonical.
  final List<String> groups;

  /// Penanda protein hewani dari berkas resep.
  final bool animalProtein;

  /// Catatan tekstur sesuai usia (wajib ada).
  final String textureNote;

  /// Catatan alergen/keamanan; boleh kosong bila tidak ada alergen umum.
  final String allergenNote;

  /// Peninjau (ahli gizi/bidan) atau null bila BELUM ditinjau (PRD §9.1).
  final String? reviewedBy;
  final String? reviewedOn;

  bool get isReviewed => reviewedBy != null && reviewedBy!.trim().isNotEmpty;

  bool get hasAllergenNote => allergenNote.trim().isNotEmpty;

  int get groupCount => groups.length;
}
