import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/storage/local_prefs.dart';

/// Tema aplikasi. Sumber kebenaran ada di `LocalPrefs` (offline-safe);
/// perubahan langsung tercermin di `MaterialApp.themeMode`.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _fromValue(ref.watch(localPrefsProvider).themeMode);

  Future<void> set(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      await ref.read(localPrefsProvider).setThemeMode(_toValue(mode));
    } catch (_) {
      // Tidak ada penyimpanan: tema tetap aktif untuk sesi ini.
    }
  }

  static ThemeMode _fromValue(String value) => switch (value) {
    LocalPrefs.themeModeDark => ThemeMode.dark,
    LocalPrefs.themeModeSystem => ThemeMode.system,
    _ => ThemeMode.light,
  };

  static String _toValue(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => LocalPrefs.themeModeDark,
    ThemeMode.system => LocalPrefs.themeModeSystem,
    ThemeMode.light => LocalPrefs.themeModeLight,
  };
}
