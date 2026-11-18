import 'dart:async';

import 'package:flutter/foundation.dart';

/// Menjalankan satu langkah startup dengan batas waktu.
///
/// Startup TIDAK BOLEH menggantung: bila jaringan lambat/putus, aplikasi tetap
/// harus sampai ke frame pertama dan menampilkan pesan ramah (bukan berhenti
/// di splash). Karena itu setiap langkah yang bisa menunggu I/O dibungkus
/// helper ini - timeout atau galat apa pun dicatat sebagai tipe saja (tanpa
/// data sensitif) lalu dianggap selesai.
///
/// Mengembalikan nilai [task] bila selesai tepat waktu, atau `null` bila
/// timeout/galat. Pemanggil harus siap menerima `null`.
Future<T?> runStartupTask<T>(
  Future<T> Function() task, {
  required Duration timeout,
  required String label,
}) async {
  try {
    return await task().timeout(timeout);
  } on TimeoutException {
    debugPrint('startup: $label melewati ${timeout.inSeconds}s; dilanjutkan.');
    return null;
  } catch (error) {
    debugPrint('startup: $label gagal (${error.runtimeType}); dilanjutkan.');
    return null;
  }
}
