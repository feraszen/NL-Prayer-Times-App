import 'dart:async';

import 'package:flutter/material.dart';

import '../../../prayer_times/domain/models/prayer_times.dart';
import '../../../prayer_times/domain/services/prayer_service.dart';

class PrayerCountdown extends StatefulWidget {
  final PrayerTimes prayerTimes;

  const PrayerCountdown({
    super.key,
    required this.prayerTimes,
  });

  @override
  State<PrayerCountdown> createState() =>
      _PrayerCountdownState();
}

class _PrayerCountdownState
    extends State<PrayerCountdown> {
  late Timer timer;

  Duration remaining = Duration.zero;

  final prayerService = const PrayerService();

  @override
  void initState() {
    super.initState();

    _updateCountdown();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    if (!mounted) return;

    setState(() {
      remaining = prayerService.getTimeRemaining(
        widget.prayerTimes,
        DateTime.now(),
      );
    });
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours =
        twoDigits(remaining.inHours);

    final minutes =
        twoDigits(
          remaining.inMinutes.remainder(60),
        );

    final seconds =
        twoDigits(
          remaining.inSeconds.remainder(60),
        );

    return Text(
      '$hours:$minutes:$seconds Remaining',
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1E5FBF),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
