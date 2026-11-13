/// Kontrak autentikasi (PRD §4/§6.1): anonim dulu, penautan akun menyusul
/// (Batch 9). Implementasi ada di data layer (AuthRepositoryImpl).
abstract interface class AuthRepository {
  /// Masuk anonim bila belum ada sesi. Sesi dipersisten oleh SDK.
  /// Tidak melempar galat jaringan mentah - kegagalan ditangani pemanggil.
  Future<void> signInAnonymously();

  /// Id pengguna aktif, atau null bila belum masuk.
  String? get currentUserId;

  /// true bila ada sesi (anonim atau tertaut).
  bool get isSignedIn;
}
