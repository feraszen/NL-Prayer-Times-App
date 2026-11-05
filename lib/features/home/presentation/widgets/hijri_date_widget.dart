import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriDateWidget extends StatelessWidget {
  const HijriDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final hijriDate = HijriCalendar.now();

    return Text(
      '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
