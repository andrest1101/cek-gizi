import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/chat/data/services/chat_error_mapper.dart';

void main() {
  group('ChatErrorMapper', () {
    test('404 fungsi belum di-deploy tidak jadi ai_unavailable', () {
      expect(
        ChatErrorMapper.map(
          status: 404,
          details: {'message': 'Function not found'},
        ),
        ChatErrorMapper.functionUnavailable,
      );
    });

    test('kode dari body server diprioritaskan', () {
      expect(
        ChatErrorMapper.map(status: 502, details: {'error': 'ai_unavailable'}),
        ChatErrorMapper.aiUnavailable,
      );
      expect(
        ChatErrorMapper.map(status: 429, details: '{"error":"quota_daily"}'),
        ChatErrorMapper.quotaDaily,
      );
      expect(
        ChatErrorMapper.map(status: 500, details: {'error': 'misconfigured'}),
        ChatErrorMapper.misconfigured,
      );
    });

    test('status tanpa kode dipetakan sesuai PRD', () {
      expect(ChatErrorMapper.map(status: 400), ChatErrorMapper.invalidInput);
      expect(ChatErrorMapper.map(status: 401), ChatErrorMapper.unauthorized);
      expect(ChatErrorMapper.map(status: 429), ChatErrorMapper.quotaDaily);
      expect(ChatErrorMapper.map(status: 504), ChatErrorMapper.timeout);
      expect(ChatErrorMapper.map(status: 502), ChatErrorMapper.aiUnavailable);
      expect(
        ChatErrorMapper.map(status: null, details: null),
        ChatErrorMapper.aiUnavailable,
      );
    });

    test('kode server yang belum diterjemahkan dilewatkan apa adanya', () {
      expect(
        ChatErrorMapper.map(
          status: 502,
          details: {'error': 'gemini_schema_reject'},
        ),
        'gemini_schema_reject',
      );
    });
  });
}
