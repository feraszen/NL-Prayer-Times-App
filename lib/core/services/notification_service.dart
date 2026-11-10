import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

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
          AndroidScheduleMode.exactAllowWhileIdle,    );
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