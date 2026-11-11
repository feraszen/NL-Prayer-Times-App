import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/models/prayer_times.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  static const int fajrId = 1;
  static const int dhuhrId = 2;
  static const int asrId = 3;
  static const int maghribId = 4;
  static const int ishaId = 5;

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final String timeZone =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(timeZone),
      );

      debugPrint(
        'Timezone initialized: $timeZone',
      );
    } catch (e) {
      debugPrint(
        'Timezone initialization failed: $e',
      );
    }

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(
      settings,
    );

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> showTestNotification() async {
    const androidDetails =
        AndroidNotificationDetails(
      'test_channel_v2',
      'Test Notifications v2',
      channelDescription:
          'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      999,
      'NL Prayer Times',
      'Notifications are working correctly.',
      details,
    );
  }

  Future<void> scheduleNotificationIn30Seconds()
      async {
    final now = DateTime.now();

    final scheduledTime =
        tz.TZDateTime.from(
      now.add(
        const Duration(seconds: 30),
      ),
      tz.local,
    );

    debugPrint('Now: $now');
    debugPrint(
      'Scheduled: $scheduledTime',
    );

    const androidDetails =
        AndroidNotificationDetails(
      'test_channel_v2',
      'Test Notifications v2',
      channelDescription:
          'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.zonedSchedule(
      5000,
      'Notification Test',
      'This notification was scheduled 30 seconds ago.',
      scheduledTime,
      details,
      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,
    );

    debugPrint(
      'Test notification scheduled for $scheduledTime',
    );
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails =
        AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription:
          'Prayer time notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      id,
      title,
      body,
      details,
    );
  }

  Future<void> schedulePrayerNotificationAtTime({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      if (prayerTime.isBefore(
        DateTime.now(),
      )) {
        debugPrint(
          '$prayerName notification skipped (time already passed)',
        );

        return;
      }

      final scheduledTime =
          tz.TZDateTime.from(
        prayerTime,
        tz.local,
      );

      debugPrint(
        '$prayerName notification scheduled for $scheduledTime',
      );

      const androidDetails =
          AndroidNotificationDetails(
        'test_channel_v2',
        'Test Notifications v2',
        channelDescription:
            'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
      );

      const details = NotificationDetails(
        android: androidDetails,
      );

      await notifications.zonedSchedule(
        id,
        '$prayerName Prayer',
        'It\'s time for $prayerName prayer.',
        scheduledTime,
        details,
        androidScheduleMode:
            AndroidScheduleMode
                .inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint(
        'Failed to schedule $prayerName notification: $e',
      );
    }
  }

  Future<void> scheduleDailyPrayerNotifications({
    required PrayerTimes prayerTimes,
    required bool fajrEnabled,
    required bool dhuhrEnabled,
    required bool asrEnabled,
    required bool maghribEnabled,
    required bool ishaEnabled,
  }) async {
    await cancelAllNotifications();

    debugPrint(
      'Scheduling daily prayer notifications...',
    );

    if (fajrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: fajrId,
        prayerName: 'Fajr',
        prayerTime: prayerTimes.fajr.time,
      );
    }

    if (dhuhrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: dhuhrId,
        prayerName: 'Dhuhr',
        prayerTime: prayerTimes.dhuhr.time,
      );
    }

    if (asrEnabled) {
      await schedulePrayerNotificationAtTime(
        id: asrId,
        prayerName: 'Asr',
        prayerTime: prayerTimes.asr.time,
      );
    }

    if (maghribEnabled) {
      await schedulePrayerNotificationAtTime(
        id: maghribId,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes.maghrib.time,
      );
    }

    if (ishaEnabled) {
      await schedulePrayerNotificationAtTime(
        id: ishaId,
        prayerName: 'Isha',
        prayerTime: prayerTimes.isha.time,
      );
    }
  }

  Future<void> printPendingNotifications() async {
    final pending =
        await notifications.pendingNotificationRequests();

    debugPrint(
      'Pending notifications count: ${pending.length}',
    );

    for (final notification in pending) {
      debugPrint(
        'ID: ${notification.id}, '
        'Title: ${notification.title}',
      );
    }
  }

  Future<void> printActiveNotifications() async {
    final active =
        await notifications.getActiveNotifications();

    debugPrint(
      'Active notifications count: ${active.length}',
    );

    for (final item in active) {
      debugPrint(
        'Active ID: ${item.id}',
      );
    }
  }

  Future<void> checkExactAlarmPermission() async {
    final android = notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final allowed =
        await android?.canScheduleExactNotifications();

    debugPrint(
      'Exact alarms allowed: $allowed',
    );
  }

  Future<void> cancelNotification(
    int id,
  ) async {
    await notifications.cancel(id);
  }

  Future<void> cancelAllNotifications()
      async {
    await notifications.cancelAll();
  }
}
