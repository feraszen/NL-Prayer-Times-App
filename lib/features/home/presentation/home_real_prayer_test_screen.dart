import 'package:flutter/material.dart';

import '../../prayer_times/domain/extensions/prayer_time_extension.dart';
import 'widgets/home_prayer_loader.dart';

class HomeRealPrayerTestScreen extends StatelessWidget {
  const HomeRealPrayerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Real Prayer Times Test',
        ),
      ),
      body: HomePrayerLoader(
        builder: (prayerTimes) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'ISNA Prayer Times',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Fajr: ${prayerTimes.fajr.formattedTime}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Dhuhr: ${prayerTimes.dhuhr.formattedTime}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Asr: ${prayerTimes.asr.formattedTime}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Maghrib: ${prayerTimes.maghrib.formattedTime}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Isha: ${prayerTimes.isha.formattedTime}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
