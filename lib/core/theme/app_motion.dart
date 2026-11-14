import 'package:flutter/material.dart';

/// Durasi & kurva motion (PRD §7.4): 200-250ms easeOutCubic;
/// cincin Piring Hari Ini menyala bertahap 400ms. Hormati
/// `MediaQuery.disableAnimations` di call site (lihat [of]).
abstract final class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration ring = Duration(milliseconds: 400);

  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Hormati pengaturan aksesibilitas "kurangi animasi": kembalikan
  /// [baseline] apa adanya, atau `Duration.zero` bila pengguna meminta.
  static Duration of(BuildContext context, Duration baseline) =>
      MediaQuery.of(context).disableAnimations ? Duration.zero : baseline;
}
