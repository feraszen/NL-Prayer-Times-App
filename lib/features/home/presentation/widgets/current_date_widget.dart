import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentDateWidget extends StatelessWidget {
  const CurrentDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(now);

    return Text(
      formattedDate,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
      ),
    );
  }
}
