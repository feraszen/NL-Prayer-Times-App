import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
import 'support/location_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  setUp(() {
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
      unawaited(p.setTheme(AppThemeMode.dark));
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
      unawaited(p.setTheme(AppThemeMode.light));
      await tester.pumpAndSettle();
      await capture(tester, 'qibla-light');
      await tester.tap(find.text('الإعدادات').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('الصوت والأذان'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'settings-light');
      unawaited(p.setTheme(AppThemeMode.dark));
      await tester.pumpAndSettle();
      await capture(tester, 'settings-dark');
      unawaited(p.setLanguage('en'));
      unawaited(p.setTimeFormat(TimeFormat.hour24));
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
    },
  );

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
