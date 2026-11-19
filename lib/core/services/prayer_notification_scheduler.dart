import '../../features/location/domain/models/location_data.dart';
import '../../features/prayer_times/data/providers/alfalah_prayer_times_provider.dart';
import '../../features/prayer_times/data/services/prayer_schedule_loader.dart';
import '../../features/prayer_times/data/services/prayer_times_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class PrayerNotificationScheduler {
  final PrayerTimesService prayerTimesService;
  final SettingsService settingsService;
  final AlFalahPrayerTimesProvider? mosqueProvider;
  const PrayerNotificationScheduler({
    required this.prayerTimesService,
    required this.settingsService,
    this.mosqueProvider,
  });
  static Future<void> _pendingUpdate = Future.value();
  Future<void> scheduleNotifications({required LocationData location}) {
    final update = _pendingUpdate.then((_) async {
      try {
        await _schedule(location);
        NotificationService.instance.reportScheduled();
      } catch (error) {
        NotificationService.instance.reportSchedulingError(error);
        rethrow;
      }
    });
    _pendingUpdate = update.catchError((Object error) {});
    return update;
  }

  Future<void> _schedule(LocationData location) async {
    if (!NotificationService.isSupported) return;
    if (!await settingsService.getNotificationsEnabled()) {
      await NotificationService.instance.cancelPrayerNotifications();
      return;
    }
    await NotificationService.instance.prepareScheduling();
    final sunrise = await settingsService.getSunriseNotification();
    final fajr = await settingsService.getFajrNotification();
    final dhuhr = await settingsService.getDhuhrNotification();
    final asr = await settingsService.getAsrNotification();
    final maghrib = await settingsService.getMaghribNotification();
    final isha = await settingsService.getIshaNotification();
    final source = await settingsService.getPrayerTimeSource();
    final adjustments = await settingsService.getPrayerAdjustments();
    final now = source == PrayerTimeSource.alFalah
        ? AlFalahPrayerTimesProvider.now
        : DateTime.now();
    final loader = PrayerScheduleLoader(
      localService: prayerTimesService,
      mosqueProvider: mosqueProvider,
    );
    // Resolve the whole horizon first. Offline/malformed mosque data must not
    // erase a still valid set of scheduled notifications or substitute GPS times.
    final days = await Future.wait(
      List.generate(
        7,
        (day) => loader.load(
          location: location,
          date: DateTime(now.year, now.month, now.day + day),
          source: source,
          adjustments: adjustments,
        ),
      ),
    );
    if (!await settingsService.getNotificationsEnabled()) return;
    if (source != await settingsService.getPrayerTimeSource()) return;
    await NotificationService.instance.cancelPrayerNotifications();
    for (var day = 0; day < days.length; day++) {
      await NotificationService.instance.scheduleDailyPrayerNotifications(
        prayerTimes: days[day],
        dayOffset: day,
        sunriseEnabled: sunrise,
        fajrEnabled: fajr,
        dhuhrEnabled: dhuhr,
        asrEnabled: asr,
        maghribEnabled: maghrib,
        ishaEnabled: isha,
      );
    }
  }
}
