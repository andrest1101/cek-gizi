import '../entities/assistant_reply.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Aturan domain Tanya Gizi (PRD §5.5, §6.7).
///
/// Validasi di sini bersifat defensif untuk sisi klien; penegakan yang
/// sesungguhnya (kuota, red flag, batas panjang) ada di Edge Function.
abstract final class ChatUseCases {
  const ChatUseCases._();

  static const int maxMessagesPerRequest = 10;
  static const int maxContentLength = 4000;

  /// Kirim pertanyaan. Konteks yang boleh dikirim HANYA usia (bulan) dan
  /// jenis kelamin - tidak pernah nama atau tanggal lahir (PRD §8.1).
  static Future<AskNutritionResult> askQuestion(
    ChatRepository repository, {
    required List<ChatMessage> messages,
    required int ageMonths,
    required String sex,
  }) {
    if (ageMonths < 0 || ageMonths > 60) {
      throw ArgumentError.value(ageMonths, 'ageMonths', 'Usia 0–60 bulan.');
    }
    if (sex != 'male' && sex != 'female') {
      throw ArgumentError.value(sex, 'sex', 'male atau female.');
    }
    if (messages.isEmpty) {
      throw ArgumentError('Pertanyaan tidak boleh kosong.');
    }
    final last = messages.last;
    if (last.role != ChatRole.user) {
      throw ArgumentError('Pesan terakhir harus dari user.');
    }
    for (final message in messages) {
      final length = message.content.trim().length;
      if (length == 0 || length > maxContentLength) {
        throw ArgumentError('Isi pesan kosong atau terlalu panjang.');
      }
    }
    // Server menerima maksimal 10 pesan terakhir; klien memotong lebih awal
    // agar jawaban tidak melenceng dari konteks yang dimaksud.
    final window = messages.length > maxMessagesPerRequest
        ? messages.sublist(messages.length - maxMessagesPerRequest)
        : messages;
    return repository.ask(
      messages: window,
      ageMonths: ageMonths,
      sex: sex,
    );
  }

  static Future<List<ChatMessage>> listMessages(
    ChatRepository repository, {
    int limit = 100,
  }) =>
      repository.listMessages(limit: limit);

  static Future<void> clearMessages(ChatRepository repository) =>
      repository.clearMessages();

  /// Jumlah pertanyaan hari ini menurut `ai_usage` (Asia/Jakarta).
  /// `null` = tidak bisa dibaca (badge disembunyikan).
  static Future<int?> usageToday(ChatRepository repository) =>
      repository.chatUsageToday();
}
