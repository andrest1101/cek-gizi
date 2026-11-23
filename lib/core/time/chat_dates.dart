/// Helper tanggal & waktu untuk percakapan Tanya Gizi.
///
/// Murni Dart (tanpa Flutter) agar mudah diuji dan dipakai lapisan
/// presentasi. Label hari sengaja dikembalikan sebagai [ChatDayKind], bukan
/// teks, supaya copy tetap terpusat di `AppStrings`.
library;

import 'package:cekgizi/core/time/local_dates.dart';

/// Jenis label pada pembatas hari percakapan.
enum ChatDayKind { today, yesterday, date }

const List<String> _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Hari kalender [at] relatif terhadap [now] (zona waktu perangkat).
ChatDayKind chatDayKind(DateTime at, {required DateTime now}) {
  final difference = localDayDifference(at, now);
  if (difference == 0) return ChatDayKind.today;
  if (difference == 1) return ChatDayKind.yesterday;
  return ChatDayKind.date;
}

/// Apakah dua waktu jatuh pada hari kalender lokal yang sama.
bool isSameChatDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Tanggal pendek Indonesia, mis. `16 Nov 2026`.
String formatChatDate(DateTime at) =>
    '${at.day} ${_monthShort[at.month - 1]} ${at.year}';

/// Jam lokal format Indonesia, mis. `14.05`.
String formatChatTime(DateTime at) {
  final hour = at.hour.toString().padLeft(2, '0');
  final minute = at.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}
