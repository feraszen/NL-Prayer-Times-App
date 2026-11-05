import '../calculators/isna_prayer_time_calculator.dart';
import '../../domain/models/prayer_times.dart';

class RealPrayerTimesProvider {
  const RealPrayerTimesProvider();

  PrayerTimes getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    return const ISNAPrayerTimeCalculator().calculate(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );
  }
}
