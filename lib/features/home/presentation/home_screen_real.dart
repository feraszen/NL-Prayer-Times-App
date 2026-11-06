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
        final prayerService = const PrayerService();

        final nextPrayer = prayerService.getNextPrayer(
          prayerTimes,
          DateTime.now(),
        );

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A3D91),
                        Color(0xFF1E5FBF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      LiveClock(),

                      SizedBox(height: 12),

                      CurrentDateWidget(),

                      SizedBox(height: 4),

                      HijriDateWidget(),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NEXT PRAYER',
                          style: TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          nextPrayer.type.displayName
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          nextPrayer.formattedTime,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 12),

                        PrayerCountdown(
                          prayerTimes: prayerTimes,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
