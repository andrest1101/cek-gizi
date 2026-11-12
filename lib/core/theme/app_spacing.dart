/// Skala ruang 4pt (PRD §7.4). Jangan pakai angka spacing aneh di widget -
/// ambil dari sini.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4dp - jarak antar busur, celah terkecil.
  static const double xs = 4;

  /// 8dp
  static const double sm = 8;

  /// 12dp
  static const double md = 12;

  /// 16dp
  static const double lg = 16;

  /// 20dp - padding layar.
  static const double xl = 20;

  /// 24dp
  static const double xxl = 24;

  /// 32dp
  static const double xxxl = 32;

  /// Padding horizontal konten layar (PRD §7.4).
  static const double screenPadding = 20;

  /// Jarak antar section vertikal (PRD §7.4).
  static const double sectionGap = 28;
}
