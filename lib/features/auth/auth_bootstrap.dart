import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/core/bootstrap/startup_guard.dart';
import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cekgizi/features/auth/domain/use_cases/sign_in_anonymously_usecase.dart';

/// Batas waktu inisialisasi SDK (lokal, normalnya < 1 detik).
const Duration _initTimeout = Duration(seconds: 8);

/// Batas waktu pendaftaran sesi anonim ke server.
///
/// Ini satu-satunya langkah startup yang butuh jaringan. Tanpa batas waktu,
/// perangkat offline membuat aplikasi "menggantung" di splash sebelum Flutter
/// sempat menggambar frame pertama.
const Duration _sessionTimeout = Duration(seconds: 5);

/// Inisialisasi backend saat startup aplikasi (dipanggil dari main).
///
/// Kegagalan jaringan TIDAK menghentikan aplikasi: sesi dicoba lagi saat
/// layar terkait memuat data (setiap galat punya aksi "Coba lagi"), dan
/// fitur offline (tumbuh, z-score, resep, aturan gizi) tetap berjalan.
/// Tidak ada data anak/log sensitif di sini.
Future<void> bootstrapBackend() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabase = await runStartupTask(
    () => Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    ),
    timeout: _initTimeout,
    label: 'init Supabase',
  );

  // Tanpa SDK yang siap, `Supabase.instance` belum ada. Aplikasi tetap
  // dijalankan agar pengguna melihat pesan ramah + tombol coba lagi, bukan
  // splash yang membeku.
  if (supabase == null) return;

  await ensureAnonymousSession();
}

/// Pastikan ada sesi (anonim) untuk RLS. Tidak pernah melempar galat.
///
/// Boleh dipanggil ulang (mis. saat aplikasi kembali ke depan) - SDK
/// mengembalikan sesi yang sudah ada tanpa permintaan jaringan baru.
Future<bool> ensureAnonymousSession({
  Duration timeout = _sessionTimeout,
}) async {
  final done = await runStartupTask(
    () async {
      final repository = AuthRepositoryImpl(Supabase.instance.client);
      await SignInAnonymously(repository)();
      return true;
    },
    timeout: timeout,
    label: 'sesi anonim',
  );
  return done ?? false;
}
