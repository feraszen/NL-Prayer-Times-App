import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';

class CurrentDateWidget extends StatelessWidget {
  const CurrentDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSizes.scale(context);

    final now = DateTime.now();

    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(now);

    return Text(
      formattedDate,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 12 * s,
      ),
    );
  }
}
