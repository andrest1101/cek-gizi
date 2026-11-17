import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';

/// Mapping `chat_messages` (PRD §5.2). Nilai tak dikenal = data korup →
/// [InvalidReferenceDataException] (jangan ditelan diam-diam).
final class ChatMessageModel {
  const ChatMessageModel(this.message);

  final ChatMessage message;

  static ChatMessage fromMap(Map<String, dynamic> row) {
    final id = row['id'];
    final content = row['content'];
    final createdAtRaw = row['created_at'];

    if (id is! String || content is! String || createdAtRaw is! String) {
      throw const InvalidReferenceDataException(
        'chat_messages: kolom id/content/created_at tidak valid.',
      );
    }

    return ChatMessage(
      id: id,
      role: ChatMessage.roleFromDb(row['role'] as String?),
      content: content,
      safetyFlag: ChatMessage.safetyFlagFromDb(row['safety_flag'] as String?),
      createdAt: DateTime.parse(createdAtRaw).toLocal(),
    );
  }

  Map<String, dynamic> toMap({String? childId}) {
    return {
      'role': ChatMessage.roleToDb(message.role),
      'content': message.content,
      'safety_flag': ChatMessage.safetyFlagToDb(message.safetyFlag),
      // child_id boleh null (chat tidak bergantung pada anak terpilih).
      if (childId != null) 'child_id': childId,
    };
  }
}
