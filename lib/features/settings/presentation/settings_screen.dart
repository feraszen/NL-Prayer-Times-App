import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/ios_prayer_alarm_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../app/app_preferences.dart';
import '../../../core/presentation/islamic_decoration.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/custom_adhan_service.dart';
import '../../../core/services/prayer_notification_scheduler.dart';
import '../../../core/services/settings_service.dart';
import '../../location/data/providers/gps_location_provider.dart';
import '../../location/domain/models/location_data.dart';
import '../../prayer_times/data/providers/real_prayer_times_provider.dart';
import '../../prayer_times/data/providers/alfalah_prayer_times_provider.dart';
import '../../prayer_times/data/services/prayer_times_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _player = AudioPlayer();
  StreamSubscription<void>? _completion;
  bool _playing = false, _busy = false;
  double _previewVolume = .7;
  String? _previewPath, _audioName;
  final _audio = CustomAdhanService();
  Map<String, dynamic> _iosStatus = {};
  Future<void> _refreshIOSStatus() async {
    if (!NotificationService.isIOS) return;
    try {
      final status = await NotificationService.instance.iosStatus();
      if (mounted) setState(() => _iosStatus = status);
    } catch (e) {
      if (mounted) setState(() => _iosStatus = {'error': e.toString()});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIOSStatus();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.statusRevision.addListener(_refreshIOSStatus);
    _refreshIOSStatus();
    _loadAudio();
    _completion = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _loadAudio() async {
    final selected = await _audio.selection();
    if (mounted) {
      setState(() {
        _previewPath = selected[CustomAdhanService.pathKey];
        _audioName = selected[CustomAdhanService.nameKey];
      });
    }
  }

  Future<void> _chooseAudio(AppPreferences p) => _run(() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: NotificationService.isIOS
          ? ['mp3', 'wav', 'm4a', 'caf', 'aiff', 'aif']
          : ['mp3', 'wav', 'm4a', 'ogg'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final filePath = file.path;
    if (filePath == null) {
      throw StateError('Choose a downloaded local audio file');
    }
    final selected = await _audio.importFile(filePath, file.name);
    await _setAudio(p, selected);
  });

  Future<void> _setAudio(AppPreferences p, Map<String, String> selected) async {
    final previous = await _audio.selection();
    await _player.stop();
    if (mounted) setState(() => _playing = false);
    try {
      await _audio.save(selected);
      await _reschedule(p);
    } catch (_) {
      await _audio.restore(previous);
      rethrow;
    }
    await _loadAudio();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          p.text(
            'تم حفظ الصوت لتنبيهات الصلاة.',
            'Audio saved for prayer alerts.',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.statusRevision.removeListener(
      _refreshIOSStatus,
    );
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
      await _refreshIOSStatus();
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
    late LocationData location;
    if (p.prayerSource == PrayerTimeSource.alFalah) {
      location = AlFalahPrayerTimesProvider.location;
    } else {
      final pos = await const GpsLocationProvider().getCurrentPosition();
      location = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        country: '',
        region: '',
        city: '',
        timeZone: DateTime.now().timeZoneName,
      );
    }
    await PrayerNotificationScheduler(
      prayerTimesService: const PrayerTimesService(
        provider: RealPrayerTimesProvider(),
      ),
      settingsService: p.storage,
    ).scheduleNotifications(location: location);
  }

  Future<void> _changeTiming(
    Future<void> Function() change,
    Future<void> Function() undo,
    AppPreferences p,
  ) => _run(() async {
    try {
      await change();
      await _reschedule(p);
    } catch (_) {
      await undo();
      rethrow;
    }
  });

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
                          ? (value) {
                              final previous = p.adhanEnabled;
                              _changeTiming(
                                () => p.setAdhan(value),
                                () => p.setAdhan(previous),
                                p,
                              );
                            }
                          : null,
                    ),
                    _tile(
                      CupertinoIcons.waveform,
                      p.text('صوت الأذان أو التنبيه', 'Adhan or alert audio'),
                      _audioName ?? p.text('أذان مكة المكرمة', 'Makkah adhan'),
                      native && !_busy ? () => _chooseAudio(p) : null,
                    ),
                    if (_audioName != null)
                      _tile(
                        CupertinoIcons.arrow_counterclockwise,
                        p.text(
                          'استعادة الأذان المدمج',
                          'Restore bundled adhan',
                        ),
                        '',
                        native && !_busy
                            ? () => _run(() => _setAudio(p, {}))
                            : null,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        NotificationService.isIOS
                            ? p.text(
                                'اختر الصوت من تطبيق الملفات. الإشعار العادي يستخدم أول 29 ثانية. لتشغيل الملف الكامل اضغط مطولًا على الإشعار واختر Play full adhan. خيار منبّه iOS أدناه يستخدم AlarmKit ويحتاج اختبار الصوت على الجهاز. يدعم MP3 وM4A وWAV وCAF وAIFF حتى 50 ميغابايت و10 دقائق.',
                                'Choose audio from Files. Standard notifications use the first 29 seconds. Long-press a notification and choose Play full adhan for the complete file. iOS alarms below use AlarmKit and need device sound testing. Supports MP3, M4A, WAV, CAF and AIFF up to 50 MB and 10 minutes.',
                              )
                            : p.text(
                                'اضغط لاختيار ملف صوتي من هاتفك لجميع الصلوات. يُحفظ الملف للتنبيهات حتى بعد إغلاق التطبيق. يدعم MP3 وWAV وM4A وOGG حتى 50 ميغابايت. يتحكم Android بمستوى الصوت ومدة تشغيله.',
                                'Tap to choose audio from your phone for all prayers. Audio is saved for alerts after closing the app. Supports MP3, WAV, M4A and OGG up to 50 MB. Android controls alert volume and playback duration.',
                              ),
                        style: const TextStyle(fontSize: 11),
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
                          : _audioName ?? p.text('ملف مخصص', 'Custom audio'),
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
                          ? (value) {
                              final previous = p.notifications;
                              _changeTiming(
                                () => p.setNotifications(value),
                                () => p.setNotifications(previous),
                                p,
                              );
                            }
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
                                ? (value) {
                                    final previous = p.alerts[type]!;
                                    _changeTiming(
                                      () => p.setAlert(type, value),
                                      () => p.setAlert(type, previous),
                                      p,
                                    );
                                  }
                                : null,
                          ),
                      ],
                    ),
                  ]),
                  if (NotificationService.isIOS) ...[
                    _group([
                      _tile(
                        CupertinoIcons.bell,
                        p.text(
                          'إذن إشعارات iPhone',
                          'iPhone notification permission',
                        ),
                        _iosStatus['notifications'] == true
                            ? p.text('مسموح', 'Allowed')
                            : p.text('غير مسموح', 'Not allowed'),
                        () => _run(
                          NotificationService.instance.requestPermissions,
                        ),
                      ),
                      _tile(
                        CupertinoIcons.speaker_2,
                        p.text('صوت الإشعارات', 'Notification sounds'),
                        _iosStatus['sound'] == true
                            ? p.text('مسموح', 'Allowed')
                            : p.text(
                                'غير مسموح من النظام',
                                'Disabled in system settings',
                              ),
                        () => _run(
                          () => IOSPrayerAlarmService.channel
                              .invokeMethod<void>('openSettings'),
                        ),
                      ),
                      _tile(
                        CupertinoIcons.calendar,
                        p.text('الصلوات المجدولة', 'Scheduled prayers'),
                        '${_iosStatus['pending'] ?? 0}',
                        () => _run(() => _reschedule(p)),
                      ),
                      if (_iosStatus['available'] == true)
                        _switch(
                          CupertinoIcons.alarm,
                          p.text(
                            'استخدام منبّه iOS للصلاة',
                            'Use iOS prayer alarms',
                          ),
                          _iosStatus['alarmEnabled'] == true,
                          _busy
                              ? null
                              : (value) => _run(() async {
                                  final alarms =
                                      NotificationService.instance.alarms;
                                  final previous = await alarms.enabled();
                                  if (value &&
                                      !await alarms.requestPermission()) {
                                    throw StateError(
                                      p.text(
                                        'اسمح بالمنبّهات في إعدادات iPhone.',
                                        'Allow alarms in iPhone Settings.',
                                      ),
                                    );
                                  }
                                  try {
                                    await alarms.setEnabled(value);
                                    await _reschedule(p);
                                  } catch (_) {
                                    await alarms.setEnabled(previous);
                                    rethrow;
                                  }
                                }),
                        ),
                      _tile(
                        CupertinoIcons.gear,
                        p.text('إعدادات iPhone', 'iPhone settings'),
                        '',
                        () => _run(
                          () => IOSPrayerAlarmService.channel
                              .invokeMethod<void>('openSettings'),
                        ),
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        p.text(
                          'افتح التطبيق أسبوعيًا لتجديد الجدولة. وضع المنبّه يتطلب إذنًا منفصلًا وقد يصدر صوتًا أثناء الصامت والتركيز؛ يتوقف من شاشة منبّه النظام. كتم الأذان في التطبيق يبقي الإشعار دون منبّه صوتي.',
                          'Open the app weekly to renew the schedule. Alarm mode needs separate permission and can sound during Silent mode and Focus; stop it from the system alarm screen. Muting adhan keeps a silent notification.',
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (NotificationService.instance.lastPreparationError !=
                            null ||
                        _iosStatus['error'] != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${p.text('لم تكتمل جدولة التنبيهات أو تهيئة الصوت', 'Alert scheduling or audio preparation failed')}: ${NotificationService.instance.lastPreparationError ?? _iosStatus['error']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                  if (!native)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        p.text(
                          'جدولة التنبيهات متاحة على Android وiPhone.',
                          'Scheduled notifications are available on Android and iPhone.',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  _heading(
                    p.text(
                      'مصدر المواقيت وضبطها',
                      'Prayer time source & adjustments',
                    ),
                  ),
                  _group([
                    _tile(
                      CupertinoIcons.building_2_fill,
                      p.text('مصدر المواقيت', 'Prayer time source'),
                      p.prayerSource == PrayerTimeSource.alFalah
                          ? p.text('مواقيت سانت جونز', 'St. John’s timetable')
                          : p.text(
                              'حساب ISNA حسب GPS',
                              'ISNA calculation using GPS',
                            ),
                      () => _choose<PrayerTimeSource>(
                        p.text('مصدر المواقيت', 'Prayer time source'),
                        PrayerTimeSource.values,
                        [
                          p.text(
                            'حساب ISNA حسب GPS',
                            'ISNA calculation using GPS',
                          ),
                          p.text('مواقيت سانت جونز', 'St. John’s timetable'),
                        ],
                        p.prayerSource,
                        (value) {
                          final old = p.prayerSource;
                          return _changeTiming(
                            () => p.setPrayerSource(value),
                            () => p.setPrayerSource(old),
                            p,
                          );
                        },
                      ),
                    ),
                    _tile(
                      CupertinoIcons.slider_horizontal_3,
                      p.text(
                        'تعديل الدقائق لكل صلاة',
                        'Adjust minutes per prayer',
                      ),
                      p.adjustments.values.any((value) => value != 0)
                          ? p.text('تعديلات مخصصة', 'Custom adjustments')
                          : p.text('بدون تعديل', 'No adjustments'),
                      () => _adjustments(p),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Text(
                        p.text(
                          'جدول أوقات بدء الصلاة لسانت جونز، وليس الإقامة. يتطلب الإنترنت لأول تحميل؛ تُحفظ الأيام للعمل دون اتصال. التعديلات اليدوية تؤثر في العرض والتنبيهات معًا.',
                          'Prayer start times for St. John’s, not iqama. Internet is needed initially; fetched dates are cached offline. Manual adjustments apply to both display and alerts.',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]),
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
                          'ISNA — أمريكا الشمالية\nالفجر: 15° · العشاء: 15°\nالعصر: المذهب الشافعي\nفي وضع GPS تُحسب الأوقات حسب موقعك. في وضع جدول المدينة تُستخدم مواقيت سانت جونز.',
                          'ISNA — North America\nFajr: 15° · Isha: 15°\nAsr: Shafi\nGPS mode uses your location. City timetable mode uses St. John’s prayer times.',
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  _group([
                    _tile(
                      CupertinoIcons.info_circle,
                      p.text('عن التطبيق', 'About the app'),
                      '1.1.1',
                      () => _info(
                        p.text('عن التطبيق', 'About the app'),
                        'NL Prayer Times\nFeras Zen Alabdeen\n\n${p.text('مواقيت الصلاة واتجاه القبلة أينما كنت.', 'Prayer times and Qibla wherever you are.')}',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _adjustments(AppPreferences p) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      var pending = false;
      return StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.text(
                      'تعديل الدقائق لكل صلاة',
                      'Adjust minutes per prayer',
                    ),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.text(
                      'القيمة الموجبة تؤخر الوقت، والسالبة تقدّمه. اتركها صفرًا لمطابقة المصدر دون تعديل.',
                      'Positive values delay the time; negative values make it earlier. Leave zero to follow the selected source unchanged.',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  for (final type in p.adjustments.keys)
                    ListTile(
                      title: Text(p.prayerName(type)),
                      subtitle: Text(
                        '${p.adjustments[type]! > 0 ? '+' : ''}${p.adjustments[type]} ${p.text('دقيقة', 'min')}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final delta in [-1, 1])
                            IconButton(
                              tooltip: delta < 0
                                  ? p.text('تقديم دقيقة', 'One minute earlier')
                                  : p.text('تأخير دقيقة', 'One minute later'),
                              icon: Icon(
                                delta < 0
                                    ? CupertinoIcons.minus_circle
                                    : CupertinoIcons.plus_circle,
                              ),
                              onPressed:
                                  pending ||
                                      _busy ||
                                      (p.adjustments[type]! + delta).abs() > 30
                                  ? null
                                  : () async {
                                      final old = p.adjustments[type]!;
                                      updateSheet(() => pending = true);
                                      await _changeTiming(
                                        () => p.setPrayerAdjustment(
                                          type,
                                          old + delta,
                                        ),
                                        () => p.setPrayerAdjustment(type, old),
                                        p,
                                      );
                                      if (sheetContext.mounted) {
                                        updateSheet(() => pending = false);
                                      }
                                    },
                            ),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: pending
                        ? null
                        : () => Navigator.pop(sheetContext),
                    child: Text(p.text('تم', 'Done')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

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
  Widget _tile(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) => ListTile(
    leading: Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
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
