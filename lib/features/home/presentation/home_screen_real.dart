import 'package:flutter/material.dart';

import '../../prayer_times/domain/extensions/prayer_type_extension.dart';
import '../../prayer_times/domain/extensions/prayer_time_extension.dart';
import '../../prayer_times/domain/services/prayer_service.dart';

import 'widgets/home_prayer_loader.dart';
import 'widgets/live_clock.dart';
import 'widgets/current_date_widget.dart';
import 'widgets/hijri_date_widget.dart';
import 'widgets/prayer_countdown.dart';

class HomeScreenReal extends StatelessWidget {
  const HomeScreenReal({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePrayerLoader(
      builder: (prayerTimes) {
        final prayerService =
            const PrayerService();

        final nextPrayer =
            prayerService.getNextPrayer(
          prayerTimes,
          DateTime.now(),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'HomeScreenReal',
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const LiveClock(),

                  const SizedBox(height: 16),

                  const CurrentDateWidget(),

                  const SizedBox(height: 8),

                  const HijriDateWidget(),

                  const SizedBox(height: 32),

                  Text(
                    'Next Prayer: ${nextPrayer.type.displayName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Time: ${nextPrayer.formattedTime}',
                  ),

                  const SizedBox(height: 16),

                  PrayerCountdown(
                    prayerTimes: prayerTimes,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
