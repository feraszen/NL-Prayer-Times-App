import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:nl_prayer_times_app/core/services/notification_service.dart';
import 'package:nl_prayer_times_app/core/services/prayer_notification_scheduler.dart';
import 'package:nl_prayer_times_app/core/services/settings_service.dart';
import 'package:nl_prayer_times_app/features/location/domain/models/location_data.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/providers/real_prayer_times_provider.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var exactAllowed = true;
  var failSchedule = false;
  const location = LocationData(
    latitude: 47.5615,
    longitude: -52.7126,
    country: 'Canada',
    region: 'NL',
    city: "St. John's",
    timeZone: 'America/St_Johns',
  );
  final scheduler = PrayerNotificationScheduler(
    prayerTimesService: PrayerTimesService(provider: RealPrayerTimesProvider()),
    settingsService: SettingsService(),
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/St_Johns'));
    exactAllowed = true;
    failSchedule = false;
    calls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'zonedSchedule' && failSchedule) {
            throw PlatformException(code: 'test_schedule_failure');
          }
          if (call.method == 'canScheduleExactNotifications') {
            return exactAllowed;
          }
          return null;
        });
  });

  test('sunrise uses normal sound and never adhan or AlarmKit', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'adhan_enabled': false,
      'custom_adhan_uri': 'content://media/audio/123',
      'custom_adhan_token': 'custom',
      'ios_prayer_alarms_enabled': true,
    });
    final time = DateTime.now().add(const Duration(hours: 1));
    await NotificationService.instance.scheduleSunriseNotificationAtTime(
      id: 6,
      time: time,
    );
    final n =
        calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    final details = n['platformSpecifics'] as Map;
    expect(details['sound'], isNull);
    expect(details['playSound'], true);
    expect(details['channelId'], 'sunrise_default_v1');
    expect(n['payload'], contains('sunrise'));
    calls.clear();
    await NotificationService.instance.scheduleSunriseNotificationAtTime(
      id: 6,
      time: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(calls, isEmpty);
  });

  test('sunrise is included in the schedule and can be disabled', () async {
    SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    await scheduler.scheduleNotifications(location: location);
    var scheduled = calls
        .where((c) => c.method == 'zonedSchedule')
        .map((c) => c.arguments as Map)
        .toList();
    expect(
      scheduled.where((n) => (n['id'] as int) % 10 == 6).length,
      inInclusiveRange(6, 7),
    );
    expect(scheduled.length, lessThanOrEqualTo(42));
    await (await SharedPreferences.getInstance()).setBool(
      'sunrise_notification',
      false,
    );
    calls.clear();
    await scheduler.scheduleNotifications(location: location);
    scheduled = calls
        .where((c) => c.method == 'zonedSchedule')
        .map((c) => c.arguments as Map)
        .toList();
    expect(scheduled.where((n) => (n['id'] as int) % 10 == 6), isEmpty);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('disabled master switch cancels only owned prayer IDs', () async {
    await scheduler.scheduleNotifications(location: location);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    final cancelled = calls
        .where((c) => c.method == 'cancel')
        .map((c) => (c.arguments as Map)['id'])
        .toSet();
    expect(cancelled.length, 42);
    expect(cancelled, containsAll([1, 5, 61, 65]));
    expect(cancelled, isNot(contains(5000)));
    expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
  });

  test(
    'seven days use unique IDs and respect individual prayer settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'fajr_notification': false,
        'sunrise_notification': false,
      });
      await scheduler.scheduleNotifications(location: location);
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => c.arguments as Map)
          .toList();
      expect(scheduled.length, inInclusiveRange(24, 28));
      final ids = scheduled.map((c) => c['id'] as int).toSet();
      expect(ids.length, scheduled.length);
      expect(ids.every((id) => id % 10 != 1), isTrue);
      expect(ids, containsAll([62, 63, 64, 65]));
      for (final notification in scheduled) {
        expect(notification['timeZoneName'], 'America/St_Johns');
        final android = notification['platformSpecifics'] as Map;
        expect(android['channelId'], 'prayer_channel_v2');
        expect(android['sound'], 'adhan');
        expect(android['scheduleMode'], 'exactAllowWhileIdle');
      }
    },
  );

  test(
    'denied exact alarms fall back without dropping the notification',
    () async {
      exactAllowed = false;
      await NotificationService.instance.scheduleNotificationIn30Seconds();
      final notification = calls.singleWhere(
        (c) => c.method == 'zonedSchedule',
      );
      final android =
          (notification.arguments as Map)['platformSpecifics'] as Map;
      expect(android['scheduleMode'], 'inexactAllowWhileIdle');
      expect(android['channelId'], 'prayer_channel_v2');
      expect(android['sound'], 'adhan');
    },
  );

  test(
    'scheduling errors reach caller and do not prevent a later retry',
    () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      failSchedule = true;
      await expectLater(
        scheduler.scheduleNotifications(location: location),
        throwsA(isA<PlatformException>()),
      );
      failSchedule = false;
      calls.clear();
      await scheduler.scheduleNotifications(location: location);
      expect(calls.where((c) => c.method == 'zonedSchedule'), isNotEmpty);
    },
  );

  test('adhan can be muted without disabling prayer reminders', () async {
    SharedPreferences.setMockInitialValues({'adhan_enabled': false});
    await NotificationService.instance.scheduleNotificationIn30Seconds();
    final call = calls.singleWhere((c) => c.method == 'zonedSchedule');
    final android = (call.arguments as Map)['platformSpecifics'] as Map;
    expect(android['channelId'], 'prayer_silent_v1');
    expect(android['playSound'], isFalse);
  });

  test('imported audio drives real prayer alerts and diagnostics', () async {
    SharedPreferences.setMockInitialValues({
      'custom_adhan_uri': 'content://media/external/audio/media/123',
      'custom_adhan_token': 'audio123',
    });
    await NotificationService.instance.schedulePrayerNotificationAtTime(
      id: 1,
      prayerName: 'Fajr',
      prayerTime: DateTime.now().add(const Duration(hours: 1)),
    );
    await NotificationService.instance.showTestNotification();
    await NotificationService.instance.scheduleNotificationIn30Seconds();
    for (final call in calls.where(
      (c) => c.method == 'zonedSchedule' || c.method == 'show',
    )) {
      final android = (call.arguments as Map)['platformSpecifics'] as Map;
      expect(android['channelId'], 'prayer_custom_audio123');
      expect(android['sound'], 'content://media/external/audio/media/123');
      expect(android['soundSource'], 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'custom_adhan_uri',
      'content://media/external/audio/media/456',
    );
    await prefs.setString('custom_adhan_token', 'audio456');
    calls.clear();
    await NotificationService.instance.showTestNotification();
    expect(
      ((calls.single.arguments as Map)['platformSpecifics']
          as Map)['channelId'],
      'prayer_custom_audio456',
    );
    await prefs.setBool('adhan_enabled', false);
    calls.clear();
    await NotificationService.instance.showTestNotification();
    expect(
      ((calls.single.arguments as Map)['platformSpecifics']
          as Map)['playSound'],
      false,
    );
  });

  test('past prayers are not scheduled', () async {
    await NotificationService.instance.schedulePrayerNotificationAtTime(
      id: 1,
      prayerName: 'Fajr',
      prayerTime: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(calls, isEmpty);
  });
}
