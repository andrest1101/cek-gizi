import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_prefs.dart';
import 'features/auth/auth_bootstrap.dart';

/// Titik masuk aplikasi.
///
/// Urutan sengaja dibatasi waktu: preferensi lokal (lokal, cepat) lalu
/// bootstrap backend yang setiap langkahnya punya timeout sendiri (lihat
/// `startup_guard.dart`). Dengan begitu aplikasi selalu sampai ke frame
/// pertama - tidak pernah berhenti di logo saat jaringan lambat.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await LocalPrefs.load();
  // Bootstrap di latar: logo bermerek langsung tampil (dengan indikator
  // memuat) sementara SDK & sesi anonim disiapkan. Setiap langkah di dalamnya
  // punya batas waktu, jadi layar ini tidak pernah menjadi jebakan.
  final backendReady = bootstrapBackend();
  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
      ],
      child: CekGiziApp(backendReady: backendReady),
    ),
  );
}
