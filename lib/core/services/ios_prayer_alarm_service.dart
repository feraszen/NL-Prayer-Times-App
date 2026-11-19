import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional AlarmKit alerts. Regular iOS notifications remain the default.
class IOSPrayerAlarmService {
  static const channel = MethodChannel('nl_prayer_times/ios_alarms');
  static const enabledKey = 'ios_prayer_alarms_enabled';

  Future<Map<String, dynamic>> status() async =>
      await channel.invokeMapMethod<String, dynamic>('status') ??
      {'available': false, 'authorized': false};

  Future<bool> requestPermission() async =>
      await channel.invokeMethod<bool>('requestPermission') ?? false;

  Future<bool> enabled() async =>
      (await SharedPreferences.getInstance()).getBool(enabledKey) ?? false;

  Future<void> setEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(enabledKey, value);

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime time,
    required String sound,
  }) async {
    await channel.invokeMethod<void>('schedule', {
      'id': id,
      'title': title,
      'timestamp': time.millisecondsSinceEpoch / 1000,
      'sound': sound,
    });
  }

  Future<void> cancelPrayerAlarms() =>
      channel.invokeMethod<void>('cancelPrayerAlarms');
}
