import 'package:flutter/material.dart';

import '../data/calculators/isna_prayer_time_calculator.dart';
import '../domain/extensions/prayer_time_extension.dart';

class PrayerCalculatorTestScreen extends StatelessWidget {
  const PrayerCalculatorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calculator =
        const ISNAPrayerTimeCalculator();

    final prayerTimes = calculator.calculate(
      latitude: 47.5615,
      longitude: -52.7126,
      date: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prayer Calculator Test',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'St. John\'s, NL',
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
      ),
    );
  }
}
