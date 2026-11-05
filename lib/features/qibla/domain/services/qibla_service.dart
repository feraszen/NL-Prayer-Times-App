import 'dart:math';

class QiblaService {
  static const double kaabaLatitude =
      21.4225;

  static const double kaabaLongitude =
      39.8262;

  const QiblaService();

  double calculateQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _degreesToRadians(
      latitude,
    );

    final lon1 = _degreesToRadians(
      longitude,
    );

    final lat2 = _degreesToRadians(
      kaabaLatitude,
    );

    final lon2 = _degreesToRadians(
      kaabaLongitude,
    );

    final deltaLon = lon2 - lon1;

    final y = sin(deltaLon);

    final x =
        cos(lat1) * tan(lat2) -
        sin(lat1) * cos(deltaLon);

    final bearing =
        atan2(y, x);

    return (_radiansToDegrees(
          bearing,
        ) +
            360) %
        360;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * pi / 180;
  }

  double _radiansToDegrees(
    double radians,
  ) {
    return radians * 180 / pi;
  }
}
