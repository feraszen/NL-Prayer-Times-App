import '../../domain/models/location_data.dart';
import '../providers/mock_location_provider.dart';

class LocationRepository {
  final MockLocationProvider provider;

  const LocationRepository({
    required this.provider,
  });

  LocationData getCurrentLocation() {
    return provider.getLocation();
  }
}
