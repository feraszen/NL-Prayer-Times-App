import '../../../../core/services/settings_service.dart';
import '../../../location/domain/models/location_data.dart';
import '../../domain/models/prayer_time_adjustments.dart';
import '../../domain/models/prayer_times.dart';
import '../../domain/models/prayer_type.dart';
import '../providers/alfalah_prayer_times_provider.dart';
import 'prayer_times_service.dart';

/// Shared loading path for the Home countdown and scheduled notifications.
class PrayerScheduleLoader {
  final PrayerTimesService localService;
  final AlFalahPrayerTimesProvider? mosqueProvider;
  const PrayerScheduleLoader({required this.localService, this.mosqueProvider});

  Future<PrayerTimes> load({
    required LocationData location,
    required DateTime date,
    required PrayerTimeSource source,
    required Map<PrayerType, int> adjustments,
    bool includeTomorrow = false,
  }) async {
    var base = source == PrayerTimeSource.alFalah
        ? await (mosqueProvider ?? AlFalahPrayerTimesProvider.instance)
              .getPrayerTimes(date: date)
        : localService.getPrayerTimes(
            latitude: location.latitude,
            longitude: location.longitude,
            date: date,
          );
    if (includeTomorrow) {
      final nextDate = DateTime(date.year, date.month, date.day + 1);
      final tomorrow = source == PrayerTimeSource.alFalah
          ? await (mosqueProvider ?? AlFalahPrayerTimesProvider.instance)
                .getPrayerTimes(date: nextDate)
          : localService.getPrayerTimes(
              latitude: location.latitude,
              longitude: location.longitude,
              date: nextDate,
            );
      base = PrayerTimes(
        fajr: base.fajr,
        sunrise: base.sunrise,
        dhuhr: base.dhuhr,
        asr: base.asr,
        maghrib: base.maghrib,
        isha: base.isha,
        nextDayFajr: tomorrow.fajr,
      );
    }
    return PrayerTimeAdjustments(adjustments).apply(base);
  }
}
