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
    const clockFontSize = 28.0;
    const titleFontSize = 16.0;

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
                    12,
                    8,
                    12,
                    8,
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
                              fontSize: 12,
                            ),
                          ),

                          SizedBox(height: 12),

                          SizedBox(
                            height: clockFontSize * 1.4,
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.contain,
                              child: SizedBox(
                                height: 48.0 * 1.4,
                                child: const LiveClock(),
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          SizedBox(
                            height: 12.0 * 1.4,
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.contain,
                              child: SizedBox(
                                height: 18.0 * 1.4,
                                child: const CurrentDateWidget(),
                              ),
                            ),
                          ),

                          SizedBox(height: 4),

                          SizedBox(
                            height: 12.0 * 1.4,
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.contain,
                              child: SizedBox(
                                height: 18.0 * 1.4,
                                child: const HijriDateWidget(),
                              ),
                            ),
                          ),

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
                            padding: const EdgeInsets.all(12),
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
                                    fontSize: 18,
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
                                    fontSize: 13,
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

                        const Padding(
                          padding: EdgeInsets.only(
                            left: 4,
                            bottom: 12,
                          ),
                          child: Text(
                            'Prayer Times',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              children: [
                                PrayerTile(
                                    icon: Icons.wb_sunny_outlined,
                                  prayerName:
                                      prayerTimes.fajr.displayName,
                                  prayerTime:
                                      prayerTimes.fajr.formattedTime,
                                  highlighted:
                                      currentPrayer.type ==
                                      prayerTimes.fajr.type,
                                ),
                                const Divider(height: 1),
                                PrayerTile(
                                    icon: Icons.wb_twilight,
                                  prayerName:
                                      prayerTimes.sunrise.displayName,
                                  prayerTime: prayerTimes
                                      .sunrise.formattedTime,
                                ),
                                const Divider(height: 1),
                                PrayerTile(
                                    icon: Icons.light_mode_outlined,
                                  prayerName:
                                      prayerTimes.dhuhr.displayName,
                                  prayerTime:
                                      prayerTimes.dhuhr.formattedTime,
                                  highlighted:
                                      currentPrayer.type ==
                                      prayerTimes.dhuhr.type,
                                ),
                                const Divider(height: 1),
                                PrayerTile(
                                    icon: Icons.star_outline,
                                  prayerName:
                                      prayerTimes.asr.displayName,
                                  prayerTime:
                                      prayerTimes.asr.formattedTime,
                                  highlighted:
                                      currentPrayer.type ==
                                      prayerTimes.asr.type,
                                ),
                                const Divider(height: 1),
                                PrayerTile(
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
                                const Divider(height: 1),
                                PrayerTile(
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
                                      fontSize: 13,
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

class PrayerTile extends StatelessWidget {
  final IconData icon;
  final String prayerName;
  final String prayerTime;
  final bool highlighted;

  const PrayerTile({
    super.key,
    required this.icon,
    required this.prayerName,
    required this.prayerTime,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: highlighted
                ? const Color(0xFFD4AF37)
                : Colors.transparent,
            width: 5,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 0,
        ),
        leading: Icon(
          icon,
          size: 22,
        ),
        title: Text(
          prayerName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          prayerTime,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
