import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/services/settings_service.dart';
import 'app_preferences.dart';
import 'navigation/main_navigation_screen.dart';
import 'theme/app_theme.dart';

class NLPrayerTimesApp extends StatefulWidget {
  const NLPrayerTimesApp({super.key});
  @override
  State<NLPrayerTimesApp> createState() => _NLPrayerTimesAppState();
}

class _NLPrayerTimesAppState extends State<NLPrayerTimesApp> {
  final preferences = AppPreferences();
  @override
  void initState() {
    super.initState();
    preferences.load();
  }

  @override
  void dispose() {
    preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    preferences: preferences,
    child: ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NL Prayer Times',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: switch (preferences.theme) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        },
        locale: Locale(preferences.language),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const MainNavigationScreen(),
      ),
    ),
  );
}
