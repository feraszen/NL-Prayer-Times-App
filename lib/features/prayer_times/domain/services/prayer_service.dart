import '../models/prayer_time.dart';
import '../models/prayer_times.dart';

class PrayerService {
  const PrayerService();

  PrayerTime getCurrentPrayer(
    PrayerTimes prayerTimes,
    DateTime now,
  ) {
    final prayers = prayerTimes.allPrayers;

    for (int i = prayers.length - 1; i >= 0; i--) {
      if (now.isAfter(prayers[i].time)) {
        return prayers[i];
      }
    }

    return prayerTimes.isha;
  }

  PrayerTime getNextPrayer(
    PrayerTimes prayerTimes,
    DateTime now,
  ) {
    final prayers = prayerTimes.allPrayers;

    for (final prayer in prayers) {
      if (now.isBefore(prayer.time)) {
        return prayer;
      }
    }

    return prayerTimes.fajr;
  }

  Duration getTimeRemaining(
    PrayerTimes prayerTimes,
    DateTime now,
  ) {
    final nextPrayer = getNextPrayer(
      prayerTimes,
      now,
    );

    if (nextPrayer.time.isAfter(now)) {
      return nextPrayer.time.difference(now);
    }

    final tomorrowFajr = nextPrayer.time.add(
      const Duration(days: 1),
    );

    return tomorrowFajr.difference(now);
  }
}
