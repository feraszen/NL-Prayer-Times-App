import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class ReverseGeocodingService {
  const ReverseGeocodingService();

  Future<Placemark> getPlacemark({
    required double latitude,
    required double longitude,
  }) async {
    if (kIsWeb) {
      return Placemark(
        locality: 'St. John\'s',
        administrativeArea:
            'Newfoundland and Labrador',
        country: 'Canada',
      );
    }

    final placemarks =
        await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception(
        'No placemark found.',
      );
    }

    return placemarks.first;
  }
}

