import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sumber waktu tunggal untuk logika "hari ini" (PRD §3.7: zona waktu
/// perangkat).
///
/// Semua keputusan yang bergantung pada tanggal (batas hari, reset target,
/// label "Hari ini"/"Kemarin") harus membaca waktu dari sini, bukan langsung
/// `DateTime.now()`, agar bisa diuji dengan jam palsu dan tetap konsisten
/// saat aplikasi terbuka melewati tengah malam.
typedef Clock = DateTime Function();

/// Default: jam perangkat. Test dapat meng-override dengan jam tetap.
final clockProvider = Provider<Clock>((ref) => DateTime.now);
