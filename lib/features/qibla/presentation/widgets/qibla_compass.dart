import 'dart:math';

import 'package:flutter/material.dart';

class QiblaCompass extends StatelessWidget {
  final double qiblaDirection;

  final double heading;

  const QiblaCompass({
    super.key,
    required this.qiblaDirection,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    final rotation =
        (qiblaDirection - heading) *
            pi /
            180;

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 3,
                color: const Color(
                  0xFF1E5FBF,
                ),
              ),
            ),
          ),

          const Positioned(
            top: 8,
            child: Text(
              'N',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Positioned(
            bottom: 8,
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Positioned(
            left: 8,
            child: Text(
              'W',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Positioned(
            right: 8,
            child: Text(
              'E',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Icon(
            Icons.mosque,
            size: 120,
            color: Color(
              0xFFD4AF37,
            ),
          ),

          Transform.rotate(
            angle: rotation,
            child: const Icon(
              Icons.navigation,
              size: 60,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
