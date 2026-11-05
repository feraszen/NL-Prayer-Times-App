import 'dart:async';

import 'package:flutter/material.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final hour = currentTime.hour > 12
        ? currentTime.hour - 12
        : currentTime.hour == 0
            ? 12
            : currentTime.hour;

    final minute = twoDigits(currentTime.minute);

    final period =
        currentTime.hour >= 12 ? 'PM' : 'AM';

    return Text(
      '$hour:$minute $period',
      style: TextStyle(
        color: Colors.white,
        fontSize:
            MediaQuery.of(context).size.width < 400
                ? 38
                : 50,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
