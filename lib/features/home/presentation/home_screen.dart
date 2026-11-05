import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                      color: Colors.white.withValues(alpha: 0.05),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'St. John\'s, NL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '12:45 PM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth < 400 ? 38 : 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(20),
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8EEF7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'NEXT PRAYER',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ASR',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '03:48 PM',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '02:15:30 Remaining',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E5FBF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                children: const [
                  PrayerCard(
                    icon: Icons.wb_sunny_outlined,
                    prayerName: 'Fajr',
                    prayerTime: '05:12 AM',
                  ),
                  PrayerCard(
                    icon: Icons.light_mode_outlined,
                    prayerName: 'Dhuhr',
                    prayerTime: '12:34 PM',
                  ),
                  PrayerCard(
                    icon: Icons.star_outline,
                    prayerName: 'Asr',
                    prayerTime: '03:48 PM',
                    highlighted: true,
                  ),
                  PrayerCard(
                    icon: Icons.wb_twilight_outlined,
                    prayerName: 'Maghrib',
                    prayerTime: '05:42 PM',
                  ),
                  PrayerCard(
                    icon: Icons.nights_stay_outlined,
                    prayerName: 'Isha',
                    prayerTime: '07:16 PM',
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlighted ? 4 : 1,
      color: highlighted
          ? const Color(0xFFD4AF37)
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
