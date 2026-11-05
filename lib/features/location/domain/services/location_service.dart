import '../models/location_data.dart';

abstract class LocationService {
  Future<LocationData> getCurrentLocation();
}
