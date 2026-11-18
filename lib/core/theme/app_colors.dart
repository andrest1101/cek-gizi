import 'package:flutter/material.dart';

/// Semua token warna (PRD §7.2) sebagai `ThemeExtension`.
///
/// Widget DILARANG memakai literal warna - ambil dari sini:
/// `Theme.of(context).extension<AppColors>()!.primary`.
///
/// `statusWatch` = warna isi status "perlu perhatian" (ikon/pita),
/// `statusWatchText` = warna teks status tersebut (kontras ≥ 4,5:1).
/// Di dark theme keduanya sama.
///
/// **Permukaan hero (v2.1).** Satu layar punya satu permukaan solid dominan
/// ([heroSurface]) dengan teks di atasnya ([onHeroSurface],
/// [onHeroSurfaceMuted], [onHeroAccent]). Di light theme hero memakai hijau
/// tua `primary`; di dark theme hijau dinaikkan satu tone + hairline
/// [heroEdge] agar tidak melebur dengan latar `#101713`.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.accent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.statusGood,
    required this.statusWatch,
    required this.statusWatchText,
    required this.statusAlert,
    required this.heroSurface,
    required this.onHeroSurface,
    required this.onHeroSurfaceMuted,
    required this.onHeroAccent,
    required this.heroTrack,
    required this.heroEdge,
  });

  /// Latar layar (krem hangat `#FBF7F0` / `#101713`).
  final Color background;

  /// Kartu, sheet, nav (`#FFFFFF` / `#17211B`).
  final Color surface;

  /// Blok halus, busur belum menyala (`#F1EBDD` / `#1F2C25`).
  final Color surfaceVariant;

  /// Hairline 1px (`#E6DDCB` / `#2C3B33`).
  final Color outline;

  final Color textPrimary;
  final Color textSecondary;

  /// Aksi utama, busur menyala (`#1F6F54` / `#7FD1A8`).
  final Color primary;
  final Color onPrimary;

  /// Permukaan tonal lembut - indikator tab aktif, lingkaran ikon.
  final Color primaryContainer;

  /// Busur protein hewani, sorotan hangat (`#E9893B` / `#F2A55F`).
  final Color accent;

  /// Latar tonal hangat untuk pita/chip "perlu perhatian"
  /// (`#FBE8D6` / `#3E2A19`). Pasangan teksnya [onAccentContainer].
  final Color accentContainer;

  /// Teks/ikon di atas [accentContainer] (kontras ≥ 4,5:1 di kedua mode).
  final Color onAccentContainer;

  /// Status normal (`#2E7D32` / `#7BD88F`).
  final Color statusGood;

  /// Status perlu perhatian - isi (`#F2B84B` / `#F2C14E`).
  final Color statusWatch;

  /// Status perlu perhatian - teks (`#8A5A12` / `#F2C14E`).
  final Color statusWatchText;

  /// Status perlu diperiksa segera (`#C0392B` / `#FF8E80`).
  final Color statusAlert;

  /// Permukaan hero dominan (`#1F6F54` / `#1E4A38`).
  final Color heroSurface;

  /// Teks/ikon utama di atas [heroSurface] (kontras ≥ 4,5:1 di kedua mode).
  final Color onHeroSurface;

  /// Teks sekunder di atas [heroSurface].
  final Color onHeroSurfaceMuted;

  /// Sorotan hangat di atas [heroSurface] (mis. protein hewani belum ada).
  final Color onHeroAccent;

  /// Busur ring yang belum terisi di atas [heroSurface].
  final Color heroTrack;

  /// Garis tepi hero. Transparan di light (kontras sudah cukup), hijau
  /// terang di dark agar batas permukaan terbaca.
  final Color heroEdge;

  static const light = AppColors(
    background: Color(0xFFFBF7F0),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1EBDD),
    outline: Color(0xFFE6DDCB),
    textPrimary: Color(0xFF1E2A25),
    textSecondary: Color(0xFF5F6B64),
    primary: Color(0xFF1F6F54),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8EBDD),
    accent: Color(0xFFE9893B),
    accentContainer: Color(0xFFFBE8D6),
    onAccentContainer: Color(0xFF7A4318),
    statusGood: Color(0xFF2E7D32),
    statusWatch: Color(0xFFF2B84B),
    statusWatchText: Color(0xFF8A5A12),
    statusAlert: Color(0xFFC0392B),
    heroSurface: Color(0xFF1F6F54),
    onHeroSurface: Color(0xFFFFFFFF),
    onHeroSurfaceMuted: Color(0xFFD8E9DF),
    onHeroAccent: Color(0xFFFFE0C2),
    heroTrack: Color(0xFF3C8069),
    heroEdge: Color(0x00000000),
  );

  static const dark = AppColors(
    background: Color(0xFF101713),
    surface: Color(0xFF17211B),
    surfaceVariant: Color(0xFF1F2C25),
    outline: Color(0xFF2C3B33),
    textPrimary: Color(0xFFE9F0EB),
    textSecondary: Color(0xFFA3B1A8),
    primary: Color(0xFF7FD1A8),
    onPrimary: Color(0xFF06251A),
    primaryContainer: Color(0xFF1B4A38),
    accent: Color(0xFFF2A55F),
    accentContainer: Color(0xFF3E2A19),
    onAccentContainer: Color(0xFFF7C79B),
    statusGood: Color(0xFF7BD88F),
    statusWatch: Color(0xFFF2C14E),
    statusWatchText: Color(0xFFF2C14E),
    statusAlert: Color(0xFFFF8E80),
    heroSurface: Color(0xFF1E4A38),
    onHeroSurface: Color(0xFFEAF6EF),
    onHeroSurfaceMuted: Color(0xFFB9D6C6),
    onHeroAccent: Color(0xFFF7B77C),
    heroTrack: Color(0xFF2C6A50),
    heroEdge: Color(0xFF2F6A52),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? accent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? statusGood,
    Color? statusWatch,
    Color? statusWatchText,
    Color? statusAlert,
    Color? heroSurface,
    Color? onHeroSurface,
    Color? onHeroSurfaceMuted,
    Color? onHeroAccent,
    Color? heroTrack,
    Color? heroEdge,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      statusGood: statusGood ?? this.statusGood,
      statusWatch: statusWatch ?? this.statusWatch,
      statusWatchText: statusWatchText ?? this.statusWatchText,
      statusAlert: statusAlert ?? this.statusAlert,
      heroSurface: heroSurface ?? this.heroSurface,
      onHeroSurface: onHeroSurface ?? this.onHeroSurface,
      onHeroSurfaceMuted: onHeroSurfaceMuted ?? this.onHeroSurfaceMuted,
      onHeroAccent: onHeroAccent ?? this.onHeroAccent,
      heroTrack: heroTrack ?? this.heroTrack,
      heroEdge: heroEdge ?? this.heroEdge,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(
        accentContainer,
        other.accentContainer,
        t,
      )!,
      onAccentContainer: Color.lerp(
        onAccentContainer,
        other.onAccentContainer,
        t,
      )!,
      statusGood: Color.lerp(statusGood, other.statusGood, t)!,
      statusWatch: Color.lerp(statusWatch, other.statusWatch, t)!,
      statusWatchText: Color.lerp(statusWatchText, other.statusWatchText, t)!,
      statusAlert: Color.lerp(statusAlert, other.statusAlert, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHeroSurface: Color.lerp(onHeroSurface, other.onHeroSurface, t)!,
      onHeroSurfaceMuted: Color.lerp(
        onHeroSurfaceMuted,
        other.onHeroSurfaceMuted,
        t,
      )!,
      onHeroAccent: Color.lerp(onHeroAccent, other.onHeroAccent, t)!,
      heroTrack: Color.lerp(heroTrack, other.heroTrack, t)!,
      heroEdge: Color.lerp(heroEdge, other.heroEdge, t)!,
    );
  }
}
