import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

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
    final s = AppSizes.scale(context);

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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 750;

            final width = constraints.maxWidth;
            final isPhone = width < 600;
            final isTablet = width >= 600 && width < 1024;
            final isDesktop = width >= 1024;

            final contentMaxWidth = isDesktop
                ? 900.0
                : isTablet
                    ? 700.0
                    : double.infinity;


            final titleSize =
                (isPhone ? (isCompact ? 14.0 : 18.0) : 20.0) * s;
            final prayerTextSize = (isCompact ? 11.0 : 14.0) * s;
            final iconSize = (isCompact ? 14.0 : 18.0) * s;
            final cardPadding = (isCompact ? 8.0 : 12.0) * s;
            final headerPadding = (isCompact ? 8.0 : 16.0) * s;
            final headerSpacing = (isCompact ? 6.0 : 12.0) * s;

            return Scaffold(
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 750;
                    final headerHeight = isCompact ? 180.0 : 240.0;
                    final prayerTileHeight = isCompact ? 36.0 : 42.0;
                    final horizontalPadding = constraints.maxWidth < 400 ? 12.0 : 24.0;

                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: SizedBox(
                            width: constraints.maxWidth,
                          child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: headerHeight),
                      padding: EdgeInsets.fromLTRB(
                        headerPadding,
                        headerPadding,
                        headerPadding,
                        headerPadding,
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

                              SizedBox(
                                height: headerSpacing,
                              ),

                              DefaultTextStyle.merge(
                                style: TextStyle(fontSize: isCompact ? 26.0 : 34.0),
                                child: const LiveClock(),
                              ),

                              SizedBox(
                                height: headerSpacing,
                              ),

                              DefaultTextStyle.merge(
                                style: TextStyle(fontSize: isCompact ? 10.0 : 13.0),
                                child: const CurrentDateWidget(),
                              ),

                              SizedBox(height: 4),

                              DefaultTextStyle.merge(
                                style: TextStyle(fontSize: isCompact ? 10.0 : 13.0),
                                child: const HijriDateWidget(),
                              ),

                              SizedBox(
                                height: headerSpacing,
                              ),

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

                    Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding, 0, horizontalPadding, 12,
                        ),
                        child: Column(
                  mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -15),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(
                                  cardPadding,
                                ),
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
                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'NEXT PRAYER',
                                      style: TextStyle(
                                        fontSize: titleSize,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${nextPrayer.type.displayName.toUpperCase()} - '
                                      '${nextPrayer.formattedTime}',
                                      style: TextStyle(
                                        fontSize: prayerTextSize + 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PrayerCountdown(
                                      prayerTimes: prayerTimes,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 6,
                              ),
                              child: Text(
                                'Prayer Times',
                                style: TextStyle(
                                  fontSize: titleSize,
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
                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PrayerTile(
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
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
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
                                        icon: Icons.wb_twilight,
                                      prayerName:
                                          prayerTimes.sunrise.displayName,
                                      prayerTime: prayerTimes
                                          .sunrise.formattedTime,
                                    ),
                                    const Divider(height: 1),
                                    PrayerTile(
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
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
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
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
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
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
                                      prayerTextSize: prayerTextSize,
                                      iconSize: iconSize,
                                      isCompact: isCompact,
                                      minHeight: prayerTileHeight,
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
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Prayer Information',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Method',
                                          style: TextStyle(
                                            fontSize: prayerTextSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            'ISNA (North America)',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: prayerTextSize,
                                              color: Color(0xFF1E5FBF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
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
  final double prayerTextSize;
  final double iconSize;
  final bool isCompact;
  final double minHeight;

  const PrayerTile({
    super.key,
    required this.icon,
    required this.prayerName,
    required this.prayerTime,
    this.highlighted = false,
    required this.prayerTextSize,
    required this.iconSize,
    this.isCompact = false,
    this.minHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      color: highlighted
          ? const Color(0xFFD4AF37)
          : Colors.white,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(
          vertical: -4,
        ),
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        leading: Icon(
          icon,
          size: iconSize,
          color: highlighted ? Colors.black : null,
        ),
        title: Text(
          prayerName,
          style: TextStyle(
            fontSize: prayerTextSize,
            color: highlighted ? Colors.black : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          prayerTime,
          style: TextStyle(
            fontSize: prayerTextSize,
            color: highlighted ? Colors.black : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
