class LocationData {
  final double latitude;
  final double longitude;

  final String country;
  final String region;
  final String city;

  final String timeZone;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.region,
    required this.city,
    required this.timeZone,
  });

  String get displayName {
    return '$city, $region';
  }
}
