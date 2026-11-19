import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'custom_adhan_service.dart';
import 'ios_prayer_alarm_service.dart';
import 'adhan_playback_service.dart';

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
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || isIOS);
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String? lastPreparationError;
  String? iosAudioPreparationError;
  bool iosDefaultSoundReady = false;
  final statusRevision = ValueNotifier<int>(0);
  final alarms = IOSPrayerAlarmService();
  DateTime? lastScheduledAt;
  void reportSchedulingError(Object error) {
    lastPreparationError = error.toString();
    statusRevision.value++;
  }

  void reportScheduled() {
    lastPreparationError = iosAudioPreparationError;
    lastScheduledAt = DateTime.now();
    statusRevision.value++;
  }

  Future<Map<String, dynamic>> iosStatus() async {
    final permissions = await notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    final pending = await notifications.pendingNotificationRequests();
    final alarmState = await alarms.status();
    return {
      ...alarmState,
      'notifications': permissions?.isEnabled ?? false,
      'sound': permissions?.isSoundEnabled ?? false,
      'pending': pending
          .where(
            (n) => n.id >= 1 && n.id <= 65 && n.id % 10 >= 1 && n.id % 10 <= 5,
          )
          .length,
      'alarmEnabled': await alarms.enabled(),
    };
  }

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
    final prefs = await SharedPreferences.getInstance();
    if (isIOS) {
      final audible = prefs.getBool('adhan_enabled') ?? true;
      final alarm = audible && await alarms.enabled();
      return NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: audible && !alarm,
          sound: audible && !alarm
              ? prefs.getString(CustomAdhanService.iosSoundKey) ??
                    (iosDefaultSoundReady
                        ? CustomAdhanService.defaultIOSSound
                        : null)
              : null,
          categoryIdentifier: audible ? 'prayer_audio' : 'prayer_silent',
          threadIdentifier: 'prayer_times',
        ),
      );
    }
    if (!(prefs.getBool('adhan_enabled') ?? true)) return silentPrayerDetails;
    final uri = prefs.getString(CustomAdhanService.uriKey);
    final token = prefs.getString(CustomAdhanService.tokenKey);
    if (uri == null || token == null) return prayerDetails;
    // Android channel sounds are immutable. Each imported audio has its own
    // content-derived channel so it cannot retain a previous file's sound.
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_custom_$token',
        'Prayer Notifications',
        channelDescription: 'Prayer times with selected audio',
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(uri),
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
    );
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

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'prayer_audio',
            actions: [
              DarwinNotificationAction.plain(
                'PLAY_ADHAN',
                'Play full adhan',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      ),
    );

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: handleResponse,
    );
    if (isIOS) {
      try {
        await CustomAdhanService().prepareIOSDefaultSound();
        iosDefaultSoundReady = true;
      } catch (e) {
        iosAudioPreparationError = 'Unable to prepare default iPhone audio: $e';
        lastPreparationError = iosAudioPreparationError;
        debugPrint(lastPreparationError);
      }
      final launch = await notifications.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && response != null) {
        handleResponse(response);
      }
    } else {
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    if (!isSupported) return;
    if (isIOS) {
      final allowed = await notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (allowed != true) {
        throw PlatformException(
          code: 'IOS_NOTIFICATIONS_DENIED',
          message:
              'Enable notifications for NL Prayer Times in iPhone Settings',
        );
      }
      return;
    }
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
      payload: await _payload(),
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
      payload: await _payload(),
      androidScheduleMode: await scheduleMode(),
    );

    debugPrint('Test notification scheduled for $scheduledTime');
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await notifications.show(
      id,
      title,
      body,
      await _details(),
      payload: await _payload(),
    );
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
      payload: await _payload(),
      androidScheduleMode: await scheduleMode(),
    );
    if (isIOS && await alarms.enabled()) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('adhan_enabled') ?? true) {
        await alarms.schedule(
          id: id,
          title: '$prayerName Prayer',
          time: prayerTime,
          sound:
              prefs.getString(CustomAdhanService.iosAlarmSoundKey) ??
              CustomAdhanService.defaultIOSAlarmSound,
        );
      }
    }
  }

  void handleResponse(NotificationResponse response) {
    if (!isIOS || response.actionId != 'PLAY_ADHAN') return;
    try {
      final payload = jsonDecode(response.payload ?? '{}');
      if (payload is Map &&
          payload['kind'] == 'prayer' &&
          payload['audio'] == true) {
        AdhanPlaybackService.instance.play();
      }
    } catch (_) {
      /* Other applications' or malformed payloads never play audio. */
    }
  }

  Future<String> _payload() async => jsonEncode({
    'kind': 'prayer',
    'audio':
        (await SharedPreferences.getInstance()).getBool('adhan_enabled') ??
        true,
  });

  Future<void> prepareScheduling() async {
    if (!isIOS) return;
    final permissions = await notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    if (permissions?.isEnabled != true) {
      throw PlatformException(
        code: 'IOS_NOTIFICATIONS_DENIED',
        message: 'Enable notifications in iPhone Settings',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    if (await alarms.enabled() && (prefs.getBool('adhan_enabled') ?? true)) {
      final state = await alarms.status();
      if (state['available'] != true || state['authorized'] != true) {
        throw PlatformException(
          code: 'IOS_ALARMS_DENIED',
          message: 'Allow prayer alarms in Settings or turn off iOS alarms',
        );
      }
      if (prefs.getString(CustomAdhanService.iosAlarmSoundKey) == null &&
          !iosDefaultSoundReady) {
        throw StateError('iPhone alarm audio is not ready. Reopen the app.');
      }
    }
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
    if (isIOS) await alarms.cancelPrayerAlarms();
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
