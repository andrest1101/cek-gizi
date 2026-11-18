import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_strings.dart';
import 'core/router.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';

/// Root widget aplikasi. Navigasi go_router; tema light/dark (PRD §7).
/// Gate: onboarding & consent wajib lebih dulu (PRD §6.1).
class CekGiziApp extends ConsumerWidget {
  const CekGiziApp({super.key, this.backendReady});

  /// Saat dijalankan dari `main()`, bootstrap backend berjalan di latar dan
  /// widget ini menampilkan layar bermerek sampai selesai. Dengan begitu
  /// pengguna tidak pernah menatap splash native yang "diam" saat jaringan
  /// lambat. Tes tidak mengirim future ini (semua repository di-override).
  final Future<void>? backendReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final app = MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );

    final ready = backendReady;
    if (ready == null) return app;

    return FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupScreen();
        }
        return app;
      },
    );
  }
}

/// Layar bermerek singkat sebelum frame aplikasi pertama. Tidak memuat
/// navigasi dan tidak memanggil jaringan - hanya menunggu [CekGiziApp.backendReady].
class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    // Layar ini tampil sebelum `MaterialApp.router` dipasang, jadi theme
    // belum tersedia dari context - ambang brightness sistem dipakai dulu.
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        child: const _StartupContent(),
      ),
    );
  }
}

class _StartupContent extends StatelessWidget {
  const _StartupContent();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Material(
      color: colors.background,
      child: Center(
        child: Semantics(
          label: '${AppConfig.appName} — ${AppStrings.startupLoading}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/logo_splash_screen.png',
                width: 132,
                height: 132,
                cacheWidth: 264,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xxl),
              CircularProgressIndicator(color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
