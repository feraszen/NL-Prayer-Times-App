import '../models/prayer_type.dart';

extension PrayerTypeExtension on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';

      case PrayerType.sunrise:
        return 'Sunrise';

      case PrayerType.dhuhr:
        return 'Dhuhr';

      case PrayerType.asr:
        return 'Asr';

      case PrayerType.maghrib:
        return 'Maghrib';

      case PrayerType.isha:
        return 'Isha';
    }
  }
}
