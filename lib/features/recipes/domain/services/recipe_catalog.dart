import 'package:cekgizi/features/recipes/domain/entities/recipe.dart';

/// Filter & pencarian katalog resep (PRD §6.6). Murni Dart, tanpa Flutter.
///
/// Tidak ada "rekomendasi" karangan: penyaringan hanya memakai rentang usia
/// yang tertulis di berkas resep, teks judul/bahan, dan penanda protein
/// hewani dari berkas yang sama.
abstract final class RecipeCatalog {
  const RecipeCatalog._();

  /// Normalisasi teks pencarian: huruf kecil, spasi berlebih dirapatkan.
  static String normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Saring katalog. [band] null = semua usia.
  static List<Recipe> filter(
    List<Recipe> recipes, {
    RecipeAgeBand? band,
    String query = '',
    bool animalProteinOnly = false,
  }) {
    final needle = normalize(query);
    return [
      for (final recipe in recipes)
        if ((band == null || recipe.ageBand == band) &&
            (!animalProteinOnly || recipe.animalProtein) &&
            (needle.isEmpty || _matches(recipe, needle)))
          recipe,
    ];
  }

  /// Urut stabil: rentang usia (6–8 → 24+), lalu judul alfabetis.
  static List<Recipe> sorted(List<Recipe> recipes) {
    final copy = [...recipes];
    copy.sort((a, b) {
      final byBand = a.ageBand.index.compareTo(b.ageBand.index);
      if (byBand != 0) return byBand;
      return normalize(a.title).compareTo(normalize(b.title));
    });
    return copy;
  }

  /// Resep yang cocok untuk usia anak; kosong bila < 6 bulan.
  static List<Recipe> forAge(List<Recipe> recipes, int ageMonths) {
    final band = RecipeAgeBand.forAge(ageMonths);
    if (band == null) return const [];
    return sorted(filter(recipes, band: band));
  }

  /// Resep unggulan "Ide hari ini" - deterministik per tanggal perangkat.
  ///
  /// Tidak memakai acak agar tampilan stabil sepanjang hari dan bisa diuji
  /// dengan jam palsu. [recipes] sebaiknya sudah tersaring & terurut.
  static Recipe? featured(List<Recipe> recipes, DateTime at) {
    if (recipes.isEmpty) return null;
    // Tanggal kalender murni (UTC) agar indeks tidak bergeser oleh zona waktu
    // atau pergantian DST di perangkat pengguna.
    final day = DateTime.utc(at.year, at.month, at.day);
    final startOfYear = DateTime.utc(at.year, 1, 1);
    final dayOfYear = day.difference(startOfYear).inDays;
    return recipes[dayOfYear % recipes.length];
  }

  static bool _matches(Recipe recipe, String needle) {
    if (normalize(recipe.title).contains(needle)) return true;
    for (final ingredient in recipe.ingredients) {
      if (normalize(ingredient.name).contains(needle)) return true;
    }
    return false;
  }
}
