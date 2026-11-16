import 'prayer_time.dart';
import 'prayer_times.dart';
import 'prayer_type.dart';

/// Minute adjustments are applied once, to both display and alarm instants.
class PrayerTimeAdjustments {
  final Map<PrayerType, int> minutes;
  const PrayerTimeAdjustments(this.minutes);

  PrayerTimes apply(PrayerTimes times) {
    PrayerTime adjusted(PrayerTime prayer) => PrayerTime(
      type: prayer.type,
      time: prayer.time.add(Duration(minutes: minutes[prayer.type] ?? 0)),
    );
    return PrayerTimes(
      fajr: adjusted(times.fajr),
      sunrise: times.sunrise,
      dhuhr: adjusted(times.dhuhr),
      asr: adjusted(times.asr),
      maghrib: adjusted(times.maghrib),
      isha: adjusted(times.isha),
      nextDayFajr: times.nextDayFajr == null
          ? null
          : adjusted(times.nextDayFajr!),
    );
  }
}
