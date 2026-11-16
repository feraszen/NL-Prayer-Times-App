import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/prayer_notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/settings_service.dart';

import '../../../location/data/providers/gps_location_provider.dart';
import '../../../location/data/services/reverse_geocoding_service.dart';
import '../../../location/domain/models/location_data.dart';

import '../../../prayer_times/data/providers/real_prayer_times_provider.dart';
import '../../../prayer_times/data/services/prayer_times_service.dart';

import '../../../prayer_times/domain/models/prayer_times.dart';

class HomePrayerLoader extends StatefulWidget {
  final Widget Function(PrayerTimes prayerTimes)? builder;
  final Widget Function(PrayerTimes prayerTimes, LocationData location)?
  locationBuilder;

  const HomePrayerLoader({super.key, this.builder, this.locationBuilder})
    : assert(builder != null || locationBuilder != null);

  @override
  State<HomePrayerLoader> createState() => _HomePrayerLoaderState();
}

class _HomePrayerLoaderState extends State<HomePrayerLoader>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  DateTime? _loadedDate;
  bool _loading = false;
  PrayerTimes? prayerTimes;
  LocationData? location;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadPrayerTimes();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      if (_loadedDate?.day != now.day ||
          _loadedDate?.month != now.month ||
          _loadedDate?.year != now.year) {
        loadPrayerTimes();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) loadPrayerTimes();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadPrayerTimes() async {
    if (_loading) return;
    _loading = true;
    try {
      final position = await const GpsLocationProvider().getCurrentPosition();

      var city = '';
      var region = '';
      try {
        final place = await const ReverseGeocodingService()
            .getPlacemark(
              latitude: position.latitude,
              longitude: position.longitude,
            )
            .timeout(const Duration(seconds: 3));
        city = place.locality ?? '';
        region = place.administrativeArea ?? '';
      } catch (_) {
        /* Coordinates and prayer times still work offline. */
      }
      final resolvedLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        country: '',
        region: region,
        city: city,
        timeZone: DateTime.now().timeZoneName,
      );
      final service = PrayerTimesService(
        provider: const RealPrayerTimesProvider(),
      );

      final result = service.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (NotificationService.isSupported) {
        try {
          final scheduler = PrayerNotificationScheduler(
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
              timeZone: DateTime.now().timeZoneName,
            ),
          );
        } catch (error) {
          debugPrint('Prayer notification scheduling failed: $error');
        }
      }

      if (!mounted) return;

      setState(() {
        prayerTimes = result;
        location = resolvedLocation;
        _loadedDate = DateTime.now();
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (prayerTimes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return widget.locationBuilder?.call(prayerTimes!, location!) ??
        widget.builder!(prayerTimes!);
  }
}
