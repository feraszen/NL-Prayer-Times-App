import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../app/app_preferences.dart';
import '../../../../core/presentation/islamic_decoration.dart';
import '../../../prayer_times/domain/models/prayer_times.dart';
import '../../../prayer_times/domain/services/prayer_service.dart';

class PrayerCountdown extends StatefulWidget {
  final PrayerTimes prayerTimes;
  const PrayerCountdown({super.key, required this.prayerTimes});
  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context);
    final now = DateTime.now();
    final next = const PrayerService().getNextPrayer(widget.prayerTimes, now);
    final remaining = const PrayerService().getTimeRemaining(
      widget.prayerTimes,
      now,
    );
    final seconds = remaining.inSeconds.clamp(0, 172800);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  p.text('الصلاة القادمة', 'Next prayer'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p.prayerName(next.type),
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _unit(seconds ~/ 3600, p.text('ساعة', 'hours')),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 18),
                          child: Text(':', style: TextStyle(fontSize: 24)),
                        ),
                        _unit(seconds ~/ 60 % 60, p.text('دقيقة', 'minutes')),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 18),
                          child: Text(':', style: TextStyle(fontSize: 24)),
                        ),
                        _unit(seconds % 60, p.text('ثانية', 'seconds')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 82,
              child: IslamicBackdrop(
                mosque: true,
                child: const Center(
                  child: Icon(
                    CupertinoIcons.moon_stars,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unit(int value, String label) => Column(
    children: [
      Text(
        value.toString().padLeft(2, '0'),
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
