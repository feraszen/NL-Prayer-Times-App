import 'prayer_time.dart';

class PrayerTimes {
  final PrayerTime fajr;
  final PrayerTime sunrise;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;
  final PrayerTime? nextDayFajr;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.nextDayFajr,
  });

  List<PrayerTime> get allPrayers => [fajr, dhuhr, asr, maghrib, isha];
}
