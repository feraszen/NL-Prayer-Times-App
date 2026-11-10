import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/prayer_notification_scheduler.dart';
import '../../../../core/services/settings_service.dart';

import '../../../location/data/providers/gps_location_provider.dart';
import '../../../location/domain/models/location_data.dart';

import '../../../prayer_times/data/providers/real_prayer_times_provider.dart';
import '../../../prayer_times/data/services/prayer_times_service.dart';

import '../../../prayer_times/domain/models/prayer_times.dart';

class HomePrayerLoader extends StatefulWidget {
  final Widget Function(
    PrayerTimes prayerTimes,
  ) builder;

  const HomePrayerLoader({
    super.key,
    required this.builder,
  });

  @override
  State<HomePrayerLoader> createState() =>
      _HomePrayerLoaderState();
}

class _HomePrayerLoaderState
    extends State<HomePrayerLoader> {
  PrayerTimes? prayerTimes;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPrayerTimes();
  }

  Future<void> loadPrayerTimes() async {
    try {
      final position =
          await const GpsLocationProvider()
              .getCurrentPosition();

      final service = PrayerTimesService(
        provider: const RealPrayerTimesProvider(),
      );

      final result = service.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!kIsWeb) {
        final scheduler =
            PrayerNotificationScheduler(
          prayerTimesService: service,
          settingsService: SettingsService(),
        );

        await scheduler.scheduleNotifications(
          location: LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            country: '',
            region: '',
            city: '',
            timeZone:
                DateTime.now().timeZoneName,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        prayerTimes = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            textAlign:
                TextAlign.center,
          ),
        ),
      );
    }

    if (prayerTimes == null) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return widget.builder(
      prayerTimes!,
    );
  }
}
