import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/backend_ready_provider.dart';
import 'core/storage/local_prefs.dart';
import 'features/auth/auth_bootstrap.dart';

/// Titik masuk aplikasi.
///
/// Urutan startup dibatasi waktu: preferensi lokal (lokal, cepat) lalu
/// bootstrap backend berjalan di latar (setiap langkahnya punya batas waktu,
/// lihat `startup_guard.dart`). Layar pembuka (satu page Lottie) menunggu
/// backend selesai bersama animasi - tidak pernah berhenti di splash.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await LocalPrefs.load();
  final backendReady = bootstrapBackend();
  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        backendReadyProvider.overrideWithValue(backendReady),
      ],
      child: const CekGiziApp(),
    ),
  );
}
