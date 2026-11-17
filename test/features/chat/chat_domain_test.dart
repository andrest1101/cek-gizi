import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/domain/repositories/chat_repository.dart';
import 'package:cekgizi/features/chat/domain/usecases/chat_use_cases.dart';

ChatMessage _msg(String content, {ChatRole role = ChatRole.user}) =>
    ChatMessage(
      id: '',
      role: role,
      content: content,
      safetyFlag: ChatSafetyFlag.none,
      createdAt: DateTime(2026, 11, 17, 10, 0),
    );

AskNutritionResult _sampleReply() => const AskNutritionResult(
      requestId: 'req-1',
      answer: 'Jawaban contoh',
      safetyFlag: ChatSafetyFlag.none,
      followups: ['Satu'],
    );

final class _RecordingChatRepository implements ChatRepository {
  int askCalls = 0;
  List<ChatMessage>? lastMessages;
  int? lastAgeMonths;
  String? lastSex;

  @override
  Future<AskNutritionResult> ask({
    required List<ChatMessage> messages,
    required int ageMonths,
    required String sex,
  }) async {
    askCalls++;
    lastMessages = List<ChatMessage>.of(messages);
    lastAgeMonths = ageMonths;
    lastSex = sex;
    return _sampleReply();
  }

  @override
  Future<List<ChatMessage>> listMessages({int limit = 100}) async =>
      const [];

  @override
  Future<ChatMessage> addMessage({
    required ChatRole role,
    required String content,
    required ChatSafetyFlag safetyFlag,
    String? childId,
  }) async =>
      _msg(content, role: role);

  @override
  Future<void> clearMessages() async {}

  @override
  Future<int?> chatUsageToday() async => 0;
}

void main() {
  group('ChatSafetyFlag (safety_flag di DB)', () {
    test('mapping db -> enum', () {
      expect(ChatMessage.safetyFlagFromDb('none'), ChatSafetyFlag.none);
      expect(
        ChatMessage.safetyFlagFromDb('refer_doctor'),
        ChatSafetyFlag.referDoctor,
      );
      expect(
        ChatMessage.safetyFlagFromDb('emergency'),
        ChatSafetyFlag.emergency,
      );
    });

    test('nilai tidak dikenal dilempar (data korup, bukan default diam)', () {
      expect(
        () => ChatMessage.safetyFlagFromDb('viral'),
        throwsFormatException,
      );
      expect(
        () => ChatMessage.safetyFlagFromDb(null),
        throwsFormatException,
      );
    });

    test('enum -> db roundtrip', () {
      expect(ChatMessage.safetyFlagToDb(ChatSafetyFlag.none), 'none');
      expect(
        ChatMessage.safetyFlagToDb(ChatSafetyFlag.referDoctor),
        'refer_doctor',
      );
      expect(
        ChatMessage.safetyFlagToDb(ChatSafetyFlag.emergency),
        'emergency',
      );
    });
  });

  group('AskNutritionResult.fromJson', () {
    test('menerima payload valid dan memangkas followups ke 2', () {
      final result = AskNutritionResult.fromJson({
        'request_id': '  req-9  ',
        'answer': '  Berikan makanan beragam setiap hari.  ',
        'safety_flag': 'none',
        'followups': ['  a  ', 'b', 'c', ''],
      });
      expect(result.requestId, 'req-9');
      expect(result.answer, 'Berikan makanan beragam setiap hari.');
      expect(result.safetyFlag, ChatSafetyFlag.none);
      expect(result.followups, ['a', 'b']);
    });

    test('followups boleh tidak ada', () {
      final result = AskNutritionResult.fromJson({
        'request_id': 'req-1',
        'answer': 'Jawaban.',
        'safety_flag': 'refer_doctor',
      });
      expect(result.followups, isEmpty);
    });

    test('request_id hilang ditolak', () {
      expect(
        () => AskNutritionResult.fromJson({
          'answer': 'Jawaban.',
          'safety_flag': 'none',
        }),
        throwsFormatException,
      );
    });

    test('answer kosong ditolak', () {
      expect(
        () => AskNutritionResult.fromJson({
          'request_id': 'req-1',
          'answer': '   ',
          'safety_flag': 'none',
        }),
        throwsFormatException,
      );
    });

    test('answer lebih dari 1500 karakter ditolak', () {
      expect(
        () => AskNutritionResult.fromJson({
          'request_id': 'req-1',
          'answer': 'a' * 1501,
          'safety_flag': 'none',
        }),
        throwsFormatException,
      );
    });

    test('safety_flag tidak dikenal ditolak', () {
      expect(
        () => AskNutritionResult.fromJson({
          'request_id': 'req-1',
          'answer': 'Jawaban.',
          'safety_flag': 'viral',
        }),
        throwsFormatException,
      );
    });
  });

  group('ChatUseCases.askQuestion', () {
    test('menolak pesan kosong', () {
      final repo = _RecordingChatRepository();
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: const [],
          ageMonths: 11,
          sex: 'female',
        ),
        throwsArgumentError,
      );
    });

    test('menolak usia di luar 0-60 bulan', () {
      final repo = _RecordingChatRepository();
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: [_msg('Halo')],
          ageMonths: 61,
          sex: 'female',
        ),
        throwsArgumentError,
      );
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: [_msg('Halo')],
          ageMonths: -1,
          sex: 'female',
        ),
        throwsArgumentError,
      );
    });

    test('menolak sex yang tidak dikenal', () {
      final repo = _RecordingChatRepository();
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: [_msg('Halo')],
          ageMonths: 11,
          sex: 'x',
        ),
        throwsArgumentError,
      );
    });

    test('menolak pesan terakhir bukan dari user', () {
      final repo = _RecordingChatRepository();
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: [_msg('Jawaban', role: ChatRole.assistant)],
          ageMonths: 11,
          sex: 'male',
        ),
        throwsArgumentError,
      );
    });

    test('menolak isi pesan lebih dari 4000 karakter', () {
      final repo = _RecordingChatRepository();
      expect(
        () => ChatUseCases.askQuestion(
          repo,
          messages: [_msg('a' * 4001)],
          ageMonths: 11,
          sex: 'male',
        ),
        throwsArgumentError,
      );
    });

    test('konteks yang dikirim hanya usia + jenis kelamin', () async {
      final repo = _RecordingChatRepository();
      await ChatUseCases.askQuestion(
        repo,
        messages: [_msg('Apa ide MPASI hari ini?')],
        ageMonths: 9,
        sex: 'female',
      );
      expect(repo.askCalls, 1);
      expect(repo.lastAgeMonths, 9);
      expect(repo.lastSex, 'female');
    });

    test('riwayat dipotong ke 10 pesan terakhir, urutan kronologis', () async {
      final repo = _RecordingChatRepository();
      final messages = [
        for (var index = 0; index < 11; index++)
          _msg('Pesan $index',
              role: index.isEven ? ChatRole.user : ChatRole.assistant),
        _msg('Pertanyaan akhir'),
      ];
      await ChatUseCases.askQuestion(
        repo,
        messages: messages,
        ageMonths: 12,
        sex: 'male',
      );
      expect(repo.lastMessages, hasLength(10));
      expect(repo.lastMessages!.first.content, 'Pesan 2');
      expect(repo.lastMessages!.last.content, 'Pertanyaan akhir');
    });
  });
}
