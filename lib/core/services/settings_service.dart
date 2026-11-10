import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

enum TimeFormat {
  hour12,
  hour24,
}

class SettingsService {
  static const String _themeKey =
      'theme_mode';

  static const String _timeFormatKey =
      'time_format';

  static const String _notificationsKey =
      'notifications_enabled';

  static const String _fajrKey =
      'fajr_notification';

  static const String _dhuhrKey =
      'dhuhr_notification';

  static const String _asrKey =
      'asr_notification';

  static const String _maghribKey =
      'maghrib_notification';

  static const String _ishaKey =
      'isha_notification';

  static const String _notificationSoundPathKey =
      'notification_sound_path';

  Future<void> saveThemeMode(
    AppThemeMode mode,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      mode.name,
    );
  }

  Future<AppThemeMode> getThemeMode() async {
    final prefs =
        await SharedPreferences.getInstance();

    final value =
        prefs.getString(_themeKey);

    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> saveTimeFormat(
    TimeFormat format,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _timeFormatKey,
      format.name,
    );
  }

  Future<TimeFormat> getTimeFormat() async {
    final prefs =
        await SharedPreferences.getInstance();

    final value =
        prefs.getString(_timeFormatKey);

    return TimeFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeFormat.hour12,
    );
  }

  Future<void> saveNotificationsEnabled(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _notificationsKey,
      enabled,
    );
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _notificationsKey,
        ) ??
        false;
  }

  Future<void> saveFajrNotification(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _fajrKey,
      enabled,
    );
  }

  Future<bool> getFajrNotification() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _fajrKey,
        ) ??
        true;
  }

  Future<void> saveDhuhrNotification(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _dhuhrKey,
      enabled,
    );
  }

  Future<bool> getDhuhrNotification() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _dhuhrKey,
        ) ??
        true;
  }

  Future<void> saveAsrNotification(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _asrKey,
      enabled,
    );
  }

  Future<bool> getAsrNotification() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _asrKey,
        ) ??
        true;
  }

  Future<void> saveMaghribNotification(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _maghribKey,
      enabled,
    );
  }

  Future<bool> getMaghribNotification() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _maghribKey,
        ) ??
        true;
  }

  Future<void> saveIshaNotification(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _ishaKey,
      enabled,
    );
  }

  Future<bool> getIshaNotification() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _ishaKey,
        ) ??
        true;
  }

  Future<void> saveNotificationSoundPath(
    String path,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _notificationSoundPathKey,
      path,
    );
  }

  Future<String?> getNotificationSoundPath()
      async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _notificationSoundPathKey,
    );
  }

  Future<void> clearNotificationSoundPath()
      async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _notificationSoundPathKey,
    );
  }
}
