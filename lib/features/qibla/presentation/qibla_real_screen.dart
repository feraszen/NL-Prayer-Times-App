import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

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

  double? latitude;
  double? longitude;

  double heading = 0;

  bool isLoading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    loadQibla();

    FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (!mounted) return;

        setState(() {
          heading = event.heading ?? 0;
        });
      },
    );
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

        latitude = position.latitude;
        longitude = position.longitude;

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
          title: const Text(
            'Qibla',
          ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 24,
          ),
          child: Column(
            children: [
              QiblaCompass(
                qiblaDirection: qiblaDirection!,
                heading: heading,
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

              const SizedBox(height: 8),

              Text(
                'Phone Heading: ${heading.toStringAsFixed(1)}°',
              ),

              const SizedBox(height: 32),

              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Qibla Direction',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${qiblaDirection!.toStringAsFixed(2)}°',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Color(
                              0xFF1E5FBF,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                      height: 28,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Latitude',
                        ),
                        Text(
                          latitude!
                              .toStringAsFixed(4),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Longitude',
                        ),
                        Text(
                          longitude!
                              .toStringAsFixed(4),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const Divider(
                      height: 28,
                    ),

                    const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text(
                          'Source',
                        ),
                        Text(
                          'GPS Location',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
