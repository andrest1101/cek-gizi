import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_strings.dart';

/// Root widget aplikasi.
///
/// Pada Batch 0 aplikasi berisi satu layar penanda (shell). Navigasi
/// (`go_router`), tema desain (Batch 1), dan layar nyata (Batch 4+)
/// dihubungkan mengikuti Rencana Batch di PRD §10.
class CekGiziApp extends StatelessWidget {
  const CekGiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F54)),
      ),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConfig.appName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.disclaimer,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
