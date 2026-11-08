import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/constants/app_sizes.dart';

class HijriDateWidget extends StatelessWidget {
  const HijriDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSizes.scale(context);

    final hijriDate = HijriCalendar.now();

    return Text(
      '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 13 * s,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
