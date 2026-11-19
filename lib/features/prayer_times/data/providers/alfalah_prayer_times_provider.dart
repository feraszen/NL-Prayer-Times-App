import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../../location/domain/models/location_data.dart';
import '../../domain/models/prayer_time.dart';
import '../../domain/models/prayer_times.dart';
import '../../domain/models/prayer_type.dart';

/// Uses the same daily endpoint and parameters as alfalahnl.ca's start times.
/// The separate mosque iqama configuration is not used for adhan scheduling.
class AlFalahPrayerTimesProvider {
  AlFalahPrayerTimesProvider({this.client});
  static final instance = AlFalahPrayerTimesProvider();
  final http.Client? client;
  static const maxResponseBytes = 64 * 1024;
  final _requests = <String, Future<Map<String, dynamic>>>{};
  static const timezoneName = 'America/St_Johns';
  static const location = LocationData(
    latitude: 47.5615,
    longitude: -52.7126,
    country: 'Canada',
    region: 'NL',
    city: "St. John's",
    timeZone: timezoneName,
  );

  static tz.Location get zone {
    try {
      return tz.getLocation(timezoneName);
    } on tz.LocationNotFoundException {
      tzdata.initializeTimeZones();
      return tz.getLocation(timezoneName);
    }
  }

  static DateTime get now => tz.TZDateTime.now(zone);
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<PrayerTimes> getPrayerTimes({required DateTime date}) async {
    final prefs = await SharedPreferences.getInstance();
    final day = dateKey(date), key = 'alfalah_day_v1_${dateKey(date)}';
    Map<String, dynamic>? cached;
    try {
      final raw = prefs.getString(key);
      if (raw != null) {
        if (raw.length > maxResponseBytes) {
          throw const FormatException('Oversized cached timetable');
        }
        cached = jsonDecode(raw) as Map<String, dynamic>;
        _readDay(cached, date);
      }
    } catch (_) {
      cached = null;
    }
    if (cached != null && cached['fetchedOn'] == dateKey(now)) {
      return _readDay(cached, date);
    }
    try {
      final request = _requests.putIfAbsent(
        day,
        () => _fetchDay(date, prefs, key),
      );
      late Map<String, dynamic> data;
      try {
        data = await request;
      } finally {
        if (identical(_requests[day], request)) _requests.remove(day);
      }
      return _readDay(data, date);
    } catch (_) {
      if (cached != null) return _readDay(cached, date);
      rethrow; // Never silently substitute GPS times for mosque start times.
    }
  }

  Future<Map<String, dynamic>> _fetchDay(
    DateTime date,
    SharedPreferences prefs,
    String key,
  ) async {
    final pathDate =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity/$pathDate', {
      'country': 'canada',
      'city': 'st johns',
      'method': '2',
      'school': '0',
    });
    final response = await _getTimetable(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200 || body['data'] is! Map) {
      throw const FormatException('Invalid mosque timetable.');
    }
    final data = body['data'] as Map;
    if (data['meta']['timezone'] != timezoneName ||
        data['date']['gregorian']['date'] != pathDate) {
      throw const FormatException('Unexpected timetable date or timezone.');
    }
    final timings = data['timings'] as Map;
    const names = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final entry = <String, dynamic>{
      'timezone': timezoneName,
      'date': dateKey(date),
      'fetchedOn': dateKey(now),
      'times': [for (final name in names) _clock(timings[name])],
    };
    _readDay(
      entry,
      date,
    ); // Validate ordering before replacing usable cache data.
    await prefs.setString(key, jsonEncode(entry));
    return entry;
  }

  Future<http.Response> _getTimetable(Uri uri) async {
    final transport = client ?? http.Client();
    StreamSubscription<List<int>>? subscription;
    Timer? timer;
    try {
      // Never follow a server redirect to a different host or plaintext HTTP.
      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('The St. John’s timetable source is unavailable.');
      }
      if ((response.contentLength ?? 0) > maxResponseBytes) {
        throw const FormatException('Oversized timetable response');
      }
      final done = Completer<List<int>>();
      final bytes = <int>[];
      timer = Timer(const Duration(seconds: 10), () {
        if (!done.isCompleted) {
          done.completeError(TimeoutException('Timetable download timed out'));
        }
      });
      subscription = response.stream.listen(
        (chunk) {
          if (done.isCompleted) return;
          if (chunk.length > maxResponseBytes - bytes.length) {
            done.completeError(
              const FormatException('Oversized timetable response'),
            );
          } else {
            bytes.addAll(chunk);
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        },
        onDone: () {
          if (!done.isCompleted) done.complete(bytes);
        },
        cancelOnError: true,
      );
      final body = await done.future;
      return http.Response.bytes(
        body,
        response.statusCode,
        headers: response.headers,
      );
    } finally {
      timer?.cancel();
      await subscription?.cancel();
      if (client == null) transport.close();
    }
  }

  static String _clock(dynamic value) {
    if (value is! String) throw const FormatException('Missing prayer time.');
    final match = RegExp(r'^(\d{2}):(\d{2})(?:\s.*)?$').firstMatch(value);
    if (match == null ||
        int.parse(match[1]!) > 23 ||
        int.parse(match[2]!) > 59) {
      throw const FormatException('Invalid prayer time.');
    }
    return '${match[1]}:${match[2]}';
  }

  static PrayerTimes _readDay(Map<String, dynamic> entry, DateTime date) {
    if (entry['timezone'] != timezoneName || entry['date'] != dateKey(date)) {
      throw const FormatException('Wrong cached date or timezone.');
    }
    final values = entry['times'] as List?;
    if (values == null || values.length != 6) {
      throw const FormatException('Incomplete mosque timetable.');
    }
    final prayers = <PrayerTime>[];
    for (var i = 0; i < values.length; i++) {
      final parts = _clock(values[i]).split(':');
      final time = tz.TZDateTime(
        zone,
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (prayers.isNotEmpty && !time.isAfter(prayers.last.time)) {
        throw const FormatException('Prayer times are out of order.');
      }
      prayers.add(PrayerTime(type: PrayerType.values[i], time: time));
    }
    return PrayerTimes(
      fajr: prayers[0],
      sunrise: prayers[1],
      dhuhr: prayers[2],
      asr: prayers[3],
      maghrib: prayers[4],
      isha: prayers[5],
    );
  }
}
