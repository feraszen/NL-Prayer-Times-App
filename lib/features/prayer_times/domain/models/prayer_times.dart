import 'prayer_time.dart';

class PrayerTimes {
  final PrayerTime fajr;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;

  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  List<PrayerTime> get allPrayers => [
        fajr,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];
}
