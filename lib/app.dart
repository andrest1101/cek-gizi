import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

/// Root widget aplikasi. Navigasi go_router; tema light/dark (PRD §7).
/// Gate: onboarding & consent wajib lebih dulu (PRD §6.1).
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
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
