import '../models/prayer_time.dart';
import 'prayer_type_extension.dart';

extension PrayerTimeExtension on PrayerTime {
  String get displayName {
    return type.displayName;
  }

  String get formattedTime {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
