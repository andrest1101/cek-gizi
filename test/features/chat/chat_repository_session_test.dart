import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cekgizi/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ask memastikan sesi anonim sebelum memanggil Edge Function', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-publishable-key',
    );
    var calls = 0;
    final repository = ChatRepositoryImpl(
      client,
      ensureSession: () async {
        calls++;
        // Hentikan sebelum invoke agar tes tidak menyentuh jaringan.
        throw StateError('stop-before-network');
      },
    );

    await expectLater(
      repository.ask(
        messages: [
          ChatMessage(
            id: '',
            role: ChatRole.user,
            content: 'Ide MPASI untuk bayi 1 tahun?',
            safetyFlag: ChatSafetyFlag.none,
            createdAt: DateTime.now(),
          ),
        ],
        ageMonths: 12,
        sex: 'male',
      ),
      throwsA(isA<ChatException>()),
    );

    expect(calls, 1);
  });
}
