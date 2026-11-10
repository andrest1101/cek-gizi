import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cekgizi/features/auth/domain/use_cases/sign_in_anonymously_usecase.dart';

/// Inisialisasi backend saat startup aplikasi (dipanggil dari main).
///
/// Kegagalan jaringan TIDAK menghentikan aplikasi — sesi bisa dicoba lagi
/// dari layar terkait nanti; pesan ramah ke pengguna disampaikan di UI
/// (Batch 4+). Tidak ada data anak/log sensitif di sini.
Future<void> bootstrapBackend() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  try {
    final repository = AuthRepositoryImpl(Supabase.instance.client);
    await SignInAnonymously(repository)();
  } catch (error) {
    debugPrint('bootstrapBackend: anon sign-in gagal (${error.runtimeType}); lanjut tanpa sesi.');
  }
}
