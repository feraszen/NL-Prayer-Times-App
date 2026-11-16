import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Imported audio is copied into durable Android storage, not picker cache.
class CustomAdhanService {
  static const channel = MethodChannel('nl_prayer_times/custom_adhan');
  static const uriKey = 'custom_adhan_uri';
  static const tokenKey = 'custom_adhan_token';
  static const pathKey = 'custom_adhan_path';
  static const nameKey = 'custom_adhan_name';

  Future<Map<String, String>> importFile(String path, String name) async {
    final result = await channel.invokeMapMethod<String, String>(
      'importAudio',
      {'path': path, 'name': name},
    );
    if (result == null ||
        result['uri'] == null ||
        result['token'] == null ||
        result['path'] == null) {
      throw StateError('Unable to import audio');
    }
    return {...result, 'name': name};
  }

  Future<Map<String, String>> selection() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in [uriKey, tokenKey, pathKey, nameKey])
        if (prefs.getString(key) case final String value) key: value,
    };
  }

  Future<void> save(Map<String, String> audio) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in {
      uriKey: audio['uri'],
      tokenKey: audio['token'],
      pathKey: audio['path'],
      nameKey: audio['name'],
    }.entries) {
      if (entry.value == null) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, entry.value!);
      }
    }
  }

  Future<void> restore(Map<String, String> previous) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [uriKey, tokenKey, pathKey, nameKey]) {
      if (previous[key] == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, previous[key]!);
      }
    }
  }
}
