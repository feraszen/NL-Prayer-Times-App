import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import '../../../app/app_preferences.dart';
import '../../../core/presentation/islamic_decoration.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/prayer_notification_scheduler.dart';
import '../../../core/services/settings_service.dart';
import '../../location/data/providers/gps_location_provider.dart';
import '../../location/domain/models/location_data.dart';
import '../../prayer_times/data/providers/real_prayer_times_provider.dart';
import '../../prayer_times/data/services/prayer_times_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _player = AudioPlayer();
  StreamSubscription<void>? _completion;
  bool _playing = false, _busy = false;
  double _previewVolume = .7;
  String? _previewPath;
  @override
  void initState() {
    super.initState();
    _completion = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _completion?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppScope.of(context).text('تعذر إكمال العملية', 'Could not complete action')}: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule(AppPreferences p) async {
    if (!NotificationService.isSupported) return;
    if (!p.notifications) {
      await NotificationService.instance.cancelPrayerNotifications();
      return;
    }
    await NotificationService.instance.requestPermissions();
    final pos = await const GpsLocationProvider().getCurrentPosition();
    await PrayerNotificationScheduler(
      prayerTimesService: const PrayerTimesService(
        provider: RealPrayerTimesProvider(),
      ),
      settingsService: p.storage,
    ).scheduleNotifications(
      location: LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        country: '',
        region: '',
        city: '',
        timeZone: DateTime.now().timeZoneName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context);
    final native = NotificationService.isSupported;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    p.text('الإعدادات', 'Settings'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_busy) const LinearProgressIndicator(minHeight: 2),
                  _heading(p.text('الصوت والأذان', 'Sound & adhan')),
                  _group([
                    _switch(
                      CupertinoIcons.speaker_2,
                      p.text('الأذان', 'Adhan sound'),
                      p.adhanEnabled,
                      native && !_busy
                          ? (value) => _run(() async {
                              await p.setAdhan(value);
                              await _reschedule(p);
                            })
                          : null,
                    ),
                    _tile(
                      CupertinoIcons.waveform,
                      p.text('صوت الأذان', 'Adhan voice'),
                      p.text('أذان مكة المكرمة', 'Makkah adhan'),
                      () => _info(
                        p.text('صوت الأذان', 'Adhan voice'),
                        p.text(
                          'يُستخدم الأذان المدمج للتنبيهات المجدولة. يمكنك تعديل صوت القناة من إعدادات إشعارات التطبيق في Android. اختيار ملف أدناه للمعاينة فقط.',
                          'Scheduled reminders use the bundled adhan. Android notification settings control the channel sound. Local file selection below is for preview only.',
                        ),
                      ),
                    ),
                    _tile(
                      _playing
                          ? CupertinoIcons.stop_circle
                          : CupertinoIcons.play_circle,
                      _playing
                          ? p.text('إيقاف المعاينة', 'Stop preview')
                          : p.text('معاينة الأذان', 'Preview adhan'),
                      _previewPath == null
                          ? p.text('الصوت المدمج', 'Bundled audio')
                          : path.basename(_previewPath!),
                      () => _run(() async {
                        if (_playing) {
                          await _player.stop();
                        } else {
                          await _player.setVolume(_previewVolume);
                          await _player.play(
                            _previewPath == null
                                ? AssetSource('audio/adhan.mp3')
                                : DeviceFileSource(_previewPath!),
                          );
                        }
                        if (mounted) setState(() => _playing = !_playing);
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.text(
                              'مستوى صوت المعاينة فقط',
                              'Preview volume only',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Slider(
                            value: _previewVolume,
                            label: '${(_previewVolume * 100).round()}%',
                            onChanged: (value) {
                              setState(() => _previewVolume = value);
                              _player.setVolume(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                  _heading(p.text('التنبيهات', 'Notifications')),
                  _group([
                    _switch(
                      CupertinoIcons.bell,
                      p.text('تنبيهات الصلاة', 'Prayer notifications'),
                      p.notifications,
                      native && !_busy
                          ? (value) => _run(() async {
                              await p.setNotifications(value);
                              await _reschedule(p);
                            })
                          : null,
                    ),
                    ExpansionTile(
                      leading: Icon(
                        CupertinoIcons.bell,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        p.text('تنبيهات كل صلاة', 'Individual prayer alerts'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      children: [
                        for (final type in p.alerts.keys)
                          _switch(
                            CupertinoIcons.bell,
                            p.prayerName(type),
                            p.alerts[type]!,
                            native && p.notifications && !_busy
                                ? (value) => _run(() async {
                                    await p.setAlert(type, value);
                                    await _reschedule(p);
                                  })
                                : null,
                          ),
                      ],
                    ),
                  ]),
                  if (!native)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        p.text(
                          'جدولة التنبيهات متاحة على Android في هذه النسخة.',
                          'Scheduled notifications are available on Android in this version.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  _heading(p.text('العام', 'General')),
                  _group([
                    _tile(
                      CupertinoIcons.moon,
                      p.text('النمط', 'Appearance'),
                      switch (p.theme) {
                        AppThemeMode.system => p.text('تلقائي', 'System'),
                        AppThemeMode.light => p.text('فاتح', 'Light'),
                        AppThemeMode.dark => p.text('داكن', 'Dark'),
                      },
                      () => _choose<AppThemeMode>(
                        p.text('النمط', 'Appearance'),
                        AppThemeMode.values,
                        [
                          p.text('تلقائي', 'System'),
                          p.text('فاتح', 'Light'),
                          p.text('داكن', 'Dark'),
                        ],
                        p.theme,
                        p.setTheme,
                      ),
                    ),
                    _tile(
                      CupertinoIcons.globe,
                      p.text('اللغة', 'Language'),
                      p.arabic ? 'العربية' : 'English',
                      () => _choose<String>(
                        p.text('اللغة', 'Language'),
                        ['ar', 'en'],
                        ['العربية', 'English'],
                        p.language,
                        p.setLanguage,
                      ),
                    ),
                    _tile(
                      CupertinoIcons.clock,
                      p.text('تنسيق الوقت', 'Time format'),
                      p.timeFormat == TimeFormat.hour12
                          ? p.text('12 ساعة', '12 hour')
                          : p.text('24 ساعة', '24 hour'),
                      () => _choose<TimeFormat>(
                        p.text('تنسيق الوقت', 'Time format'),
                        TimeFormat.values,
                        [
                          p.text('12 ساعة', '12 hour'),
                          p.text('24 ساعة', '24 hour'),
                        ],
                        p.timeFormat,
                        p.setTimeFormat,
                      ),
                    ),
                    _tile(
                      CupertinoIcons.compass,
                      p.text('طريقة الحساب', 'Calculation method'),
                      'ISNA',
                      () => _info(
                        p.text('طريقة الحساب', 'Calculation method'),
                        p.text(
                          'ISNA — أمريكا الشمالية\nالفجر: 15° · العشاء: 15°\nالعصر: المذهب الشافعي\nتُحسب الأوقات حسب موقع GPS والمنطقة الزمنية للهاتف.',
                          'ISNA — North America\nFajr: 15° · Isha: 15°\nAsr: Shafi\nTimes use your GPS location and phone timezone.',
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  _group([
                    _tile(
                      CupertinoIcons.info_circle,
                      p.text('عن التطبيق', 'About the app'),
                      '1.0.0',
                      () => _info(
                        p.text('عن التطبيق', 'About the app'),
                        'NL Prayer Times\nFeras Zen Alabdeen\n\n${p.text('مواقيت الصلاة واتجاه القبلة أينما كنت.', 'Prayer times and Qibla wherever you are.')}',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      p.text(
                        'خيارات الصوت والاختبار',
                        'Audio & testing options',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    children: [
                      _tile(
                        CupertinoIcons.folder,
                        p.text('اختيار ملف للمعاينة', 'Choose preview file'),
                        p.text(
                          'لا يغيّر صوت التنبيه',
                          'Does not change alert sound',
                        ),
                        () => _run(() async {
                          final files = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'],
                          );
                          if (files.isNotEmpty && mounted) {
                            setState(() => _previewPath = files.first.path);
                          }
                        }),
                      ),
                      if (native) ...[
                        _tile(
                          CupertinoIcons.bell,
                          p.text('تجربة التنبيه الآن', 'Test alert now'),
                          '',
                          () => _run(
                            NotificationService.instance.showTestNotification,
                          ),
                        ),
                        _tile(
                          CupertinoIcons.timer,
                          p.text('تجربة بعد 30 ثانية', 'Test after 30 seconds'),
                          '',
                          () => _run(() async {
                            await NotificationService.instance
                                .scheduleNotificationIn30Seconds();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  p.text(
                                    'تمت الجدولة. اقفل الشاشة وانتظر 30 ثانية.',
                                    'Scheduled. Lock your screen and wait 30 seconds.',
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        _tile(
                          CupertinoIcons.gear,
                          p.text('إعدادات Android', 'Android app settings'),
                          '',
                          () => Geolocator.openAppSettings(),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          p.text(
                            'افتح التطبيق أسبوعيًا لتجديد الجدولة. يتحكم Android بصوت التنبيهات ووضع عدم الإزعاج.',
                            'Open the app weekly to renew the schedule. Android controls notification volume and Do Not Disturb.',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 18, 8, 9),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
  Widget _group(List<Widget> children) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Theme.of(context).dividerColor,
            ),
        ],
      ],
    ),
  );
  Widget _switch(
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool>? onChanged,
  ) => SwitchListTile.adaptive(
    secondary: Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: Text(label, style: const TextStyle(fontSize: 14)),
    value: value,
    onChanged: onChanged,
  );
  Widget _tile(IconData icon, String label, String value, VoidCallback onTap) =>
      ListTile(
        leading: Icon(
          icon,
          size: 21,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: value.isEmpty
            ? null
            : Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 14),
        onTap: onTap,
      );
  Future<void> _info(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppScope.of(context).text('حسنًا', 'OK')),
        ),
      ],
    ),
  );
  Future<void> _choose<T>(
    String title,
    List<T> values,
    List<String> labels,
    T current,
    Future<void> Function(T) change,
  ) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (var i = 0; i < values.length; i++)
              ListTile(
                title: Text(labels[i]),
                trailing: current == values[i]
                    ? const Icon(CupertinoIcons.check_mark)
                    : null,
                onTap: () => Navigator.pop(context, values[i]),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected != null) await change(selected);
  }
}
