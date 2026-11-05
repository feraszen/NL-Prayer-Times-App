import 'package:flutter/material.dart';

import '../../../location/data/providers/mock_location_provider.dart';
import '../../../location/data/repositories/location_repository.dart';

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

  @override
  void initState() {
    super.initState();
    loadPrayerTimes();
  }

  Future<void> loadPrayerTimes() async {
    final locationRepository = LocationRepository(
      provider: const MockLocationProvider(),
    );

    final location =
        locationRepository.getCurrentLocation();

    final service = PrayerTimesService(
      provider: const RealPrayerTimesProvider(),
    );

    final result = service.getPrayerTimes(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (!mounted) return;

    setState(() {
      prayerTimes = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (prayerTimes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return widget.builder(
      prayerTimes!,
    );
  }
}
