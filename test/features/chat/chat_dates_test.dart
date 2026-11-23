import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/time/chat_dates.dart';

void main() {
  final now = DateTime(2026, 11, 22, 14, 30);

  group('chatDayKind', () {
    test('hari yang sama', () {
      expect(
        chatDayKind(DateTime(2026, 11, 22, 0, 5), now: now),
        ChatDayKind.today,
      );
    });

    test('kemarin', () {
      expect(
        chatDayKind(DateTime(2026, 11, 21, 23, 55), now: now),
        ChatDayKind.yesterday,
      );
    });

    test('lebih lama menjadi tanggal', () {
      expect(
        chatDayKind(DateTime(2026, 11, 16, 19, 0), now: now),
        ChatDayKind.date,
      );
    });

    test('melewati batas bulan tetap dihitung kalender', () {
      expect(
        chatDayKind(
          DateTime(2026, 10, 31, 22, 0),
          now: DateTime(2026, 11, 1, 6, 0),
        ),
        ChatDayKind.yesterday,
      );
    });
  });

  test('isSameChatDay hanya hari kalender lokal', () {
    expect(
      isSameChatDay(
        DateTime(2026, 11, 22, 0, 1),
        DateTime(2026, 11, 22, 23, 59),
      ),
      isTrue,
    );
    expect(
      isSameChatDay(
        DateTime(2026, 11, 22, 23, 59),
        DateTime(2026, 11, 23, 0, 1),
      ),
      isFalse,
    );
  });

  test('formatChatDate memakai bulan Indonesia', () {
    expect(formatChatDate(DateTime(2026, 11, 16)), '16 Nov 2026');
    expect(formatChatDate(DateTime(2026, 5, 1)), '1 Mei 2026');
  });

  test('formatChatTime dua digit dengan titik', () {
    expect(formatChatTime(DateTime(2026, 11, 22, 8, 5)), '08.05');
    expect(formatChatTime(DateTime(2026, 11, 22, 14, 30)), '14.30');
    expect(formatChatTime(DateTime(2026, 11, 22, 0, 0)), '00.00');
  });
}
