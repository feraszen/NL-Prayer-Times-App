import '../providers/real_prayer_times_provider.dart';
import '../../domain/models/prayer_times.dart';

class PrayerTimesService {
  final RealPrayerTimesProvider provider;

  const PrayerTimesService({
    required this.provider,
  });

  PrayerTimes getPrayerTimes({
    required double latitude,
    required double longitude,
  }) {
    return provider.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
    );
  }
}
