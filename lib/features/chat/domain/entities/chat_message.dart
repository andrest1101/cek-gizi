/// Bendera keamanan jawaban/pesan chat (PRD §3.8, kolom `safety_flag`
/// di tabel `chat_messages`).
enum ChatSafetyFlag {
  none,
  referDoctor,
  emergency,
}

/// Peran pengirim pesan (tabel `chat_messages`).
enum ChatRole {
  user,
  assistant,
}

/// Satu pesan di riwayat chat Tanya Gizi (PRD §6.7).
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.safetyFlag,
    required this.createdAt,
  });

  /// `''` untuk pesan yang belum tersimpan (optimistic UI).
  final String id;
  final ChatRole role;
  final String content;
  final ChatSafetyFlag safetyFlag;
  final DateTime createdAt;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    ChatSafetyFlag? safetyFlag,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      safetyFlag: safetyFlag ?? this.safetyFlag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Kode `safety_flag` di database (`'none' | 'refer_doctor' | 'emergency'`).
  static String safetyFlagToDb(ChatSafetyFlag flag) => switch (flag) {
        ChatSafetyFlag.none => 'none',
        ChatSafetyFlag.referDoctor => 'refer_doctor',
        ChatSafetyFlag.emergency => 'emergency',
      };

  /// Kode `safety_flag` dari database/API. Nilai tidak dikenal → data korup;
  /// lempar [FormatException] agar tidak ditelan diam-diam.
  static ChatSafetyFlag safetyFlagFromDb(String? raw) => switch (raw) {
        'none' => ChatSafetyFlag.none,
        'refer_doctor' => ChatSafetyFlag.referDoctor,
        'emergency' => ChatSafetyFlag.emergency,
        _ => throw FormatException('safety_flag tidak dikenal: $raw'),
      };

  static ChatRole roleFromDb(String? raw) => switch (raw) {
        'user' => ChatRole.user,
        'assistant' => ChatRole.assistant,
        _ => throw FormatException('role pesan tidak dikenal: $raw'),
      };

  static String roleToDb(ChatRole role) => switch (role) {
        ChatRole.user => 'user',
        ChatRole.assistant => 'assistant',
      };
}
