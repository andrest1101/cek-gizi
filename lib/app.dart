import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_providers.dart';

/// Root widget aplikasi. Navigasi go_router; tema light/dark (PRD §7).
/// Gate: onboarding & consent wajib lebih dulu (PRD §6.1).
///
/// Satu-satunya layar pra-aplikasi adalah `/opening` (satu page Lottie ±3 dtk).
/// Backend disiapkan di latar oleh `main()` tanpa menghalangi navigasi.
class CekGiziApp extends ConsumerWidget {
  const CekGiziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
