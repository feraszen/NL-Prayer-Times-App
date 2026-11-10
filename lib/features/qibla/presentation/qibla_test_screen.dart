import 'package:flutter/material.dart';

import '../domain/services/qibla_service.dart';
import 'widgets/qibla_compass.dart';

class QiblaTestScreen extends StatelessWidget {
  const QiblaTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qiblaDirection =
        const QiblaService().calculateQiblaDirection(
      latitude: 47.5615,
      longitude: -52.7126,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Qibla Test',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            QiblaCompass(
              qiblaDirection: qiblaDirection,
              heading: 0,
            ),

            const SizedBox(height: 32),

            Text(
              'Qibla Direction: '
              '${qiblaDirection.toStringAsFixed(2)}°',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Test Mode (Heading = 0°)',
            ),
          ],
        ),
      ),
    );
  }
}
