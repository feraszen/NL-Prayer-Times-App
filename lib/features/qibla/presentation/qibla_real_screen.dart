import 'package:flutter/material.dart';

import '../../location/data/providers/gps_location_provider.dart';

import '../domain/services/qibla_service.dart';
import 'widgets/qibla_compass.dart';

class QiblaRealScreen extends StatefulWidget {
  const QiblaRealScreen({super.key});

  @override
  State<QiblaRealScreen> createState() =>
      _QiblaRealScreenState();
}

class _QiblaRealScreenState
    extends State<QiblaRealScreen> {
  double? qiblaDirection;

  bool isLoading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadQibla();
  }

  Future<void> loadQibla() async {
    try {
      final position =
          await const GpsLocationProvider()
              .getCurrentPosition();

      final direction =
          const QiblaService()
              .calculateQiblaDirection(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        qiblaDirection = direction;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Qibla'),
        ),
        body: Center(
          child: Text(errorMessage),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Qibla Direction',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            QiblaCompass(
              direction: qiblaDirection!,
            ),

            const SizedBox(height: 24),

            Text(
              '${qiblaDirection!.toStringAsFixed(2)}°',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Direction to Kaaba',
            ),
          ],
        ),
      ),
    );
  }
}
