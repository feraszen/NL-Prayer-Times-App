import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nl_prayer_times_app/app/app.dart';
import 'package:nl_prayer_times_app/app/app_preferences.dart';
import 'package:nl_prayer_times_app/core/services/settings_service.dart';
import 'package:nl_prayer_times_app/features/prayer_times/data/providers/alfalah_prayer_times_provider.dart';
import 'support/location_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  setUp(() {
    // These tests cover UI and cached data; Android scheduling is covered in
    // separate method-channel tests, not across independent fake async zones.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    SharedPreferences.setMockInitialValues({});
    GeolocatorPlatform.instance = TestLocation();
    GeocodingPlatform.instance = TestGeocoding();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async =>
          call.method == 'canScheduleExactNotifications' ? true : null,
    );
    messenger.setMockStreamHandler(
      const EventChannel('hemanthraj/flutter_compass'),
      MockStreamHandler.inline(
        onListen: (_, events) {
          Timer(
            const Duration(milliseconds: 10),
            () => events.success(<double>[335, 0, 1]),
          );
        },
      ),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null,
          );
        }
        return null;
      },
    );
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/design-previews')
        ..createSync(recursive: true);
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'three tabs render in Arabic and dark mode and language update live',
    (tester) async {
      tester.view.physicalSize = const Size(393, 1020);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Load the bundled font for real Arabic glyphs in optional design captures.
      final loader = FontLoader(
        'IBM Plex Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'));
      await loader.load();
      final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        );
      await icons.load();
      final materialIcons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await materialIcons.load();
      await tester.pumpWidget(
        RepaintBoundary(key: captureKey, child: const NLPrayerTimesApp()),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 320),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text("St. John's"), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsWidgets);
      expect(tester.takeException(), isNull);
      await capture(tester, 'home-light');
      final p = AppScope.of(tester.element(find.text('الرئيسية')));
      await p.setTheme(AppThemeMode.dark);
      await tester.pumpAndSettle();
      await capture(tester, 'home-dark');
      await tester.tap(find.text('القبلة'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('كم'), findsOneWidget);
      expect(find.textContaining('335'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'qibla-dark');
      await p.setTheme(AppThemeMode.light);
      await tester.pumpAndSettle();
      await capture(tester, 'qibla-light');
      await tester.tap(find.text('الإعدادات').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('الصوت والأذان'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'settings-light');
      await p.setTheme(AppThemeMode.dark);
      await tester.pumpAndSettle();
      await capture(tester, 'settings-dark');
      await p.setLanguage('en');
      await p.setTimeFormat(TimeFormat.hour24);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Sound & adhan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final saved = SharedPreferences.getInstance();
      expect((await saved).getString('app_language'), 'en');
      expect((await saved).getString('theme_mode'), 'dark');
      expect((await saved).getString('time_format'), 'hour24');
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 1.7;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('cached Al-Falah times render offline without a GPS request', (
    tester,
  ) async {
    final now = AlFalahPrayerTimesProvider.now;
    final initial = <String, Object>{
      'prayer_time_source': 'alFalah',
      'notifications_enabled': false,
    };
    for (var day = 0; day < 2; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final key = AlFalahPrayerTimesProvider.dateKey(date);
      initial['alfalah_day_v1_$key'] = jsonEncode({
        'timezone': AlFalahPrayerTimesProvider.timezoneName,
        'date': key,
        'fetchedOn': AlFalahPrayerTimesProvider.dateKey(now),
        'times': ['05:38', '07:07', '11:46', '14:03', '16:23', '17:53'],
      });
    }
    SharedPreferences.setMockInitialValues(initial);
    GeolocatorPlatform.instance = _NoGps();
    await tester.pumpWidget(const NLPrayerTimesApp());
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('2:03 PM').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(find.text('2:03 PM'), findsOneWidget);
    expect(find.text('سانت جونز · أوقات بدء الصلاة'), findsOneWidget);
    expect(find.textContaining('الفلاح'), findsNothing);
    expect(find.textContaining('Al-Falah'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });

  test('preferences restore language theme time format and adhan', () async {
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'theme_mode': 'dark',
      'time_format': 'hour24',
      'adhan_enabled': false,
    });
    final p = AppPreferences();
    await p.load();
    expect(p.arabic, isFalse);
    expect(p.theme, AppThemeMode.dark);
    expect(p.formatTime(DateTime(2026, 11, 16, 18, 5)), '18:05');
    expect(p.adhanEnabled, isFalse);
    p.dispose();
  });
}

class _NoGps extends TestLocation {
  @override
  Future<bool> isLocationServiceEnabled() async => throw StateError(
    'GPS must not be requested for the fixed mosque timetable',
  );
}
