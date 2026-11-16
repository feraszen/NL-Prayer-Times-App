import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/models/prayer_times.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int fajrId = 1;
  static const int dhuhrId = 2;
  static const int asrId = 3;
  static const int maghribId = 4;
  static const int ishaId = 5;

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const prayerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_channel_v2',
      'Prayer Notifications',
      channelDescription: 'Prayer times with bundled adhan',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adhan'),
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
  );

  static const silentPrayerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_silent_v1',
      'Silent Prayer Notifications',
      channelDescription: 'Prayer reminders without adhan',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    ),
  );
  Future<NotificationDetails> _details() async {
    final enabled =
        (await SharedPreferences.getInstance()).getBool('adhan_enabled') ??
        true;
    return enabled ? prayerDetails : silentPrayerDetails;
  }

  Future<AndroidScheduleMode> scheduleMode() async {
    final android = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> initialize() async {
    if (!isSupported) return;
    tz.initializeTimeZones();

    try {
      final String timeZone = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(timeZone));

      debugPrint('Timezone initialized: $timeZone');
    } catch (e) {
      debugPrint('Timezone initialization failed: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await notifications.initialize(settings);

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (!isSupported) return;
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<void> showTestNotification() async {
    await notifications.show(
      999,
      'NL Prayer Times',
      'Prayer notification and adhan test.',
      await _details(),
    );
  }

  Future<void> scheduleNotificationIn30Seconds() async {
    final now = DateTime.now();

    final scheduledTime = tz.TZDateTime.from(
      now.add(const Duration(seconds: 30)),
      tz.local,
    );

    debugPrint('Now: $now');
    debugPrint('Scheduled: $scheduledTime');

    await notifications.zonedSchedule(
      5000,
      'Notification Test',
      'This notification was scheduled 30 seconds ago.',
      scheduledTime,
      await _details(),
      androidScheduleMode: await scheduleMode(),
    );

    debugPrint('Test notification scheduled for $scheduledTime');
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await notifications.show(id, title, body, prayerDetails);
  }

  Future<void> schedulePrayerNotificationAtTime({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    if (!prayerTime.isAfter(DateTime.now())) return;
    await notifications.zonedSchedule(
      id,
      '$prayerName Prayer',
      "It's time for $prayerName prayer.",
      tz.TZDateTime.from(prayerTime, tz.local),
      await _details(),
      androidScheduleMode: await scheduleMode(),
    );
  }

  Future<void> scheduleDailyPrayerNotifications({
    required PrayerTimes prayerTimes,
    int dayOffset = 0,
    required bool fajrEnabled,
    required bool dhuhrEnabled,
    required bool asrEnabled,
    required bool maghribEnabled,
    required bool ishaEnabled,
  }) async {
    debugPrint('Scheduling daily prayer notifications...');

    if (fajrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: fajrId + dayOffset * 10,
        prayerName: 'Fajr',
        prayerTime: prayerTimes.fajr.time,
      );
    }

    if (dhuhrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: dhuhrId + dayOffset * 10,
        prayerName: 'Dhuhr',
        prayerTime: prayerTimes.dhuhr.time,
      );
    }

    if (asrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: asrId + dayOffset * 10,
        prayerName: 'Asr',
        prayerTime: prayerTimes.asr.time,
      );
    }

    if (maghribEnabled) {
      await schedulePrayerNotificationAtTime(
        id: maghribId + dayOffset * 10,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes.maghrib.time,
      );
    }

    if (ishaEnabled) {
      await schedulePrayerNotificationAtTime(
        id: ishaId + dayOffset * 10,
        prayerName: 'Isha',
        prayerTime: prayerTimes.isha.time,
      );
    }
  }

  Future<void> printPendingNotifications() async {
    final pending = await notifications.pendingNotificationRequests();

    debugPrint('Pending notifications count: ${pending.length}');

    for (final notification in pending) {
      debugPrint(
        'ID: ${notification.id}, '
        'Title: ${notification.title}',
      );
    }
  }

  Future<void> printActiveNotifications() async {
    final active = await notifications.getActiveNotifications();

    debugPrint('Active notifications count: ${active.length}');

    for (final item in active) {
      debugPrint('Active ID: ${item.id}');
    }
  }

  Future<void> checkExactAlarmPermission() async {
    final android = notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final allowed = await android?.canScheduleExactNotifications();

    debugPrint('Exact alarms allowed: $allowed');
  }

  Future<void> cancelPrayerNotifications() async {
    if (!isSupported) return;
    // Only our prayer IDs: diagnostic and other notifications remain intact.
    for (var day = 0; day < 7; day++) {
      for (var prayer = 1; prayer <= 5; prayer++) {
        await notifications.cancel(day * 10 + prayer);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await notifications.cancelAll();
  }
}
