import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TestLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 47.5615,
    longitude: -52.7126,
    timestamp: DateTime.now(),
    accuracy: 3,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class TestGeocoding extends GeocodingPlatform {
  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async => [
    Placemark(
      locality: "St. John's",
      administrativeArea: 'NL',
      country: 'Canada',
    ),
  ];
}
