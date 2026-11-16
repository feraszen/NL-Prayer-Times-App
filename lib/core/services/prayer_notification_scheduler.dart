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

  static Future<void> _pendingUpdate = Future.value();

  Future<void> scheduleNotifications({required LocationData location}) {
    final update = _pendingUpdate.then((_) => _schedule(location));
    // Serialize Home/resume and Settings updates while allowing retries on errors.
    _pendingUpdate = update.catchError((Object error) {});
    return update;
  }

  Future<void> _schedule(LocationData location) async {
    if (!NotificationService.isSupported) return;
    await NotificationService.instance.cancelPrayerNotifications();
    if (!await settingsService.getNotificationsEnabled()) return;

    final fajrEnabled = await settingsService.getFajrNotification();

    final dhuhrEnabled = await settingsService.getDhuhrNotification();

    final asrEnabled = await settingsService.getAsrNotification();

    final maghribEnabled = await settingsService.getMaghribNotification();

    final ishaEnabled = await settingsService.getIshaNotification();

    final now = DateTime.now();
    for (var day = 0; day < 7; day++) {
      final prayerTimes = prayerTimesService.getPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: DateTime(now.year, now.month, now.day + day),
      );
      await NotificationService.instance.scheduleDailyPrayerNotifications(
        prayerTimes: prayerTimes,
        dayOffset: day,
        fajrEnabled: fajrEnabled,
        dhuhrEnabled: dhuhrEnabled,
        asrEnabled: asrEnabled,
        maghribEnabled: maghribEnabled,
        ishaEnabled: ishaEnabled,
      );
    }
  }
}
