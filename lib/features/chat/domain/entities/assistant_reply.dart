import 'chat_message.dart';

/// Jawaban `ask-nutrition` untuk satu pertanyaan (PRD §5.5).
final class AskNutritionResult {
  const AskNutritionResult({
    required this.requestId,
    required this.answer,
    required this.safetyFlag,
    required this.followups,
  });

  final String requestId;
  final String answer;
  final ChatSafetyFlag safetyFlag;

  /// Sarana tanya lanjutan (maksimal 2; sudah divalidasi server & klien).
  final List<String> followups;

  factory AskNutritionResult.fromJson(Map<String, dynamic> json) {
    final requestId = json['request_id'];
    final answer = json['answer'];
    final rawFollowups = json['followups'];

    if (requestId is! String || requestId.trim().isEmpty) {
      throw const FormatException('request_id wajib ada.');
    }
    if (answer is! String || answer.trim().isEmpty) {
      throw const FormatException('answer wajib ada.');
    }
    if (answer.trim().length > 1500) {
      throw const FormatException('answer terlalu panjang.');
    }

    final followups = <String>[];
    if (rawFollowups is List) {
      for (final item in rawFollowups) {
        if (item is String && item.trim().isNotEmpty) {
          final trimmed = item.trim();
          followups.add(
            trimmed.length > 140 ? trimmed.substring(0, 140) : trimmed,
          );
        }
      }
    }
    if (followups.length > 2) {
      followups.removeRange(2, followups.length);
    }

    return AskNutritionResult(
      requestId: requestId.trim(),
      answer: answer.trim(),
      safetyFlag: ChatMessage.safetyFlagFromDb(
        json['safety_flag'] is String ? json['safety_flag'] as String : null,
      ),
      followups: List.unmodifiable(followups),
    );
  }
}

/// Kegagalan panggilan Tanya Gizi yang sudah diterjemahkan (tanpa pesan
/// mentah). [code] memakai kode PRD §5.5: `quota_daily`, `ai_unavailable`,
/// `timeout`, `invalid_input`, `unauthorized`, `offline`.
final class ChatException implements Exception {
  const ChatException(this.code);

  final String code;

  @override
  String toString() => 'ChatException($code)';
}
