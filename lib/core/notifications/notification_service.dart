import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/notifications/reminder_schedule.dart';

/// Penerima jadwal pengingat (PRD §6.8, §12). Implementasi produksi memakai
/// `flutter_local_notifications`; tes memakai fake.
abstract class ReminderScheduler {
  /// Terapkan [settings]: batalkan dulu yang dimatikan, jadwalkan yang aktif.
  Future<void> apply(ReminderSettings settings);

  /// Minta izin menampilkan notifikasi (Android 13+ / iOS). Mengembalikan
  /// `true` bila diizinkan atau tidak ada yang perlu ditanya.
  Future<bool> requestPermission();
}

/// Implementasi produksi: notifikasi lokal (tanpa server / tanpa push).
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler();

  static const int monthlyId = 7101;
  static const int dailyId = 7102;
  static const String channelId = 'cek_gizi_reminders';
  static const String channelName = 'Pengingat CekGizi';
  static const String channelDescription =
      'Pengingat ukur anak bulanan dan catat makan harian.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Zona waktu lokal: pilih lokasi dengan offset sama seperti perangkat
    // (Indonesia tidak mengenal DST); fallback ke UTC bila tak ketemu.
    tz_data.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    tz.setLocalLocation(
      tz.timeZoneDatabase.locations.values.firstWhere(
        (location) => location.currentTimeZone.offset == offset.inMilliseconds,
        orElse: () => tz.UTC,
      ),
    );
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? true;
    }
    return true;
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> apply(ReminderSettings settings) async {
    await _ensureInitialized();
    await _plugin.cancel(id: monthlyId);
    await _plugin.cancel(id: dailyId);

    final now = DateTime.now();
    if (settings.monthlyEnabled) {
      final next = nextMonthlyOccurrence(now, settings.monthlyDay);
      await _plugin.zonedSchedule(
        id: monthlyId,
        title: AppStrings.settingsReminderMonthlyTitle,
        body: AppStrings.settingsReminderMonthlyBody(settings.monthlyDay),
        scheduledDate: tz.TZDateTime.from(next, tz.local),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
    if (settings.dailyEnabled) {
      final next = nextDailyOccurrence(
        now,
        settings.dailyHour,
        settings.dailyMinute,
      );
      await _plugin.zonedSchedule(
        id: dailyId,
        title: AppStrings.settingsReminderDailyTitle,
        body: AppStrings.settingsReminderDailyBody(
          '${settings.dailyHour.toString().padLeft(2, '0')}.'
          '${settings.dailyMinute.toString().padLeft(2, '0')}',
        ),
        scheduledDate: tz.TZDateTime.from(next, tz.local),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
