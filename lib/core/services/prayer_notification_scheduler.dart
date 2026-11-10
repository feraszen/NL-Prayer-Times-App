import '../../features/location/domain/models/location_data.dart';
import '../../features/prayer_times/data/services/prayer_times_service.dart';

import 'notification_service.dart';
import 'settings_service.dart';

class PrayerNotificationScheduler {
  final PrayerTimesService prayerTimesService;

  final SettingsService settingsService;

  const PrayerNotificationScheduler({
    required this.prayerTimesService,
    required this.settingsService,
  });

  Future<void> scheduleNotifications({
    required LocationData location,
  }) async {
    final prayerTimes =
        prayerTimesService.getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    final fajrEnabled =
        await settingsService
            .getFajrNotification();

    final dhuhrEnabled =
        await settingsService
            .getDhuhrNotification();

    final asrEnabled =
        await settingsService
            .getAsrNotification();

    final maghribEnabled =
        await settingsService
            .getMaghribNotification();

    final ishaEnabled =
        await settingsService
            .getIshaNotification();

    await NotificationService.instance
        .scheduleDailyPrayerNotifications(
      prayerTimes: prayerTimes,
      fajrEnabled: fajrEnabled,
      dhuhrEnabled: dhuhrEnabled,
      asrEnabled: asrEnabled,
      maghribEnabled: maghribEnabled,
      ishaEnabled: ishaEnabled,
    );
  }
}
