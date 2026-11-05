import '../models/location_data.dart';

extension LocationDataExtension on LocationData {
  String get shortDisplayName {
    return '$city, NL';
  }

  String get fullDisplayName {
    return '$city, $region';
  }
}
