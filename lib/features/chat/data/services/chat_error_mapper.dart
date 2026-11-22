import 'dart:convert';

/// Pemetaan galat Edge Function `ask-nutrition` menjadi kode UI.
///
/// Fungsi ini murni Dart agar bisa diuji tanpa Supabase/Flutter. Kode yang
/// tidak dikenal dilewatkan apa adanya (log server tetap bisa dibaca), dan UI
/// memilih copy default bila belum punya terjemahan khusus.
abstract final class ChatErrorMapper {
  static const functionUnavailable = 'function_unavailable';
  static const misconfigured = 'misconfigured';
  static const aiUnavailable = 'ai_unavailable';
  static const invalidInput = 'invalid_input';
  static const unauthorized = 'unauthorized';
  static const quotaDaily = 'quota_daily';
  static const timeout = 'timeout';
  static const offline = 'offline';

  static String map({required int? status, Object? details}) {
    final code = _codeFromDetails(details);
    if (code != null) return code;

    // Supabase mengembalikan 404 + {"message":"Function not found"} untuk
    // fungsi yang belum di-deploy. Respons itu TIDAK punya field `error`,
    // jadi dipetakan dari status agar tidak jadi "ai_unavailable".
    return switch (status) {
      400 => invalidInput,
      401 => unauthorized,
      404 => functionUnavailable,
      429 => quotaDaily,
      500 => misconfigured,
      504 => timeout,
      _ => aiUnavailable,
    };
  }

  static String? _codeFromDetails(Object? details) {
    if (details is Map) {
      return _stringCode(details['error']);
    }
    if (details is String && details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) return _stringCode(decoded['error']);
      } catch (_) {
        // Body bukan JSON - dipetakan dari status.
      }
    }
    return null;
  }

  static String? _stringCode(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
