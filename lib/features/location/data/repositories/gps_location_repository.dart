import '../../domain/models/location_data.dart';
import '../providers/gps_location_provider.dart';
import '../services/reverse_geocoding_service.dart';

class GpsLocationRepository {
  final GpsLocationProvider gpsProvider;
  final ReverseGeocodingService geocodingService;

  const GpsLocationRepository({
    required this.gpsProvider,
    required this.geocodingService,
  });

  Future<LocationData> getCurrentLocation() async {
    final position =
        await gpsProvider.getCurrentPosition();

    final placemark =
        await geocodingService.getPlacemark(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      country: placemark.country ?? '',
      region: placemark.administrativeArea ?? '',
      city: placemark.locality ?? '',
      timeZone: DateTime.now().timeZoneName,
    );
  }
}
