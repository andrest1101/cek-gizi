import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Future yang selesai ketika backend (Supabase init + sesi anonim) siap.
///
/// Di produksi di-override di `main()` dengan `bootstrapBackend()` yang
/// berjalan di latar. Default: future langsung selesai (dipakai tes) sehingga
/// layar pembuka tidak pernah menunggu tanpa batas.
final backendReadyProvider = Provider<Future<void>>((ref) => Future.value());
