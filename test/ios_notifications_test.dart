import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:nl_prayer_times_app/core/services/notification_service.dart';
import 'package:nl_prayer_times_app/core/services/ios_prayer_alarm_service.dart';
import 'package:nl_prayer_times_app/core/services/custom_adhan_service.dart';
import 'package:nl_prayer_times_app/core/services/prayer_notification_scheduler.dart';
import 'package:nl_prayer_times_app/core/services/settings_service.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/providers/real_prayer_times_provider.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/services/prayer_times_service.dart';
import 'package:nl_prayer_times_app/features/location/domain/models/location_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[], alarmCalls = <MethodCall>[];
  var allowed = true, alarmAllowed = true;
  const location = LocationData(
    latitude: 47.5615,
    longitude: -52.7126,
    city: "St. John's",
    region: 'NL',
    country: 'Canada',
    timeZone: 'America/St_Johns',
  );
  final scheduler = PrayerNotificationScheduler(
    prayerTimesService: const PrayerTimesService(
      provider: RealPrayerTimesProvider(),
    ),
    settingsService: SettingsService(),
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/St_Johns'));
    SharedPreferences.setMockInitialValues({});
    NotificationService.instance.iosDefaultSoundReady = true;
    allowed = true;
    alarmAllowed = true;
    calls.clear();
    alarmCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'requestPermissions') return allowed;
          if (call.method == 'checkPermissions') {
            return {'isEnabled': allowed, 'isSoundEnabled': allowed};
          }
          if (call.method == 'pendingNotificationRequests') {
            return <Map<String, dynamic>>[];
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(IOSPrayerAlarmService.channel, (call) async {
          alarmCalls.add(call);
          if (call.method == 'status') {
            return {'available': true, 'authorized': alarmAllowed};
          }
          if (call.method == 'requestPermission') return alarmAllowed;
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
    expect(details['presentSound'], true);
    expect(details['categoryIdentifier'], isNull);
    expect(alarmCalls.where((c) => c.method == 'schedule'), isEmpty);
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
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(IOSPrayerAlarmService.channel, null);
  });

  test(
    'iPhone permission denial is surfaced rather than enabling a false alert',
    () async {
      allowed = false;
      await expectLater(
        NotificationService.instance.requestPermissions(),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        scheduler.scheduleNotifications(location: location),
        completes,
      ); // master disabled
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      calls.clear();
      await expectLater(
        scheduler.scheduleNotifications(location: location),
        throwsA(isA<PlatformException>()),
      );
      expect(
        calls.where((c) => c.method == 'cancel' || c.method == 'zonedSchedule'),
        isEmpty,
      );
    },
  );

  test(
    'seven iPhone dates use start times, unique IDs and fewer than 64 notifications',
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
      expect(scheduled.map((n) => n['id']).toSet().length, scheduled.length);
      for (final n in scheduled) {
        expect((n['id'] as int) % 10, isNot(1));
        expect(n['timeZoneName'], 'America/St_Johns');
        final ios = n['platformSpecifics'] as Map;
        expect(ios['sound'], CustomAdhanService.defaultIOSSound);
        expect(ios['presentSound'], true);
        expect(ios['categoryIdentifier'], 'prayer_audio');
      }
      expect(alarmCalls.where((c) => c.method == 'schedule'), isEmpty);
    },
  );

  test(
    'custom iPhone sound and mute use Darwin rather than Android sound settings',
    () async {
      SharedPreferences.setMockInitialValues({
        CustomAdhanService.iosSoundKey: 'mine_short.wav',
      });
      await NotificationService.instance.schedulePrayerNotificationAtTime(
        id: 3,
        prayerName: 'Asr',
        prayerTime: DateTime.now().add(const Duration(hours: 1)),
      );
      var ios =
          ((calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
                  as Map)['platformSpecifics']
              as Map);
      expect(ios['sound'], 'mine_short.wav');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('adhan_enabled', false);
      calls.clear();
      await NotificationService.instance.schedulePrayerNotificationAtTime(
        id: 3,
        prayerName: 'Asr',
        prayerTime: DateTime.now().add(const Duration(hours: 1)),
      );
      ios =
          (calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
                  as Map)['platformSpecifics']
              as Map;
      expect(ios['presentSound'], false);
      expect(ios['sound'], isNull);
      expect(ios['categoryIdentifier'], 'prayer_silent');
    },
  );

  test(
    'AlarmKit uses exact prayer instant and full selected sound without duplicate notification audio',
    () async {
      SharedPreferences.setMockInitialValues({
        IOSPrayerAlarmService.enabledKey: true,
        CustomAdhanService.iosAlarmSoundKey: 'mine_full.wav',
      });
      final time = DateTime.now().add(const Duration(hours: 1));
      await NotificationService.instance.schedulePrayerNotificationAtTime(
        id: 3,
        prayerName: 'Asr',
        prayerTime: time,
      );
      final alarm =
          alarmCalls.singleWhere((c) => c.method == 'schedule').arguments
              as Map;
      expect(alarm['timestamp'], time.millisecondsSinceEpoch / 1000);
      expect(alarm['sound'], 'mine_full.wav');
      expect(alarm['id'], 3);
      final ios =
          (calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
                  as Map)['platformSpecifics']
              as Map;
      expect(ios['presentSound'], false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('adhan_enabled', false);
      alarmCalls.clear();
      calls.clear();
      await NotificationService.instance.schedulePrayerNotificationAtTime(
        id: 3,
        prayerName: 'Asr',
        prayerTime: time,
      );
      expect(alarmCalls.where((c) => c.method == 'schedule'), isEmpty);
    },
  );

  test('revoked alarm authorization preserves existing reminders', () async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      IOSPrayerAlarmService.enabledKey: true,
    });
    alarmAllowed = false;
    await expectLater(
      scheduler.scheduleNotifications(location: location),
      throwsA(isA<PlatformException>()),
    );
    expect(
      calls.where((c) => c.method == 'cancel' || c.method == 'zonedSchedule'),
      isEmpty,
    );
    expect(alarmCalls.where((c) => c.method == 'cancelPrayerAlarms'), isEmpty);
  });

  test(
    'disabling master cancels owned iPhone reminders and companion alarms only',
    () async {
      await scheduler.scheduleNotifications(location: location);
      expect(
        alarmCalls.where((c) => c.method == 'cancelPrayerAlarms').length,
        1,
      );
      final ids = calls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments as int)
          .toSet();
      expect(ids.length, 42);
      expect(ids, containsAll([1, 5, 61, 65]));
      expect(ids, isNot(contains(5000)));
      expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
    },
  );
}
