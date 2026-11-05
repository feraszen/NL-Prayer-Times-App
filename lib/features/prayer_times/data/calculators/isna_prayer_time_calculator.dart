import 'package:adhan/adhan.dart' as adhan;

import '../../domain/calculators/prayer_time_calculator.dart';
import '../../domain/models/prayer_time.dart';
import '../../domain/models/prayer_times.dart';
import '../../domain/models/prayer_type.dart';

class ISNAPrayerTimeCalculator
    implements PrayerTimeCalculator {
  const ISNAPrayerTimeCalculator();

  @override
  PrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final coordinates = adhan.Coordinates(
      latitude,
      longitude,
    );

    final params =
        adhan.CalculationMethod.north_america
            .getParameters();

    params.madhab = adhan.Madhab.shafi;

    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents(
        date.year,
        date.month,
        date.day,
      ),
      params,
    );

    return PrayerTimes(
      fajr: PrayerTime(
        type: PrayerType.fajr,
        time: prayerTimes.fajr,
      ),
      dhuhr: PrayerTime(
        type: PrayerType.dhuhr,
        time: prayerTimes.dhuhr,
      ),
      asr: PrayerTime(
        type: PrayerType.asr,
        time: prayerTimes.asr,
      ),
      maghrib: PrayerTime(
        type: PrayerType.maghrib,
        time: prayerTimes.maghrib,
      ),
      isha: PrayerTime(
        type: PrayerType.isha,
        time: prayerTimes.isha,
      ),
    );
  }
}
