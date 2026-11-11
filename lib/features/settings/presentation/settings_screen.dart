import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../../core/services/settings_service.dart';
import '../../../core/services/notification_service.dart';

import '../../location/data/providers/gps_location_provider.dart';
import '../../location/data/repositories/gps_location_repository.dart';
import '../../location/data/services/reverse_geocoding_service.dart';

import '../../location/domain/extensions/location_data_extension.dart';
import '../../location/domain/models/location_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  LocationData? currentLocation;

  bool isLoadingLocation = true;

  bool notificationsEnabled = false;

  String? notificationSoundPath;

  bool fajrNotification = true;

  bool dhuhrNotification = true;

  bool asrNotification = true;

  bool maghribNotification = true;

  bool ishaNotification = true;

  final SettingsService settingsService =
      SettingsService();

  final AudioPlayer audioPlayer = AudioPlayer();

  AppThemeMode currentTheme =
      AppThemeMode.system;

  TimeFormat currentTimeFormat =
      TimeFormat.hour12;

  @override
  void initState() {
    super.initState();

    loadLocation();
    loadSettings();
  }

  Future<void> loadLocation() async {
    try {
      final repository = GpsLocationRepository(
        gpsProvider: const GpsLocationProvider(),
        geocodingService:
            const ReverseGeocodingService(),
      );

      final location =
          await repository.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        currentLocation = location;
        isLoadingLocation = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Location loading error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> loadSettings() async {
    final theme =
        await settingsService.getThemeMode();

    final timeFormat =
        await settingsService.getTimeFormat();

    final notifications =
        await settingsService.getNotificationsEnabled();

    final fajr =
        await settingsService.getFajrNotification();

    final dhuhr =
        await settingsService.getDhuhrNotification();

    final asr =
        await settingsService.getAsrNotification();

    final maghrib =
        await settingsService.getMaghribNotification();

    final isha =
        await settingsService.getIshaNotification();

    final soundPath =
        await settingsService.getNotificationSoundPath();

    if (!mounted) return;

    setState(() {
      currentTheme = theme;
      currentTimeFormat = timeFormat;
      notificationsEnabled = notifications;

      fajrNotification = fajr;
      dhuhrNotification = dhuhr;
      asrNotification = asr;
      maghribNotification = maghrib;
      ishaNotification = isha;

      notificationSoundPath = soundPath;
    });
  }

  Future<void> changeTheme() async {
    final selected = await showDialog<AppThemeMode>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            'Theme',
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  AppThemeMode.system,
                );
              },
              child: const Text(
                'System',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  AppThemeMode.light,
                );
              },
              child: const Text(
                'Light',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  AppThemeMode.dark,
                );
              },
              child: const Text(
                'Dark',
              ),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    await settingsService.saveThemeMode(
      selected,
    );

    if (!mounted) return;

    setState(() {
      currentTheme = selected;
    });
  }

  Future<void> changeTimeFormat() async {
    final selected = await showDialog<TimeFormat>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            'Time Format',
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  TimeFormat.hour12,
                );
              },
              child: const Text(
                '12 Hour',
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  TimeFormat.hour24,
                );
              },
              child: const Text(
                '24 Hour',
              ),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    await settingsService.saveTimeFormat(
      selected,
    );

    if (!mounted) return;

    setState(() {
      currentTimeFormat = selected;
    });
  }

  Future<void> pickNotificationSound() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'wav',
        'm4a',
        'ogg',
      ],
    );

    if (files.isEmpty) return;

    if (kIsWeb) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecting a local notification sound is not supported on web.',
          ),
        ),
      );
      return;
    }

    final selectedPath = files.first.path;

    if (selectedPath == null) return;

    await settingsService.saveNotificationSoundPath(
      selectedPath,
    );

    if (!mounted) return;

    setState(() {
      notificationSoundPath = selectedPath;
    });
  }

  Future<void> playSelectedSound() async {
    final selectedPath = notificationSoundPath;
    if (selectedPath == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No sound selected.',
          ),
        ),
      );
      return;
    }

    await audioPlayer.stop();
    if (!mounted) return;

    await audioPlayer.play(
      DeviceFileSource(selectedPath),
    );
  }

  Future<void> stopSelectedSound() async {
    await audioPlayer.stop();
  }

  String get selectedSoundType {
    if (notificationSoundPath == null) {
      return 'No sound selected';
    }

    final extension = path.extension(
      notificationSoundPath!,
    ).toLowerCase();

    switch (extension) {
      case '.mp3':
        return 'MP3 Audio File';
      case '.wav':
        return 'WAV Audio File';
      case '.m4a':
        return 'M4A Audio File';
      case '.ogg':
        return 'OGG Audio File';
      default:
        return 'Audio File';
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  String get themeText {
    switch (currentTheme) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  String get timeFormatText {
    switch (currentTimeFormat) {
      case TimeFormat.hour12:
        return '12 Hour';
      case TimeFormat.hour24:
        return '24 Hour';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.instance
                  .showTestNotification();
            },
            child: const Text(
              'Test Notification',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.instance
                  .scheduleNotificationIn30Seconds();
            },
            child: const Text(
              'Test Notification After 30 Seconds',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.instance
                  .printPendingNotifications();
            },
            child: const Text(
              'Check Pending Notifications',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.instance
                  .printActiveNotifications();
            },
            child: const Text(
              'Check Active Notifications',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.instance
                  .checkExactAlarmPermission();
            },
            child: const Text(
              'Check Exact Alarm Permission',
            ),
          ),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                  ),
                  title: Text(
                    'Location',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    'Current City',
                  ),
                  trailing: Text(
                    isLoadingLocation
                        ? 'Loading...'
                        : currentLocation
                                ?.shortDisplayName ??
                            'Unavailable',
                  ),
                ),
                const ListTile(
                  title: Text(
                    'Location Source',
                  ),
                  trailing: Text(
                    'GPS',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(
                    Icons.calculate_outlined,
                  ),
                  title: Text(
                    'Prayer Calculation',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text(
                    'Method',
                  ),
                  trailing: Text(
                    'ISNA',
                  ),
                ),
                ListTile(
                  title: Text(
                    'Asr Calculation',
                  ),
                  trailing: Text(
                    'Standard',
                  ),
                ),
                ListTile(
                  title: Text(
                    'High Latitude Rule',
                  ),
                  trailing: Text(
                    'Middle Of The Night',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                  ),
                  title: Text(
                    'Notifications',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Enable Notifications',
                  ),
                  value: notificationsEnabled,
                  onChanged: (value) async {
                    await settingsService.saveNotificationsEnabled(
                      value,
                    );

                    if (!mounted) return;

                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.notification_add_outlined,
                  ),
                  title: const Text(
                    'Test Notification',
                  ),
                  subtitle: const Text(
                    'Send a test notification now',
                  ),
                  enabled: notificationsEnabled,
                  onTap: notificationsEnabled
                      ? () async {
                          await NotificationService.instance
                              .showTestNotification();
                        }
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.audio_file_outlined,
                  ),
                  title: Text(
                    notificationSoundPath == null
                        ? 'Notification Sound'
                        : path.basename(notificationSoundPath!),
                  ),
                  subtitle: Text(
                    notificationSoundPath == null
                        ? 'No sound selected'
                        : selectedSoundType,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: pickNotificationSound,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.play_arrow_outlined,
                  ),
                  title: const Text(
                    'Play Selected Sound',
                  ),
                  subtitle: const Text(
                    'Preview the selected audio file',
                  ),
                  enabled: notificationSoundPath != null,
                  onTap: notificationSoundPath == null
                      ? null
                      : playSelectedSound,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.stop_outlined,
                  ),
                  title: const Text(
                    'Stop Sound',
                  ),
                  subtitle: const Text(
                    'Stop the current audio playback',
                  ),
                  onTap: stopSelectedSound,
                ),
                const Divider(height: 1),

                SwitchListTile(
                  title: const Text(
                    'Fajr Notification',
                  ),
                  value: fajrNotification,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await settingsService.saveFajrNotification(
                            value,
                          );

                          if (!mounted) return;

                          setState(() {
                            fajrNotification = value;
                          });
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text(
                    'Dhuhr Notification',
                  ),
                  value: dhuhrNotification,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await settingsService.saveDhuhrNotification(
                            value,
                          );

                          if (!mounted) return;

                          setState(() {
                            dhuhrNotification = value;
                          });
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text(
                    'Asr Notification',
                  ),
                  value: asrNotification,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await settingsService.saveAsrNotification(
                            value,
                          );

                          if (!mounted) return;

                          setState(() {
                            asrNotification = value;
                          });
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text(
                    'Maghrib Notification',
                  ),
                  value: maghribNotification,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await settingsService.saveMaghribNotification(
                            value,
                          );

                          if (!mounted) return;

                          setState(() {
                            maghribNotification = value;
                          });
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text(
                    'Isha Notification',
                  ),
                  value: ishaNotification,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await settingsService.saveIshaNotification(
                            value,
                          );

                          if (!mounted) return;

                          setState(() {
                            ishaNotification = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                  ),
                  title: Text(
                    'Appearance & Language',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    'Theme',
                  ),
                  trailing: Text(
                    themeText,
                  ),
                  onTap: changeTheme,
                ),
                const ListTile(
                  title: Text(
                    'Language',
                  ),
                  trailing: Text(
                    'English',
                  ),
                ),
                ListTile(
                  title: const Text(
                    'Time Format',
                  ),
                  trailing: Text(
                    timeFormatText,
                  ),
                  onTap: changeTimeFormat,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                  ),
                  title: Text(
                    'About',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text(
                    'App Name',
                  ),
                  trailing: Text(
                    'NL Prayer Times',
                  ),
                ),
                ListTile(
                  title: Text(
                    'Version',
                  ),
                  trailing: Text(
                    '1.0.0',
                  ),
                ),
                ListTile(
                  title: Text(
                    'Developer',
                  ),
                  trailing: Text(
                    'Feras Zen Alabdeen',
                  ),
                ),
                ListTile(
                  title: Text(
                    'Email',
                  ),
                  trailing: Text(
                    'feraszen@gmail.com',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

