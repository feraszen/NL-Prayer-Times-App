import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/app_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/presentation/islamic_decoration.dart';
import '../../prayer_times/domain/models/prayer_type.dart';
import '../../prayer_times/domain/services/prayer_service.dart';
import 'widgets/home_prayer_loader.dart';
import 'widgets/prayer_countdown.dart';

class HomeScreenReal extends StatefulWidget {
  final VoidCallback? onSettings;
  const HomeScreenReal({super.key, this.onSettings});
  @override
  State<HomeScreenReal> createState() => _HomeScreenRealState();
}

class _HomeScreenRealState extends State<HomeScreenReal> {
  int _revision = 0;
  final _clock = ValueNotifier<DateTime>(DateTime.now());
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _clock.value = DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context);
    return HomePrayerLoader(
      key: ValueKey(_revision),
      locationBuilder: (times, location) => ValueListenableBuilder<DateTime>(
        valueListenable: _clock,
        builder: (context, now, _) {
          final current = const PrayerService().getCurrentPrayer(times, now);
          final next = const PrayerService().getNextPrayer(times, now);
          final hijri = HijriCalendar.fromDate(now);
          const months = [
            'محرم',
            'صفر',
            'ربيع الأول',
            'ربيع الآخر',
            'جمادى الأولى',
            'جمادى الآخرة',
            'رجب',
            'شعبان',
            'رمضان',
            'شوال',
            'ذو القعدة',
            'ذو الحجة',
          ];
          final prayers = [
            times.fajr,
            times.sunrise,
            times.dhuhr,
            times.asr,
            times.maghrib,
            times.isha,
          ];
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _revision++);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(38),
                        ),
                        child: IslamicBackdrop(
                          mosque: true,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                10,
                                22,
                                26,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _headerButton(
                                        CupertinoIcons.gear_alt,
                                        widget.onSettings,
                                        p.text('الإعدادات', 'Settings'),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'EEEE',
                                                p.language,
                                              ).format(now),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'd MMMM yyyy',
                                                p.language,
                                              ).format(now),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              p.arabic
                                                  ? '${hijri.hDay} ${months[hijri.hMonth - 1]} ${hijri.hYear} هـ'
                                                  : '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _headerButton(
                                        CupertinoIcons.bell,
                                        widget.onSettings,
                                        p.text('التنبيهات', 'Notifications'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Icon(
                                    CupertinoIcons.moon_stars_fill,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 10),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            p.formatTime(now).split(' ').first,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 66,
                                              height: 1.2,
                                              fontWeight: FontWeight.w600,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          if (p
                                              .formatTime(now)
                                              .contains(' ')) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              p.formatTime(now).split(' ').last,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.location_solid,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          location.city.isNotEmpty
                                              ? location.city
                                              : p.text(
                                                  'الموقع الحالي · GPS',
                                                  'Current location · GPS',
                                                ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  PrayerCountdown(prayerTimes: times),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.text('مواقيت الصلاة', 'Prayer times'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  p.text('اليوم', 'Today'),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < prayers.length; i++) ...[
                                    _prayerRow(
                                      p,
                                      prayers[i].type,
                                      prayers[i].time,
                                      current.type == prayers[i].type,
                                      next.type == prayers[i].type,
                                    ),
                                    if (i < prayers.length - 1)
                                      Divider(
                                        height: 1,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_shield,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    p.text(
                                      'ISNA · الشافعي · حسب موقعك',
                                      'ISNA · Shafi · Based on your location',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _headerButton(IconData icon, VoidCallback? onTap, String label) =>
      IconButton(
        onPressed: onTap,
        tooltip: label,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
        ),
        icon: Icon(icon, size: 21),
      );
  Widget _prayerRow(
    AppPreferences p,
    PrayerType type,
    DateTime time,
    bool current,
    bool next,
  ) {
    final sunrise = type == PrayerType.sunrise;
    const icons = [
      CupertinoIcons.moon_stars,
      CupertinoIcons.sunrise,
      CupertinoIcons.sun_max,
      CupertinoIcons.sun_haze,
      CupertinoIcons.sunset,
      CupertinoIcons.moon,
    ];
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: current
            ? AppColors.prayerHighlight.withValues(alpha: .16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: Row(
        children: [
          Icon(
            icons[type.index],
            size: 26,
            color:
                sunrise ||
                    type == PrayerType.dhuhr ||
                    type == PrayerType.maghrib
                ? AppColors.prayerHighlight
                : primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.prayerName(type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (current || next)
                  Text(
                    current
                        ? p.text('الصلاة الحالية', 'Current prayer')
                        : p.text('الصلاة القادمة', 'Next prayer'),
                    style: TextStyle(color: primary, fontSize: 10),
                  ),
              ],
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              p.formatTime(time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            child: sunrise
                ? null
                : Icon(
                    p.notifications && (p.alerts[type] ?? false)
                        ? CupertinoIcons.speaker_2
                        : CupertinoIcons.speaker_slash,
                    size: 17,
                    color: primary.withValues(alpha: .7),
                  ),
          ),
        ],
      ),
    );
  }
}
