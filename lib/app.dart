import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/dev/token_gallery_screen.dart';

/// Root widget aplikasi.
///
/// Batch 1: tema light/dark aktif (mengikuti mode sistem); layar uji token
/// ditampilkan. Navigasi go_router dan Beranda asli masuk di Batch 4.
class CekGiziApp extends StatelessWidget {
  const CekGiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const TokenGalleryScreen(),
    );
  }
}
