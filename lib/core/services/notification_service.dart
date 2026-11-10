import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  final FlutterLocalNotificationsPlugin
      notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

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
  }

  Future<void> requestPermissions() async {
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTestNotification() async {
    const androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription:
          'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(
      1,
      'NL Prayer Times',
      'Notifications are working correctly.',
      details,
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

      debugPrint(
        '$prayerName notification scheduled for $prayerTime',
      );

      const androidDetails =
          AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        channelDescription:
            'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
      );

      await notifications.zonedSchedule(
        id,
        '$prayerName Prayer',
        'It\'s time for $prayerName prayer.',
        tz.TZDateTime.from(
          prayerTime,
          tz.local,
        ),
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
      debugPrint('Scheduling Fajr');

      await schedulePrayerNotificationAtTime(
        id: fajrId,
        prayerName: 'Fajr',
        prayerTime: prayerTimes.fajr.time,
      );
    }

    if (dhuhrEnabled) {
      debugPrint('Scheduling Dhuhr');

      await schedulePrayerNotificationAtTime(
        id: dhuhrId,
        prayerName: 'Dhuhr',
        prayerTime: prayerTimes.dhuhr.time,
      );
    }

    if (asrEnabled) {
      debugPrint('Scheduling Asr');

      await schedulePrayerNotificationAtTime(
        id: asrId,
        prayerName: 'Asr',
        prayerTime: prayerTimes.asr.time,
      );
    }

    if (maghribEnabled) {
      debugPrint('Scheduling Maghrib');

      await schedulePrayerNotificationAtTime(
        id: maghribId,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes.maghrib.time,
      );
    }

    if (ishaEnabled) {
      debugPrint('Scheduling Isha');

      await schedulePrayerNotificationAtTime(
        id: ishaId,
        prayerName: 'Isha',
        prayerTime: prayerTimes.isha.time,
      );
    }
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
