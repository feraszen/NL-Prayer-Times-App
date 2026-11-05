import '../models/prayer_times.dart';

abstract class PrayerTimeCalculator {
  PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  });
}
