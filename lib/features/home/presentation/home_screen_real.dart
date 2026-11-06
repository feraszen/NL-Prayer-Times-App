import 'package:flutter/material.dart';

import '../../prayer_times/domain/extensions/prayer_time_extension.dart';
import '../../prayer_times/domain/extensions/prayer_type_extension.dart';
import '../../prayer_times/domain/services/prayer_service.dart';

import 'widgets/current_date_widget.dart';
import 'widgets/hijri_date_widget.dart';
import 'widgets/home_prayer_loader.dart';
import 'widgets/live_clock.dart';
import 'widgets/prayer_countdown.dart';

class HomeScreenReal extends StatelessWidget {
  const HomeScreenReal({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final clockFontSize = isSmallScreen ? 36.0 : 48.0;
    final titleFontSize = isSmallScreen ? 22.0 : 30.0;
    final prayerFontSize = isSmallScreen ? 18.0 : 24.0;

    return HomePrayerLoader(
      builder: (prayerTimes) {
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
                    12,
                    20,
                    14,
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
                          color: Colors.white.withValues(
                            alpha: 0.05,
                          ),
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
                          Text(
                            'St. John\'s, NL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 12),

                          Transform.scale(
                            scale: clockFontSize / 48.0,
                            alignment: Alignment.centerLeft,
                            child: const LiveClock(),
                          ),

                          SizedBox(height: 12),

                          CurrentDateWidget(),

                          SizedBox(height: 4),

                          HijriDateWidget(),

                          SizedBox(height: 12),

                          SizedBox(
                            width: 80,
                            child: Divider(
                              color: Color(0xFFD4AF37),
                              thickness: 3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -15),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE8EEF7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
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
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextPrayer.type.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nextPrayer.formattedTime,
                                  style: TextStyle(
                                    fontSize: prayerFontSize,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                PrayerCountdown(
                                  prayerTimes: prayerTimes,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon: Icons.wb_sunny_outlined,
                                prayerName:
                                    prayerTimes.fajr.displayName,
                                prayerTime:
                                    prayerTimes.fajr.formattedTime,
                                highlighted:
                                    currentPrayer.type ==
                                    prayerTimes.fajr.type,
                              ),

                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon: Icons.wb_twilight,
                                prayerName:
                                    prayerTimes.sunrise.displayName,
                                prayerTime: prayerTimes
                                    .sunrise.formattedTime,
                              ),

                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon: Icons.light_mode_outlined,
                                prayerName:
                                    prayerTimes.dhuhr.displayName,
                                prayerTime:
                                    prayerTimes.dhuhr.formattedTime,
                                highlighted:
                                    currentPrayer.type ==
                                    prayerTimes.dhuhr.type,
                              ),

                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon: Icons.star_outline,
                                prayerName:
                                    prayerTimes.asr.displayName,
                                prayerTime:
                                    prayerTimes.asr.formattedTime,
                                highlighted:
                                    currentPrayer.type ==
                                    prayerTimes.asr.type,
                              ),

                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon:
                                    Icons.wb_twilight_outlined,
                                prayerName:
                                    prayerTimes.maghrib.displayName,
                                prayerTime: prayerTimes
                                    .maghrib.formattedTime,
                                highlighted:
                                    currentPrayer.type ==
                                    prayerTimes.maghrib.type,
                              ),

                              PrayerCard(
                                fontSize: prayerFontSize,
                                icon:
                                    Icons.nights_stay_outlined,
                                prayerName:
                                    prayerTimes.isha.displayName,
                                prayerTime:
                                    prayerTimes.isha.formattedTime,
                                highlighted:
                                    currentPrayer.type ==
                                    prayerTimes.isha.type,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: const [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Prayer Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Method',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'ISNA (North America)',
                                      style: TextStyle(
                                        color: Color(0xFF1E5FBF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Source'),
                                    Text(
                                      'GPS Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Calculation'),
                                    Text(
                                      'Adhan 2.0.0+1',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
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

class PrayerCard extends StatelessWidget {
  final IconData icon;
  final String prayerName;
  final String prayerTime;
  final bool highlighted;
  final double fontSize;

  const PrayerCard({
    super.key,
    required this.icon,
    required this.prayerName,
    required this.prayerTime,
    this.highlighted = false,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: highlighted
          ? const Color(0xFFD4AF37)
          : Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Icon(icon),
        title: Text(
          prayerName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          prayerTime,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
