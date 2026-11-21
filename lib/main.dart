import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_prefs.dart';
import 'features/auth/auth_bootstrap.dart';

/// Titik masuk aplikasi.
///
/// Preferensi lokal dimuat dulu (cepat, lokal), lalu bootstrap backend
/// dijalankan di latar tanpa menghalangi frame pertama. Layar pembuka
/// (`/opening`) hanya menampilkan Lottie ±3 detik dan langsung lanjut; backend
/// yang lebih lama tetap berjalan dan tiap layar punya state loading/retry.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await LocalPrefs.load();
  unawaited(bootstrapBackend());
  runApp(
    ProviderScope(
      overrides: [localPrefsProvider.overrideWithValue(prefs)],
      child: const CekGiziApp(),
    ),
  );
}
