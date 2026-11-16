import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/settings_service.dart';
import '../features/prayer_times/domain/models/prayer_type.dart';

class AppPreferences extends ChangeNotifier {
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AppThemeMode theme = AppThemeMode.system;
  TimeFormat timeFormat = TimeFormat.hour12;
  String language = 'ar';
  bool notifications = false;
  bool adhanEnabled = true;
  final Map<PrayerType, bool> alerts = {
    for (final p in PrayerType.values)
      if (p != PrayerType.sunrise) p: true,
  };
  final SettingsService storage = SettingsService();
  bool get arabic => language == 'ar';
  String text(String ar, String en) => arabic ? ar : en;
  String prayerName(PrayerType type) => text(
    ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'][type.index],
    ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'][type.index],
  );
  String formatTime(DateTime time) {
    final minutes = time.minute.toString().padLeft(2, '0');
    if (timeFormat == TimeFormat.hour24) {
      return '${time.hour.toString().padLeft(2, '0')}:$minutes';
    }
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:$minutes ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme = await storage.getThemeMode();
    timeFormat = await storage.getTimeFormat();
    language = prefs.getString('app_language') ?? 'ar';
    notifications = await storage.getNotificationsEnabled();
    adhanEnabled = prefs.getBool('adhan_enabled') ?? true;
    for (final p in alerts.keys) {
      alerts[p] = prefs.getBool('${p.name}_notification') ?? true;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setTheme(AppThemeMode value) async {
    theme = value;
    notifyListeners();
    await storage.saveThemeMode(value);
  }

  Future<void> setTimeFormat(TimeFormat value) async {
    timeFormat = value;
    notifyListeners();
    await storage.saveTimeFormat(value);
  }

  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'app_language',
      value,
    );
  }

  Future<void> setNotifications(bool value) async {
    notifications = value;
    notifyListeners();
    await storage.saveNotificationsEnabled(value);
  }

  Future<void> setAdhan(bool value) async {
    adhanEnabled = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      'adhan_enabled',
      value,
    );
  }

  Future<void> setAlert(PrayerType type, bool value) async {
    alerts[type] = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      '${type.name}_notification',
      value,
    );
  }
}

class AppScope extends InheritedNotifier<AppPreferences> {
  const AppScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
