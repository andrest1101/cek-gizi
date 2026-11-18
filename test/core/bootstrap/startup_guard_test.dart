import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/bootstrap/startup_guard.dart';

/// Regresi "macet di logo": langkah startup yang menggantung harus menyerah
/// setelah batas waktu, bukan menahan `main()` selamanya.
void main() {
  test('mengembalikan hasil bila tugas selesai tepat waktu', () async {
    final result = await runStartupTask(
      () async => 'siap',
      timeout: const Duration(milliseconds: 100),
      label: 'uji cepat',
    );
    expect(result, 'siap');
  });

  test('menyerah saat melewati batas waktu (tidak melempar)', () async {
    final result = await runStartupTask<String>(
      () => Completer<String>().future,
      timeout: const Duration(milliseconds: 20),
      label: 'uji menggantung',
    );
    expect(result, isNull);
  });

  test('menelan galat dan mengembalikan null', () async {
    final result = await runStartupTask<String>(
      () async => throw StateError('server mati'),
      timeout: const Duration(milliseconds: 100),
      label: 'uji galat',
    );
    expect(result, isNull);
  });
}
