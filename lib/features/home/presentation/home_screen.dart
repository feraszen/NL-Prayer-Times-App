import 'package:flutter/material.dart';

import '../../prayer_times/data/providers/prayer_times_mock_provider.dart';
import '../../prayer_times/domain/extensions/prayer_time_extension.dart';
import '../../prayer_times/domain/extensions/prayer_type_extension.dart';
import '../../prayer_times/domain/services/prayer_service.dart';
import 'widgets/live_clock.dart';
import 'widgets/prayer_countdown.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prayerTimes =
        const PrayerTimesMockProvider().getPrayerTimes();

    final prayerService = const PrayerService();

    final nextPrayer = prayerService.getNextPrayer(
      prayerTimes,
      DateTime.now(),
    );

    final currentPrayer = prayerService.getCurrentPrayer(
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
              child: Stack(
                children: [
                  Positioned(
                    left: -30,
                    bottom: -40,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 160,
                      color:
                          Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.nightlight_round,
                      color: Colors.white24,
                      size: 90,
                    ),
                  ),
                  const Positioned(
                    top: 35,
                    right: 120,
                    child: Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.white24,
                    ),
                  ),
                  const Positioned(
                    top: 75,
                    right: 85,
                    child: Icon(
                      Icons.star,
                      size: 8,
                      color: Colors.white24,
                    ),
                  ),
                  const Positioned(
                    top: 55,
                    right: 150,
                    child: Icon(
                      Icons.star,
                      size: 6,
                      color: Colors.white24,
                    ),
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'St. John\'s, NL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const LiveClock(),
                      const SizedBox(height: 12),
                      const Text(
                        'Thursday, November 5, 2026',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '14 Jumada Al-Awwal 1448',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFD),
                    borderRadius:
                        BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8EEF7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
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
                      const PrayerCountdown(),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  16,
                ),
                children: [
                  PrayerCard(
                    icon: Icons.wb_sunny_outlined,
                    prayerName: prayerTimes.fajr.displayName,
                    prayerTime: prayerTimes.fajr.formattedTime,
                    highlighted:
                        currentPrayer.type ==
                        prayerTimes.fajr.type,
                  ),
                  PrayerCard(
                    icon: Icons.light_mode_outlined,
                    prayerName: prayerTimes.dhuhr.displayName,
                    prayerTime:
                        prayerTimes.dhuhr.formattedTime,
                    highlighted:
                        currentPrayer.type ==
                        prayerTimes.dhuhr.type,
                  ),
                  PrayerCard(
                    icon: Icons.star_outline,
                    prayerName: prayerTimes.asr.displayName,
                    prayerTime: prayerTimes.asr.formattedTime,
                    highlighted:
                        currentPrayer.type ==
                        prayerTimes.asr.type,
                  ),
                  PrayerCard(
                    icon: Icons.wb_twilight_outlined,
                    prayerName:
                        prayerTimes.maghrib.displayName,
                    prayerTime:
                        prayerTimes.maghrib.formattedTime,
                    highlighted:
                        currentPrayer.type ==
                        prayerTimes.maghrib.type,
                  ),
                  PrayerCard(
                    icon: Icons.nights_stay_outlined,
                    prayerName: prayerTimes.isha.displayName,
                    prayerTime:
                        prayerTimes.isha.formattedTime,
                    highlighted:
                        currentPrayer.type ==
                        prayerTimes.isha.type,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerCard extends StatelessWidget {
  final IconData icon;
  final String prayerName;
  final String prayerTime;
  final bool highlighted;

  const PrayerCard({
    super.key,
    required this.icon,
    required this.prayerName,
    required this.prayerTime,
    this.highlighted = false,
  });

  final Color goldColor = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlighted ? 4 : 1,
      color: highlighted
          ? goldColor
          : Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Icon(icon),
        title: Text(
          prayerName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          prayerTime,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
