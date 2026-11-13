import 'package:flutter/material.dart';

/// Semua token warna (PRD §7.2) sebagai `ThemeExtension`.
///
/// Widget DILARANG memakai literal warna - ambil dari sini:
/// `Theme.of(context).extension<AppColors>()!.primary`.
///
/// `statusWatch` = warna isi status "perlu perhatian" (ikon/pita),
/// `statusWatchText` = warna teks status tersebut (kontras ≥ 4,5:1).
/// Di dark theme keduanya sama.
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
    required this.statusGood,
    required this.statusWatch,
    required this.statusWatchText,
    required this.statusAlert,
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

  /// Permukaan solid hero Piring Hari Ini (`#D8EBDD` / `#1B4A38`).
  final Color primaryContainer;

  /// Busur protein hewani, sorotan hangat (`#E9893B` / `#F2A55F`).
  final Color accent;

  /// Status normal (`#2E7D32` / `#7BD88F`).
  final Color statusGood;

  /// Status perlu perhatian - isi (`#F2B84B` / `#F2C14E`).
  final Color statusWatch;

  /// Status perlu perhatian - teks (`#8A5A12` / `#F2C14E`).
  final Color statusWatchText;

  /// Status perlu diperiksa segera (`#C0392B` / `#FF8E80`).
  final Color statusAlert;

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
    statusGood: Color(0xFF2E7D32),
    statusWatch: Color(0xFFF2B84B),
    statusWatchText: Color(0xFF8A5A12),
    statusAlert: Color(0xFFC0392B),
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
    statusGood: Color(0xFF7BD88F),
    statusWatch: Color(0xFFF2C14E),
    statusWatchText: Color(0xFFF2C14E),
    statusAlert: Color(0xFFFF8E80),
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
    Color? statusGood,
    Color? statusWatch,
    Color? statusWatchText,
    Color? statusAlert,
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
      statusGood: statusGood ?? this.statusGood,
      statusWatch: statusWatch ?? this.statusWatch,
      statusWatchText: statusWatchText ?? this.statusWatchText,
      statusAlert: statusAlert ?? this.statusAlert,
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
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      statusGood: Color.lerp(statusGood, other.statusGood, t)!,
      statusWatch: Color.lerp(statusWatch, other.statusWatch, t)!,
      statusWatchText: Color.lerp(statusWatchText, other.statusWatchText, t)!,
      statusAlert: Color.lerp(statusAlert, other.statusAlert, t)!,
    );
  }
}
