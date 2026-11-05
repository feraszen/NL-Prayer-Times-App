import 'package:flutter/material.dart';

import '../../location/data/providers/gps_location_provider.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() =>
      _LocationTestScreenState();
}

class _LocationTestScreenState
    extends State<LocationTestScreen> {
  String result = 'Press the button to test GPS';

  Future<void> loadLocation() async {
    try {
      final position =
          await const GpsLocationProvider()
              .getCurrentPosition();

      if (!mounted) return;

      setState(() {
        result = '''
Latitude: ${position.latitude}

Longitude: ${position.longitude}

Accuracy: ${position.accuracy}

Altitude: ${position.altitude}

Speed: ${position.speed}
''';
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        result = '''
ERROR

$e

STACK TRACE

$stackTrace
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: loadLocation,
              child: const Text(
                'Get Current Location',
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  result,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
