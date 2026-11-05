import 'dart:math';

import 'package:flutter/material.dart';

class QiblaCompass extends StatelessWidget {
  final double direction;

  const QiblaCompass({
    super.key,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 3,
                color: Colors.blue,
              ),
            ),
          ),
          Transform.rotate(
            angle: direction * pi / 180,
            child: const Icon(
              Icons.navigation,
              size: 120,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
