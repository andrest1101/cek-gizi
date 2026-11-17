import '../entities/assistant_reply.dart';
import '../entities/chat_message.dart';

/// Kontrak Tanya Gizi (PRD §6.7).
///
/// Jalur AI SELALU lewat Edge Function `ask-nutrition` - aplikasi tidak
/// pernah memegang kunci Gemini. Riwayat disimpan di tabel `chat_messages`
/// (RLS: hanya baris milik pengguna).
abstract interface class ChatRepository {
  /// Riwayat chat milik pengguna, terurut dari yang terlama.
  /// [limit] membatasi jumlah baris yang ditarik (default 100).
  Future<List<ChatMessage>> listMessages({int limit = 100});

  /// Kirim pertanyaan ke Edge Function. Konteks yang dikirim HANYA
  /// `age_months` + `sex` - tidak pernah nama, tanggal lahir, atau
  /// identitas anak (PRD §5.5, §8.1).
  Future<AskNutritionResult> ask({
    required List<ChatMessage> messages,
    required int ageMonths,
    required String sex,
  });

  /// Simpan satu pesan ke `chat_messages`.
  Future<ChatMessage> addMessage({
    required ChatRole role,
    required String content,
    required ChatSafetyFlag safetyFlag,
    String? childId,
  });

  /// Hapus SEMUA riwayat chat milik pengguna (PRD §6.7 & §8.3).
  Future<void> clearMessages();

  /// Sisa kuota chat hari ini (zona Asia/Jakarta) menurut `ai_usage`.
  /// `null` bila baris belum ada tidak mungkin terjadi di sini - yang
  /// dikembalikan adalah jumlah yang SUDAH dipakai; `null` berarti gagal
  /// dibaca (badge disembunyikan, kuota tetap ditegakkan server).
  Future<int?> chatUsageToday();
}
