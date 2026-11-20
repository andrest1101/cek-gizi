/// Hapus akun (PRD §6.8, §9.4). Layanan ini kebalikan dari data
/// *per user* milik akun — data anak, pengukuran, catatan makan, chat,
/// konsentri, ai_usage, akun (Kecuali child_photos: file lokal di perangkat,
/// dibersihkan di sisi presentation).
abstract interface class AccountRepository {
  Future<void> deleteAccount();
}
