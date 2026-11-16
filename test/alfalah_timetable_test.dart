import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:nl_prayer_times_app/core/services/settings_service.dart';
import 'package:nl_prayer_times_app/core/services/prayer_notification_scheduler.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/providers/alfalah_prayer_times_provider.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/providers/real_prayer_times_provider.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/services/prayer_schedule_loader.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/services/prayer_times_service.dart';
import 'package:nl_prayer_times_app/features/prayer_times/domain/models/prayer_type.dart';
import 'package:nl_prayer_times_app/features/prayer_times/domain/services/prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture =
      jsonDecode(
            File('test/fixtures/alfalah_2026_11_16.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final date = DateTime(2026, 11, 16);
  const local = PrayerTimesService(provider: RealPrayerTimesProvider());
  const location = AlFalahPrayerTimesProvider.location;
  const native = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  Map<String, dynamic> responseFor(DateTime date) {
    final copy = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
    copy['data']['date']['gregorian']['date'] =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    return copy;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/St_Johns'));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, (call) async {
          calls.add(call);
          return call.method == 'canScheduleExactNotifications' ? true : null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, null);
  });

  test('16 November matches the screenshot start times, not the iqama', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/timingsByCity/16-11-2026');
      expect(request.url.queryParameters, {
        'country': 'canada',
        'city': 'st johns',
        'method': '2',
        'school': '0',
      });
      return http.Response(jsonEncode(fixture), 200);
    });
    final times = await AlFalahPrayerTimesProvider(
      client: client,
    ).getPrayerTimes(date: date);
    final values =
        [
              times.fajr,
              times.sunrise,
              times.dhuhr,
              times.asr,
              times.maghrib,
              times.isha,
            ]
            .map(
              (prayer) =>
                  '${prayer.time.hour.toString().padLeft(2, '0')}:${prayer.time.minute.toString().padLeft(2, '0')}',
            )
            .toList();
    expect(values, ['05:38', '07:07', '11:46', '14:03', '16:23', '17:53']);
    expect(times.asr.time.toUtc(), DateTime.utc(2026, 11, 16, 17, 33));
    expect(times.asr.time.minute, isNot(30));
    client.close();
  });

  test(
    'concurrent requests share one fetch and saved dates work offline',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(fixture), 200);
      });
      final provider = AlFalahPrayerTimesProvider(client: client);
      await Future.wait(
        List.generate(4, (_) => provider.getPrayerTimes(date: date)),
      );
      expect(requests, 1);
      final offline = AlFalahPrayerTimesProvider(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect((await offline.getPrayerTimes(date: date)).asr.time.minute, 3);
      client.close();
    },
  );

  test(
    'offline cache is date-specific and never invents next-day times',
    () async {
      final provider = AlFalahPrayerTimesProvider(
        client: MockClient(
          (_) async => http.Response(jsonEncode(fixture), 200),
        ),
      );
      await provider.getPrayerTimes(date: date);
      final prefs = await SharedPreferences.getInstance();
      final key = 'alfalah_day_v1_2026-11-16';
      final cached = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      cached['fetchedOn'] = '2026-11-15';
      await prefs.setString(key, jsonEncode(cached));
      final offline = AlFalahPrayerTimesProvider(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect((await offline.getPrayerTimes(date: date)).asr.time.minute, 3);
      await expectLater(
        offline.getPrayerTimes(date: DateTime(2026, 11, 17)),
        throwsA(isA<http.ClientException>()),
      );
    },
  );

  test(
    'wrong dates, timezones and malformed times are rejected before caching',
    () async {
      for (final kind in ['date', 'zone', 'time']) {
        final bad = responseFor(date);
        if (kind == 'date') {
          bad['data']['date']['gregorian']['date'] = '15-11-2026';
        }
        if (kind == 'zone') bad['data']['meta']['timezone'] = 'UTC';
        if (kind == 'time') bad['data']['timings']['Asr'] = '25:89';
        final provider = AlFalahPrayerTimesProvider(
          client: MockClient((_) async => http.Response(jsonEncode(bad), 200)),
        );
        await expectLater(
          provider.getPrayerTimes(date: date),
          throwsFormatException,
        );
        expect(
          (await SharedPreferences.getInstance()).getString(
            'alfalah_day_v1_2026-11-16',
          ),
          isNull,
        );
      }
    },
  );

  test('offsets apply exactly once and sunrise is unchanged', () async {
    final loader = PrayerScheduleLoader(localService: local);
    final base = await loader.load(
      location: location,
      date: date,
      source: PrayerTimeSource.gps,
      adjustments: {},
    );
    final adjusted = await loader.load(
      location: location,
      date: date,
      source: PrayerTimeSource.gps,
      adjustments: {PrayerType.asr: 2, PrayerType.dhuhr: -1},
      includeTomorrow: true,
    );
    expect(
      adjusted.asr.time.difference(base.asr.time),
      const Duration(minutes: 2),
    );
    expect(
      adjusted.dhuhr.time.difference(base.dhuhr.time),
      const Duration(minutes: -1),
    );
    expect(adjusted.sunrise.time, base.sunrise.time);
    final afterIsha = adjusted.isha.time.add(const Duration(minutes: 1));
    final next = const PrayerService().getNextPrayer(adjusted, afterIsha);
    final tomorrow = local.getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
      date: DateTime(2026, 11, 17),
    );
    expect(next.time, tomorrow.fajr.time);
    expect(
      const PrayerService().getTimeRemaining(adjusted, afterIsha),
      tomorrow.fajr.time.difference(afterIsha),
    );
    expect(
      const PrayerService().getCurrentPrayer(adjusted, adjusted.asr.time).type,
      PrayerType.asr,
    );
  });

  test(
    'source and individual offsets persist; invalid adjustments are refused',
    () async {
      final settings = SettingsService();
      expect(await settings.getPrayerTimeSource(), PrayerTimeSource.gps);
      expect((await settings.getPrayerAdjustments()).values, everyElement(0));
      await settings.savePrayerTimeSource(PrayerTimeSource.alFalah);
      await settings.savePrayerAdjustment(PrayerType.asr, 2);
      expect(
        await SettingsService().getPrayerTimeSource(),
        PrayerTimeSource.alFalah,
      );
      expect(
        (await SettingsService().getPrayerAdjustments())[PrayerType.asr],
        2,
      );
      await expectLater(
        settings.savePrayerAdjustment(PrayerType.asr, 31),
        throwsArgumentError,
      );
      await expectLater(
        settings.savePrayerAdjustment(PrayerType.sunrise, 1),
        throwsArgumentError,
      );
    },
  );

  test(
    'mosque schedule uses the same corrected start time as the display loader',
    () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'prayer_time_source': 'alFalah',
        'prayer_adjustment_asr': 2,
      });
      final provider = AlFalahPrayerTimesProvider(
        client: MockClient((request) async {
          final parts = request.url.pathSegments.last
              .split('-')
              .map(int.parse)
              .toList();
          return http.Response(
            jsonEncode(responseFor(DateTime(parts[2], parts[1], parts[0]))),
            200,
          );
        }),
      );
      await PrayerNotificationScheduler(
        prayerTimesService: local,
        settingsService: SettingsService(),
        mosqueProvider: provider,
      ).scheduleNotifications(location: location);
      final nextDayAsr = calls.singleWhere(
        (call) =>
            call.method == 'zonedSchedule' &&
            (call.arguments as Map)['id'] == 13,
      );
      final args = nextDayAsr.arguments as Map;
      expect(args['scheduledDateTime'].toString(), contains('T14:05:00'));
      expect(args['timeZoneName'], 'America/St_Johns');
      final now = AlFalahPrayerTimesProvider.now;
      final displayed =
          await PrayerScheduleLoader(
            localService: local,
            mosqueProvider: provider,
          ).load(
            location: location,
            date: DateTime(now.year, now.month, now.day + 1),
            source: PrayerTimeSource.alFalah,
            adjustments: {PrayerType.asr: 2},
          );
      expect(displayed.asr.time.hour, 14);
      expect(displayed.asr.time.minute, 5);
    },
  );

  test(
    'failed mosque refresh does not cancel existing alarms or schedule GPS substitutes',
    () async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'prayer_time_source': 'alFalah',
      });
      final provider = AlFalahPrayerTimesProvider(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        PrayerNotificationScheduler(
          prayerTimesService: local,
          settingsService: SettingsService(),
          mosqueProvider: provider,
        ).scheduleNotifications(location: location),
        throwsA(isA<http.ClientException>()),
      );
      expect(
        calls.where(
          (c) =>
              c.method == 'cancel' ||
              c.method == 'cancelAll' ||
              c.method == 'zonedSchedule',
        ),
        isEmpty,
      );
    },
  );
}
