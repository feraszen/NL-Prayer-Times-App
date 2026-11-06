import '../../domain/models/prayer_time.dart';
import '../../domain/models/prayer_times.dart';
import '../../domain/models/prayer_type.dart';

class PrayerTimesMockProvider {
  const PrayerTimesMockProvider();

  PrayerTimes getPrayerTimes() {
    final now = DateTime.now();

    return PrayerTimes(
      fajr: PrayerTime(
        type: PrayerType.fajr,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          5,
          24,
        ),
      ),

      sunrise: PrayerTime(
        type: PrayerType.sunrise,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          6,
          51,
        ),
      ),

      dhuhr: PrayerTime(
        type: PrayerType.dhuhr,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          11,
          44,
        ),
      ),

      asr: PrayerTime(
        type: PrayerType.asr,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          14,
          14,
        ),
      ),

      maghrib: PrayerTime(
        type: PrayerType.maghrib,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          16,
          37,
        ),
      ),

      isha: PrayerTime(
        type: PrayerType.isha,
        time: DateTime(
          now.year,
          now.month,
          now.day,
          18,
          5,
        ),
      ),
    );
  }
}
