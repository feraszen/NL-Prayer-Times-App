import '../../domain/models/location_data.dart';

class MockLocationProvider {
  const MockLocationProvider();

  LocationData getLocation() {
    return const LocationData(
      latitude: 47.5615,
      longitude: -52.7126,
      country: 'Canada',
      region: 'Newfoundland and Labrador',
      city: 'St. John\'s',
      timeZone: 'America/St_Johns',
    );
  }
}
