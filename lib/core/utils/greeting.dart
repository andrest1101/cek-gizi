import 'package:cekgizi/core/constants/app_strings.dart';

/// Sapaan hangat menurut jam perangkat (PRD §7.6).
///
/// Batas jam:
/// - 00.00–10.59 → "Selamat pagi"
/// - 11.00–14.59 → "Selamat siang"
/// - 15.00–17.59 → "Selamat sore"
/// - 18.00–23.59 → "Selamat malam"
abstract final class Greeting {
  const Greeting._();

  static String of(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return AppStrings.greetingMorning;
    if (hour < 15) return AppStrings.greetingNoon;
    if (hour < 18) return AppStrings.greetingEvening;
    return AppStrings.greetingNight;
  }
}
