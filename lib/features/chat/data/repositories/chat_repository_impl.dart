import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/chat/data/models/chat_message_model.dart';
import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/domain/repositories/chat_repository.dart';

/// Implementasi Tanya Gizi (PRD §5.5).
///
/// Kunci Gemini TIDAK pernah ada di sini - hanya lewat Edge Function.
/// Riwayat disimpan di `chat_messages` (RLS: hanya baris milik pengguna);
/// `safety_flag` dari server disimpan apa adanya untuk kartu khusus.
final class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, role, content, safety_flag, created_at';

  @override
  Future<List<ChatMessage>> listMessages({int limit = 100}) async {
    final rows = await _client
        .from('chat_messages')
        .select(_columns)
        .order('created_at')
        .limit(limit);
    return [
      for (final row in rows as List)
        ChatMessageModel.fromMap(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<AskNutritionResult> ask({
    required List<ChatMessage> messages,
    required int ageMonths,
    required String sex,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ask-nutrition',
        body: {
          'messages': [
            for (final message in messages)
              {
                'role': ChatMessage.roleToDb(message.role),
                'content': message.content,
              },
          ],
          // Konteks yang dikirim HANYA usia + jenis kelamin (PRD §8.1).
          'context': {'age_months': ageMonths, 'sex': sex},
        },
      );
      final data = response.data;
      if (data is Map) {
        try {
          return AskNutritionResult.fromJson(Map<String, dynamic>.from(data));
        } on FormatException {
          throw const ChatException('ai_unavailable');
        }
      }
      throw const ChatException('ai_unavailable');
    } on ChatException {
      rethrow;
    } on FunctionException catch (exception) {
      throw ChatException(_codeOf(exception));
    } catch (_) {
      throw const ChatException('offline');
    }
  }

  @override
  Future<ChatMessage> addMessage({
    required ChatRole role,
    required String content,
    required ChatSafetyFlag safetyFlag,
    String? childId,
  }) async {
    final row = await _client
        .from('chat_messages')
        .insert(
          ChatMessageModel(
            ChatMessage(
              id: '',
              role: role,
              content: content,
              safetyFlag: safetyFlag,
              createdAt: DateTime.now(),
            ),
          ).toMap(childId: childId),
        )
        .select(_columns)
        .single();
    return ChatMessageModel.fromMap(row);
  }

  @override
  Future<void> clearMessages() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const ChatException('unauthorized');
    }
    // RLS tetap menyaring; filter eksplisit diperlukan PostgREST.
    await _client.from('chat_messages').delete().eq('user_id', uid);
  }

  @override
  Future<int?> chatUsageToday() async {
    try {
      // Kuota server dihitung dari hari Asia/Jakarta (PRD §5.4).
      final jakartaNow = DateTime.now().toUtc().add(const Duration(hours: 7));
      final day =
          '${jakartaNow.year.toString().padLeft(4, '0')}-${jakartaNow.month.toString().padLeft(2, '0')}-${jakartaNow.day.toString().padLeft(2, '0')}';
      final row = await _client
          .from('ai_usage')
          .select('chat_count')
          .eq('day', day)
          .maybeSingle();
      final count = row?['chat_count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return 0;
    } catch (_) {
      // Badge kuota bersifat opsional; kuota tetap ditegakkan server.
      return null;
    }
  }

  static String _codeOf(FunctionException exception) {
    final details = exception.details;
    if (details is Map) {
      final code = details['error'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
      return 'ai_unavailable';
    }
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map && decoded['error'] is String) {
          return (decoded['error'] as String).trim();
        }
      } catch (_) {
        // bukan JSON - jatuh ke default di bawah
      }
    }
    return switch (exception.status) {
      429 => 'quota_daily',
      400 => 'invalid_input',
      401 => 'unauthorized',
      504 => 'timeout',
      _ => 'ai_unavailable',
    };
  }
}
