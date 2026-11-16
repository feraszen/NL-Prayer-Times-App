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
    expect(cancelled.length, 35);
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

  test('past prayers are not scheduled', () async {
    await NotificationService.instance.schedulePrayerNotificationAtTime(
      id: 1,
      prayerName: 'Fajr',
      prayerTime: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(calls, isEmpty);
  });
}
